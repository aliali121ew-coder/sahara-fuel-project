// ============================================================
// Phase 7: Unit Tests - Validation Middleware
// ============================================================
const {
    sanitize,
    validateEmail,
    validatePassword,
    validateNumber,
    requireFields,
} = require('../../src/middlewares/validate');

// ── Helper: mock req/res/next ──────────────────────────────
function mockReqRes(body = {}) {
    const req = { body };
    const res = {
        _status: null,
        _json: null,
        status(code) { this._status = code; return this; },
        json(data) { this._json = data; return this; },
    };
    const next = jest.fn();
    return { req, res, next };
}

// ==================== sanitize() ====================
describe('sanitize()', () => {
    test('trims whitespace from strings', () => {
        expect(sanitize('  hello  ')).toBe('hello');
    });

    test('removes simple HTML tags', () => {
        expect(sanitize('<b>bold</b> text')).toBe('bold text');
    });

    test('removes nested HTML tags', () => {
        expect(sanitize('<div><p>text</p></div>')).toBe('text');
    });

    test('handles non-string inputs', () => {
        expect(sanitize(42)).toBe(42);
        expect(sanitize(null)).toBe(null);
        expect(sanitize(undefined)).toBe(undefined);
        expect(sanitize(true)).toBe(true);
    });
});

// ==================== validateEmail() ====================
describe('validateEmail()', () => {
    const middleware = validateEmail('email');

    test('accepts valid emails', () => {
        const { req, res, next } = mockReqRes({ email: 'user@example.com' });
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('rejects invalid emails', () => {
        const { req, res, next } = mockReqRes({ email: 'not-an-email' });
        middleware(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res._status).toBe(400);
    });

    test('passes through when email not provided', () => {
        const { req, res, next } = mockReqRes({});
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });
});

// ==================== validatePassword() ====================
describe('validatePassword()', () => {
    const middleware = validatePassword('password', 6);

    test('accepts valid password (6+ chars)', () => {
        const { req, res, next } = mockReqRes({ password: 'securePass123' });
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('rejects short password', () => {
        const { req, res, next } = mockReqRes({ password: '12345' });
        middleware(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res._status).toBe(400);
    });

    test('passes through when password not provided', () => {
        const { req, res, next } = mockReqRes({});
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });
});

// ==================== validateNumber() ====================
describe('validateNumber()', () => {
    test('accepts valid number', () => {
        const middleware = validateNumber('quantity');
        const { req, res, next } = mockReqRes({ quantity: 100 });
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('accepts string number', () => {
        const middleware = validateNumber('amount');
        const { req, res, next } = mockReqRes({ amount: '500' });
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('rejects non-number', () => {
        const middleware = validateNumber('quantity');
        const { req, res, next } = mockReqRes({ quantity: 'abc' });
        middleware(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res._status).toBe(400);
    });

    test('respects min constraint', () => {
        const middleware = validateNumber('qty', { min: 1 });
        const { req, res, next } = mockReqRes({ qty: 0 });
        middleware(req, res, next);
        expect(next).not.toHaveBeenCalled();
    });
});

// ==================== requireFields() ====================
describe('requireFields()', () => {
    test('passes when all fields present', () => {
        const middleware = requireFields('name', 'email');
        const { req, res, next } = mockReqRes({ name: 'Test', email: 'a@b.com' });
        middleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('fails when fields missing', () => {
        const middleware = requireFields('name', 'email');
        const { req, res, next } = mockReqRes({ name: 'Test' });
        middleware(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(res._status).toBe(400);
    });

    test('fails when field is empty string', () => {
        const middleware = requireFields('name');
        const { req, res, next } = mockReqRes({ name: '' });
        middleware(req, res, next);
        expect(next).not.toHaveBeenCalled();
    });
});
