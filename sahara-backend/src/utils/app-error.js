// ============================================================
// Phase 6: Standardized Error Handling System
// - Custom error classes with Arabic messages
// - Error categorization (validation, auth, database, business)
// - Circuit breaker pattern
// - Async handler wrapper
// ============================================================
const logger = require('../config/logger');

// ── Base Application Error ─────────────────────────────────
class AppError extends Error {
    constructor(message, statusCode = 500, code = 'INTERNAL_ERROR', details = null) {
        super(message);
        this.name = this.constructor.name;
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
        this.isOperational = true; // distinguishes from programmer errors
        Error.captureStackTrace(this, this.constructor);
    }

    toJSON() {
        return {
            success: false,
            error: this.message,
            code: this.code,
            ...(this.details && { details: this.details }),
        };
    }
}

// ── Specialized Error Classes ──────────────────────────────
class ValidationError extends AppError {
    constructor(message = 'بيانات غير صالحة', details = null) {
        super(message, 400, 'VALIDATION_ERROR', details);
    }
}

class AuthenticationError extends AppError {
    constructor(message = 'يرجى تسجيل الدخول') {
        super(message, 401, 'AUTH_REQUIRED');
    }
}

class ForbiddenError extends AppError {
    constructor(message = 'لا تملك صلاحية لهذا الإجراء') {
        super(message, 403, 'FORBIDDEN');
    }
}

class NotFoundError extends AppError {
    constructor(resource = 'المورد', message = null) {
        super(message || `${resource} غير موجود`, 404, 'NOT_FOUND');
    }
}

class ConflictError extends AppError {
    constructor(message = 'البيانات موجودة مسبقاً') {
        super(message, 409, 'CONFLICT');
    }
}

class RateLimitError extends AppError {
    constructor(message = 'تم تجاوز الحد الأقصى للطلبات') {
        super(message, 429, 'RATE_LIMITED');
    }
}

class DatabaseError extends AppError {
    constructor(message = 'خطأ في قاعدة البيانات') {
        super(message, 500, 'DATABASE_ERROR');
        this.isOperational = false; // may indicate system problem
    }
}

class ExternalServiceError extends AppError {
    constructor(service, message = null) {
        super(message || `خدمة ${service} غير متوفرة حالياً`, 502, 'EXTERNAL_SERVICE_ERROR');
    }
}

// ── Async Handler Wrapper ──────────────────────────────────
// Wraps async route handlers to catch errors automatically
function asyncHandler(fn) {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
}

// ── Circuit Breaker ────────────────────────────────────────
class CircuitBreaker {
    constructor(name, options = {}) {
        this.name = name;
        this.failureThreshold = options.failureThreshold || 5;
        this.resetTimeout = options.resetTimeout || 30000; // 30s
        this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
        this.failureCount = 0;
        this.lastFailure = null;
        this.successCount = 0;
    }

    async execute(fn) {
        if (this.state === 'OPEN') {
            if (Date.now() - this.lastFailure > this.resetTimeout) {
                this.state = 'HALF_OPEN';
                logger.info(`🔄 Circuit [${this.name}] → HALF_OPEN`);
            } else {
                throw new ExternalServiceError(this.name, `${this.name} متوقف مؤقتاً - يرجى المحاولة لاحقاً`);
            }
        }

        try {
            const result = await fn();
            this._onSuccess();
            return result;
        } catch (err) {
            this._onFailure();
            throw err;
        }
    }

    _onSuccess() {
        if (this.state === 'HALF_OPEN') {
            this.successCount++;
            if (this.successCount >= 2) {
                this.state = 'CLOSED';
                this.failureCount = 0;
                this.successCount = 0;
                logger.info(`✅ Circuit [${this.name}] → CLOSED (recovered)`);
            }
        } else {
            this.failureCount = 0;
        }
    }

    _onFailure() {
        this.failureCount++;
        this.lastFailure = Date.now();
        this.successCount = 0;

        if (this.failureCount >= this.failureThreshold) {
            this.state = 'OPEN';
            logger.error(`🔴 Circuit [${this.name}] → OPEN (${this.failureCount} failures)`);
        }
    }

    getState() {
        return {
            name: this.name,
            state: this.state,
            failures: this.failureCount,
            lastFailure: this.lastFailure ? new Date(this.lastFailure).toISOString() : null,
        };
    }
}

// ── Global Error Handler Middleware ────────────────────────
function globalErrorHandler(err, req, res, _next) {
    // Generate request-scoped ID for tracing
    const requestId = req.headers['x-request-id'] || `req_${Date.now().toString(36)}`;

    // Determine if this is an operational error
    if (err instanceof AppError) {
        // Operational: expected error (validation, auth, not found, etc.)
        if (err.statusCode >= 500) {
            logger.error({
                requestId,
                message: err.message,
                code: err.code,
                stack: err.stack,
                url: req.originalUrl,
                method: req.method,
                userId: req.user?.id,
            });
        } else {
            logger.warn({
                requestId,
                message: err.message,
                code: err.code,
                url: req.originalUrl,
                method: req.method,
            });
        }

        return res.status(err.statusCode).json({
            ...err.toJSON(),
            requestId,
        });
    }

    // Joi validation errors
    if (err.isJoi) {
        const details = err.details.map(d => ({
            field: d.path.join('.'),
            message: d.message,
        }));
        return res.status(400).json({
            success: false,
            error: 'بيانات غير صالحة',
            code: 'VALIDATION_ERROR',
            details,
            requestId,
        });
    }

    // PostgreSQL errors
    if (err.code && err.code.startsWith('23')) {
        const pgMessages = {
            '23505': 'البيانات موجودة مسبقاً (تكرار)',
            '23503': 'لا يمكن الحذف - يوجد بيانات مرتبطة',
            '23502': 'حقل مطلوب مفقود',
            '23514': 'قيمة غير صالحة',
        };
        return res.status(409).json({
            success: false,
            error: pgMessages[err.code] || 'خطأ في قاعدة البيانات',
            code: 'DATABASE_CONSTRAINT',
            requestId,
        });
    }

    // Unknown / programmer error — log full stack
    logger.error({
        requestId,
        message: err.message || 'خطأ غير معروف',
        stack: err.stack,
        url: req.originalUrl,
        method: req.method,
        userId: req.user?.id,
    });

    res.status(500).json({
        success: false,
        error: process.env.NODE_ENV === 'production'
            ? 'خطأ داخلي في النظام'
            : err.message,
        code: 'INTERNAL_ERROR',
        requestId,
    });
}

module.exports = {
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
};
