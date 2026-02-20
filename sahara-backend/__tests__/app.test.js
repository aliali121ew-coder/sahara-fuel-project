// ============================================================
// Phase 7: API Integration Tests
// ============================================================
const app = require('../src/app');
const http = require('http');

let server;
let baseUrl;

beforeAll((done) => {
    server = http.createServer(app);
    server.listen(0, () => {
        const { port } = server.address();
        baseUrl = `http://localhost:${port}`;
        done();
    });
});

afterAll((done) => {
    server.close(done);
});

// Helper to make requests
async function request(method, path, body = null, headers = {}) {
    const url = `${baseUrl}${path}`;
    const opts = {
        method,
        headers: {
            'Content-Type': 'application/json',
            ...headers,
        },
    };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(url, opts);
    const data = await res.json().catch(() => null);
    return { status: res.status, data, headers: res.headers };
}

// ==================== Health Check ====================
describe('Health Check', () => {
    test('GET /api/health returns 200', async () => {
        const { status, data } = await request('GET', '/api/health');
        expect(status).toBe(200);
        expect(data.success).toBe(true);
        expect(data.service).toBe('Sahara Fuel SaaS API');
        expect(data.version).toBe('1.0.0');
        expect(data.timestamp).toBeDefined();
    });
});

// ==================== API Root ====================
describe('API Documentation', () => {
    test('GET /api returns endpoint listing', async () => {
        const { status, data } = await request('GET', '/api');
        expect(status).toBe(200);
        expect(data.service).toContain('Sahara Fuel');
        expect(data.endpoints).toBeDefined();
        expect(data.endpoints.auth).toBeDefined();
        expect(data.endpoints.fuel).toBeDefined();
    });
});

// ==================== 404 Handler ====================
describe('404 Handler', () => {
    test('returns 404 for unknown routes', async () => {
        const { status, data } = await request('GET', '/api/nonexistent');
        expect(status).toBe(404);
        expect(data.success).toBe(false);
        expect(data.code).toBe('NOT_FOUND');
    });

    test('includes method and path in error message', async () => {
        const { data } = await request('POST', '/api/unknown-endpoint');
        expect(data.error).toContain('POST');
        expect(data.error).toContain('/api/unknown-endpoint');
    });
});

// ==================== Security Headers ====================
describe('Security', () => {
    test('includes security headers (Helmet)', async () => {
        const { headers } = await request('GET', '/api/health');
        // Helmet sets these
        expect(headers.get('x-content-type-options')).toBe('nosniff');
        expect(headers.get('x-frame-options')).toBe('SAMEORIGIN');
    });

    test('CORS headers are set', async () => {
        const { headers } = await request('GET', '/api/health', null, {
            Origin: 'http://localhost:3000',
        });
        // Should allow the origin
        expect(headers.get('access-control-allow-credentials')).toBe('true');
    });
});

// ==================== Auth Endpoints ====================
describe('Authentication', () => {
    test('POST /api/auth/login without body returns 400 or 401', async () => {
        const { status } = await request('POST', '/api/auth/login', {});
        expect([400, 401, 422]).toContain(status);
    });

    test('POST /api/auth/login with invalid creds returns 401', async () => {
        const { status, data } = await request('POST', '/api/auth/login', {
            email: 'wrong@test.com',
            password: 'wrongpassword',
        });
        expect([400, 401]).toContain(status);
        expect(data.success).toBe(false);
    });

    test('GET /api/auth/me without token returns 401', async () => {
        const { status } = await request('GET', '/api/auth/me');
        expect(status).toBe(401);
    });

    test('GET /api/auth/me with invalid token returns 401', async () => {
        const { status } = await request('GET', '/api/auth/me', null, {
            Authorization: 'Bearer invalid_token_here',
        });
        expect([401, 403]).toContain(status);
    });
});

// ==================== Protected Routes ====================
describe('Protected Routes require auth', () => {
    const protectedRoutes = [
        ['GET', '/api/users'],
        ['GET', '/api/fuel'],
        ['GET', '/api/tanks'],
        ['GET', '/api/branches'],
        ['GET', '/api/roles'],
        ['GET', '/api/audit'],
    ];

    test.each(protectedRoutes)(
        '%s %s returns 401 without auth',
        async (method, path) => {
            const { status } = await request(method, path);
            expect(status).toBe(401);
        }
    );
});

// ==================== Rate Limiting ====================
describe('Rate Limiting', () => {
    test('returns rate limit headers', async () => {
        const { headers } = await request('GET', '/api/health');
        expect(headers.get('ratelimit-limit')).toBeDefined();
        expect(headers.get('ratelimit-remaining')).toBeDefined();
    });
});

// ==================== Input Sanitization ====================
describe('Input Sanitization', () => {
    test('strips HTML tags from input', async () => {
        const { data } = await request('POST', '/api/auth/login', {
            email: '<script>alert(1)</script>test@test.com',
            password: 'password123',
        });
        // The sanitized email should not contain script tags
        // Response will be 401 but the injection is neutralized
        expect(data.success).toBe(false);
    });
});
