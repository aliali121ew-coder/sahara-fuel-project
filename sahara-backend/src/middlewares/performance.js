// ============================================================
// Phase 5: Performance Middleware
// - Gzip/Brotli compression
// - ETag generation
// - Response caching headers
// - Request duration tracking
// ============================================================
const zlib = require('zlib');
const crypto = require('crypto');
const logger = require('../config/logger');

// ── Compression Middleware ──────────────────────────────────
function compress(req, res, next) {
    const originalSend = res.send;
    const accept = req.headers['accept-encoding'] || '';

    res.send = function (body) {
        // Skip if already compressed, very small, or non-JSON
        if (
            res.getHeader('content-encoding') ||
            !body ||
            (typeof body === 'string' && body.length < 1024) ||
            (Buffer.isBuffer(body) && body.length < 1024)
        ) {
            return originalSend.call(this, body);
        }

        const raw = typeof body === 'string' ? body : JSON.stringify(body);

        if (accept.includes('br')) {
            zlib.brotliCompress(Buffer.from(raw), (err, result) => {
                if (err) return originalSend.call(this, body);
                res.setHeader('Content-Encoding', 'br');
                res.setHeader('Content-Length', result.length);
                res.removeHeader('Content-Length'); // let chunked handle it
                originalSend.call(this, result);
            });
        } else if (accept.includes('gzip')) {
            zlib.gzip(Buffer.from(raw), (err, result) => {
                if (err) return originalSend.call(this, body);
                res.setHeader('Content-Encoding', 'gzip');
                res.removeHeader('Content-Length');
                originalSend.call(this, result);
            });
        } else {
            return originalSend.call(this, body);
        }
    };
    next();
}

// ── ETag Middleware ─────────────────────────────────────────
function etag(req, res, next) {
    if (req.method !== 'GET') return next();

    const originalJson = res.json;
    res.json = function (body) {
        const str = JSON.stringify(body);
        const hash = crypto.createHash('md5').update(str).digest('hex');
        const tag = `"${hash}"`;
        res.setHeader('ETag', tag);

        if (req.headers['if-none-match'] === tag) {
            return res.status(304).end();
        }
        return originalJson.call(this, body);
    };
    next();
}

// ── Cache-Control Headers ──────────────────────────────────
function cacheControl(maxAge = 0, scope = 'private') {
    return (req, res, next) => {
        if (req.method === 'GET') {
            res.setHeader('Cache-Control', `${scope}, max-age=${maxAge}`);
            if (maxAge > 0) {
                res.setHeader('Expires', new Date(Date.now() + maxAge * 1000).toUTCString());
            }
        } else {
            res.setHeader('Cache-Control', 'no-store');
        }
        next();
    };
}

// Preset: public data (stats, lists) — 5 min
const cachePublic = cacheControl(300, 'public');
// Preset: private data (user profile) — 1 min
const cachePrivate = cacheControl(60, 'private');
// Preset: no cache (mutations)
const noCache = cacheControl(0, 'no-store');

// ── Request Duration Tracking ──────────────────────────────
function requestTimer(req, res, next) {
    const start = process.hrtime.bigint();
    res.on('finish', () => {
        const duration = Number(process.hrtime.bigint() - start) / 1e6; // ms
        res.setHeader('X-Response-Time', `${duration.toFixed(2)}ms`);
        if (duration > 2000) {
            logger.warn(`⏱ Slow request: ${req.method} ${req.originalUrl} took ${duration.toFixed(0)}ms`);
        }
    });
    next();
}

// ── Pagination Helper ──────────────────────────────────────
function parsePagination(req, defaults = { page: 1, limit: 25, maxLimit: 100 }) {
    const page = Math.max(1, parseInt(req.query.page) || defaults.page);
    const limit = Math.min(
        defaults.maxLimit,
        Math.max(1, parseInt(req.query.limit) || defaults.limit)
    );
    const offset = (page - 1) * limit;
    const sortBy = req.query.sort_by || 'created_at';
    const sortOrder = req.query.sort_order === 'asc' ? 'ASC' : 'DESC';

    return { page, limit, offset, sortBy, sortOrder };
}

// ── Query Builder with Cache ───────────────────────────────
const { cacheGet, cacheSet } = require('../config/redis');

async function cachedQuery(pool, key, sql, params = [], ttl = 300) {
    const cached = await cacheGet(key);
    if (cached) return cached;

    const { rows } = await pool.query(sql, params);
    await cacheSet(key, rows, ttl);
    return rows;
}

module.exports = {
    compress,
    etag,
    cacheControl,
    cachePublic,
    cachePrivate,
    noCache,
    requestTimer,
    parsePagination,
    cachedQuery,
};
