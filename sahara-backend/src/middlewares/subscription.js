// ============================================================
// Subscription Validation Middleware
// ============================================================
const { query } = require('../database/connection');
const { cacheGet, cacheSet } = require('../config/redis');
const logger = require('../config/logger');

function requireActiveSubscription(req, res, next) {
    return checkSubscription()(req, res, next);
}

function checkLimit(limitType) {
    return async (req, res, next) => {
        try {
            if (!req.user || !req.user.tenantId) return next();

            const cacheKey = `sub:${req.user.tenantId}`;
            let sub = await cacheGet(cacheKey);

            if (!sub) {
                const result = await query(
                    `SELECT s.*, sp.max_users, sp.max_stations, sp.max_tanks
           FROM subscriptions s
           JOIN subscription_plans sp ON s.plan_id = sp.id
           WHERE s.tenant_id = $1 AND s.status = 'active' AND s.end_date > NOW()
           ORDER BY s.end_date DESC LIMIT 1`,
                    [req.user.tenantId]
                );
                sub = result.rows.length === 0
                    ? { max_users: 3, max_stations: 1, max_tanks: 5 }
                    : result.rows[0];
                await cacheSet(cacheKey, sub, 600);
            }

            const maxVal = sub[`max_${limitType}`];
            if (maxVal === -1) return next();

            let currentCount = 0;
            const countQuery = {
                users: 'SELECT COUNT(*) FROM users WHERE tenant_id = $1 AND is_active = true',
                stations: 'SELECT COUNT(*) FROM branches WHERE tenant_id = $1 AND is_active = true',
                tanks: 'SELECT COUNT(*) FROM tanks WHERE tenant_id = $1',
            };

            if (countQuery[limitType]) {
                const r = await query(countQuery[limitType], [req.user.tenantId]);
                currentCount = parseInt(r.rows[0].count);
            }

            if (currentCount >= maxVal) {
                const labels = { users: 'المستخدمين', stations: 'المحطات', tanks: 'الخزانات' };
                return res.status(403).json({
                    success: false,
                    error: `تم بلوغ الحد الأقصى من ${labels[limitType]} (${maxVal}) - قم بترقية الباقة`,
                    code: 'SUBSCRIPTION_LIMIT',
                    limit: { type: limitType, max: maxVal, current: currentCount },
                });
            }

            next();
        } catch (error) {
            logger.error('Subscription check error:', error);
            next();
        }
    };
}

function checkSubscription() {
    return async (req, res, next) => {
        try {
            if (!req.user || !req.user.tenantId) return next();

            const result = await query(
                `SELECT id, status, end_date FROM subscriptions
         WHERE tenant_id = $1 AND status = 'active' AND end_date > NOW() LIMIT 1`,
                [req.user.tenantId]
            );

            if (result.rows.length === 0) {
                const tenant = await query('SELECT created_at FROM tenants WHERE id = $1', [req.user.tenantId]);
                if (tenant.rows.length > 0) {
                    const trialEnd = new Date(new Date(tenant.rows[0].created_at).getTime() + 30 * 24 * 60 * 60 * 1000);
                    if (new Date() < trialEnd) {
                        req.subscription = { plan: 'trial', trialEndsAt: trialEnd };
                        return next();
                    }
                }
                return res.status(403).json({
                    success: false,
                    error: 'الاشتراك منتهي أو غير فعّال - يرجى التجديد',
                    code: 'SUBSCRIPTION_EXPIRED',
                });
            }

            req.subscription = result.rows[0];
            next();
        } catch (error) {
            logger.error('Subscription validation error:', error);
            next();
        }
    };
}

module.exports = { requireActiveSubscription, checkLimit, checkSubscription };
