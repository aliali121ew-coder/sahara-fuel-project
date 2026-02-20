// ============================================================
// Phase 7: Unit Tests - Error Handling System
// ============================================================
const {
    AppError,
    ValidationError,
    AuthenticationError,
    ForbiddenError,
    NotFoundError,
    ConflictError,
    RateLimitError,
    DatabaseError,
    ExternalServiceError,
    asyncHandler,
    CircuitBreaker,
    globalErrorHandler,
} = require('../../src/utils/app-error');

// ── Error Classes ──────────────────────────────────────────
describe('Error Classes', () => {
    test('AppError has correct properties', () => {
        const err = new AppError('test error', 500, 'TEST_CODE');
        expect(err.message).toBe('test error');
        expect(err.statusCode).toBe(500);
        expect(err.code).toBe('TEST_CODE');
        expect(err.isOperational).toBe(true);
        expect(err instanceof Error).toBe(true);
    });

    test('AppError.toJSON() returns structured response', () => {
        const err = new AppError('msg', 400, 'CODE', { field: 'name' });
        const json = err.toJSON();
        expect(json.success).toBe(false);
        expect(json.error).toBe('msg');
        expect(json.code).toBe('CODE');
        expect(json.details).toEqual({ field: 'name' });
    });

    test('ValidationError defaults to 400', () => {
        const err = new ValidationError();
        expect(err.statusCode).toBe(400);
        expect(err.code).toBe('VALIDATION_ERROR');
    });

    test('AuthenticationError defaults to 401', () => {
        const err = new AuthenticationError();
        expect(err.statusCode).toBe(401);
        expect(err.code).toBe('AUTH_REQUIRED');
    });

    test('ForbiddenError defaults to 403', () => {
        const err = new ForbiddenError();
        expect(err.statusCode).toBe(403);
    });

    test('NotFoundError defaults to 404', () => {
        const err = new NotFoundError('المستخدم');
        expect(err.statusCode).toBe(404);
        expect(err.message).toContain('المستخدم');
    });

    test('ConflictError defaults to 409', () => {
        const err = new ConflictError();
        expect(err.statusCode).toBe(409);
    });

    test('RateLimitError defaults to 429', () => {
        const err = new RateLimitError();
        expect(err.statusCode).toBe(429);
    });

    test('DatabaseError is non-operational', () => {
        const err = new DatabaseError();
        expect(err.statusCode).toBe(500);
        expect(err.isOperational).toBe(false);
    });

    test('ExternalServiceError defaults to 502', () => {
        const err = new ExternalServiceError('Redis');
        expect(err.statusCode).toBe(502);
        expect(err.message).toContain('Redis');
    });
});

// ── asyncHandler ───────────────────────────────────────────
describe('asyncHandler', () => {
    test('passes resolved value through', async () => {
        const handler = asyncHandler(async (req, res) => {
            res.json({ ok: true });
        });
        const res = { json: jest.fn() };
        const next = jest.fn();
        await handler({}, res, next);
        expect(res.json).toHaveBeenCalledWith({ ok: true });
        expect(next).not.toHaveBeenCalled();
    });

    test('passes rejected errors to next()', async () => {
        const error = new Error('async failure');
        const handler = asyncHandler(async () => { throw error; });
        const next = jest.fn();
        await handler({}, {}, next);
        expect(next).toHaveBeenCalledWith(error);
    });
});

// ── Circuit Breaker ────────────────────────────────────────
describe('CircuitBreaker', () => {
    test('starts in CLOSED state', () => {
        const cb = new CircuitBreaker('test');
        expect(cb.getState().state).toBe('CLOSED');
    });

    test('executes successfully in CLOSED state', async () => {
        const cb = new CircuitBreaker('test');
        const result = await cb.execute(() => Promise.resolve('ok'));
        expect(result).toBe('ok');
    });

    test('opens after failure threshold', async () => {
        const cb = new CircuitBreaker('test', { failureThreshold: 3 });
        for (let i = 0; i < 3; i++) {
            try { await cb.execute(() => Promise.reject(new Error('fail'))); }
            catch (e) { /* expected */ }
        }
        expect(cb.getState().state).toBe('OPEN');
    });

    test('rejects immediately when OPEN', async () => {
        const cb = new CircuitBreaker('test', { failureThreshold: 1, resetTimeout: 60000 });
        try { await cb.execute(() => Promise.reject(new Error('fail'))); } catch (e) { }

        await expect(cb.execute(() => Promise.resolve('ok')))
            .rejects.toThrow('متوقف مؤقتاً');
    });

    test('transitions to HALF_OPEN after resetTimeout', async () => {
        const cb = new CircuitBreaker('test', { failureThreshold: 1, resetTimeout: 10 });
        try { await cb.execute(() => Promise.reject(new Error('fail'))); } catch (e) { }
        expect(cb.getState().state).toBe('OPEN');

        // Wait for reset timeout
        await new Promise(r => setTimeout(r, 20));
        const result = await cb.execute(() => Promise.resolve('recovered'));
        expect(result).toBe('recovered');
    });
});

// ── Global Error Handler ───────────────────────────────────
describe('globalErrorHandler', () => {
    function mockRes() {
        const res = { _status: null, _json: null };
        res.status = (code) => { res._status = code; return res; };
        res.json = (data) => { res._json = data; return res; };
        return res;
    }

    test('handles AppError correctly', () => {
        const err = new ValidationError('bad input', { field: 'name' });
        const req = { originalUrl: '/test', method: 'POST', headers: {} };
        const res = mockRes();
        globalErrorHandler(err, req, res, () => {});
        expect(res._status).toBe(400);
        expect(res._json.code).toBe('VALIDATION_ERROR');
        expect(res._json.requestId).toBeDefined();
    });

    test('handles PostgreSQL constraint errors', () => {
        const err = { code: '23505', message: 'unique violation' };
        const req = { originalUrl: '/test', method: 'POST', headers: {} };
        const res = mockRes();
        globalErrorHandler(err, req, res, () => {});
        expect(res._status).toBe(409);
        expect(res._json.code).toBe('DATABASE_CONSTRAINT');
    });

    test('handles unknown errors as 500', () => {
        const err = new Error('something broke');
        const req = { originalUrl: '/test', method: 'GET', headers: {} };
        const res = mockRes();
        globalErrorHandler(err, req, res, () => {});
        expect(res._status).toBe(500);
        expect(res._json.code).toBe('INTERNAL_ERROR');
    });
});
