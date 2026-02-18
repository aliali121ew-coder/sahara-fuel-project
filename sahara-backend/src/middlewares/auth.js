// ============================================================
// JWT Authentication Middleware
// ============================================================
const jwt = require('jsonwebtoken');
const { query } = require('../database/connection');
const { cacheGet, cacheSet } = require('../config/redis');
const logger = require('../config/logger');

const JWT_SECRET = process.env.JWT_SECRET || 'default_secret';

function authenticate(req, res, next) {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                error: 'غير مصرح - يرجى تسجيل الدخول',
                code: 'AUTH_REQUIRED',
            });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, JWT_SECRET);

        req.user = {
            id: decoded.id,
            email: decoded.email,
            role: decoded.role,
            tenantId: decoded.tenantId,
        };

        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                error: 'انتهت صلاحية الجلسة - يرجى تسجيل الدخول مجدداً',
                code: 'TOKEN_EXPIRED',
            });
        }
        return res.status(401).json({
            success: false,
            error: 'توكن غير صالح',
            code: 'INVALID_TOKEN',
        });
    }
}

function authorize(...roles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ success: false, error: 'غير مصرح', code: 'AUTH_REQUIRED' });
        }
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                error: 'ليس لديك صلاحية الوصول إلى هذا المورد',
                code: 'FORBIDDEN',
            });
        }
        next();
    };
}

function requirePermission(permission) {
    return async (req, res, next) => {
        try {
            if (req.user.role === 'admin') return next();

            const cacheKey = `perms:${req.user.id}`;
            let permissions = await cacheGet(cacheKey);

            if (!permissions) {
                const result = await query(
                    'SELECT permissions FROM users WHERE id = $1 AND is_active = true',
                    [req.user.id]
                );
                if (result.rows.length === 0) {
                    return res.status(403).json({ success: false, error: 'المستخدم غير فعّال', code: 'USER_INACTIVE' });
                }
                permissions = result.rows[0].permissions || {};
                await cacheSet(cacheKey, permissions, 600);
            }

            if (permissions[permission] !== true) {
                return res.status(403).json({
                    success: false,
                    error: `ليس لديك صلاحية: ${permission}`,
                    code: 'PERMISSION_DENIED',
                });
            }
            next();
        } catch (error) {
            logger.error('Permission check error:', error);
            next(error);
        }
    };
}

function generateTokens(user) {
    const accessToken = jwt.sign(
        { id: user.id, email: user.email, role: user.role, tenantId: user.tenant_id },
        JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );
    const refreshToken = jwt.sign(
        { id: user.id, type: 'refresh' },
        process.env.JWT_REFRESH_SECRET || 'refresh_secret',
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
    );
    return { accessToken, refreshToken };
}

module.exports = { authenticate, authorize, requirePermission, generateTokens };
