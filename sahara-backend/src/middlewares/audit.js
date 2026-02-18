// ============================================================
// Audit Trail Logger Middleware
// ============================================================
const { query } = require('../database/connection');
const logger = require('../config/logger');

async function logAudit({ userId, action, resource, resourceId, details, ipAddress, tenantId }) {
    try {
        await query(
            `INSERT INTO audit_logs (user_id, action, resource, resource_id, details, ip_address, tenant_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
            [userId, action, resource, resourceId, JSON.stringify(details || {}), ipAddress, tenantId]
        );
    } catch (error) {
        logger.error('Audit log error:', error);
    }
}

function auditMiddleware(action, resource) {
    return (req, res, next) => {
        const originalJson = res.json.bind(res);
        res.json = function (data) {
            if (data && data.success !== false && req.user) {
                logAudit({
                    userId: req.user.id,
                    action,
                    resource,
                    resourceId: req.params.id || data?.data?.id || null,
                    details: { method: req.method, path: req.originalUrl, statusCode: res.statusCode },
                    ipAddress: req.ip || req.connection.remoteAddress,
                    tenantId: req.user.tenantId,
                });
            }
            return originalJson(data);
        };
        next();
    };
}

module.exports = { logAudit, auditMiddleware };
