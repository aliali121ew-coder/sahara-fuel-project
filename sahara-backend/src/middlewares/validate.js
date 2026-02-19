// ============================================================
// Input Validation Middleware
// ============================================================

/**
 * Sanitize a string: trim, remove HTML tags
 */
function sanitize(str) {
    if (typeof str !== 'string') return str;
    return str.trim().replace(/<[^>]*>/g, '');
}

/**
 * Recursively sanitize all string values in an object
 */
function sanitizeBody(obj) {
    if (!obj || typeof obj !== 'object') return obj;
    const cleaned = {};
    for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'string') {
            cleaned[key] = sanitize(value);
        } else if (Array.isArray(value)) {
            cleaned[key] = value.map(v => typeof v === 'string' ? sanitize(v) : v);
        } else {
            cleaned[key] = value;
        }
    }
    return cleaned;
}

/**
 * Middleware: sanitize req.body
 */
function sanitizeInput(req, res, next) {
    if (req.body && typeof req.body === 'object') {
        req.body = sanitizeBody(req.body);
    }
    next();
}

/**
 * Validate required fields in req.body
 * @param {string[]} fields - Array of required field names
 */
function requireFields(...fields) {
    return (req, res, next) => {
        const missing = fields.filter(f => {
            const val = req.body[f];
            return val === undefined || val === null || val === '';
        });
        if (missing.length > 0) {
            return res.status(400).json({
                success: false,
                error: `الحقول المطلوبة مفقودة: ${missing.join(', ')}`,
                code: 'VALIDATION_ERROR',
                details: missing.map(f => ({ field: f, message: 'مطلوب' })),
            });
        }
        next();
    };
}

/**
 * Validate email format
 */
function validateEmail(field = 'email') {
    return (req, res, next) => {
        const email = req.body[field];
        if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'صيغة البريد الإلكتروني غير صالحة',
                code: 'VALIDATION_ERROR',
            });
        }
        next();
    };
}

/**
 * Validate password strength
 */
function validatePassword(field = 'password', minLength = 6) {
    return (req, res, next) => {
        const password = req.body[field];
        if (password && password.length < minLength) {
            return res.status(400).json({
                success: false,
                error: `كلمة المرور يجب أن تكون ${minLength} أحرف على الأقل`,
                code: 'VALIDATION_ERROR',
            });
        }
        next();
    };
}

/**
 * Validate numeric field
 */
function validateNumber(field, { min, max } = {}) {
    return (req, res, next) => {
        const val = req.body[field];
        if (val !== undefined && val !== null) {
            const num = Number(val);
            if (isNaN(num)) {
                return res.status(400).json({
                    success: false,
                    error: `الحقل ${field} يجب أن يكون رقماً`,
                    code: 'VALIDATION_ERROR',
                });
            }
            if (min !== undefined && num < min) {
                return res.status(400).json({
                    success: false,
                    error: `الحقل ${field} يجب أن يكون ${min} على الأقل`,
                    code: 'VALIDATION_ERROR',
                });
            }
            if (max !== undefined && num > max) {
                return res.status(400).json({
                    success: false,
                    error: `الحقل ${field} يجب ألا يتجاوز ${max}`,
                    code: 'VALIDATION_ERROR',
                });
            }
        }
        next();
    };
}

module.exports = {
    sanitize,
    sanitizeInput,
    requireFields,
    validateEmail,
    validatePassword,
    validateNumber,
};
