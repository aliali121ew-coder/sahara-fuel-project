// ============================================================
// Phase 7: Test Environment Setup
// ============================================================
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret_key_for_ci_min_32_chars_long';
process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_for_ci_min_32chars';
process.env.DB_HOST = process.env.DB_HOST || 'localhost';
process.env.DB_PORT = process.env.DB_PORT || '5432';
process.env.DB_NAME = process.env.DB_NAME || 'sahara_fuel_test';
process.env.DB_USER = process.env.DB_USER || 'test_user';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || 'test_password';
process.env.REDIS_HOST = process.env.REDIS_HOST || 'localhost';
process.env.REDIS_PORT = process.env.REDIS_PORT || '6379';

// Global timeout for async tests
jest.setTimeout(15000);
