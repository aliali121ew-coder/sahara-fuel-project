// ============================================================
// Phase 10: Monitoring, Metrics & Health Checks
// - Application metrics collection (in-memory Prometheus-style)
// - Detailed health check endpoint
// - Request metrics middleware
// - Readiness & liveness probes
// ============================================================
const os = require('os');
const logger = require('../config/logger');

// ── In-Memory Metrics Store ────────────────────────────────
const metrics = {
    requests: { total: 0, byMethod: {}, byStatus: {}, byRoute: {} },
    errors: { total: 0, by4xx: 0, by5xx: 0 },
    latency: { sum: 0, count: 0, max: 0, buckets: {} },
    startTime: Date.now(),
};

// ── Metrics Middleware ──────────────────────────────────────
function metricsCollector(req, res, next) {
    const start = process.hrtime.bigint();
    metrics.requests.total++;
    metrics.requests.byMethod[req.method] =
        (metrics.requests.byMethod[req.method] || 0) + 1;

    res.on('finish', () => {
        const durationMs = Number(process.hrtime.bigint() - start) / 1e6;

        // Status code tracking
        const statusGroup = `${Math.floor(res.statusCode / 100)}xx`;
        metrics.requests.byStatus[statusGroup] =
            (metrics.requests.byStatus[statusGroup] || 0) + 1;

        if (res.statusCode >= 400 && res.statusCode < 500) metrics.errors.by4xx++;
        if (res.statusCode >= 500) metrics.errors.by5xx++;
        if (res.statusCode >= 400) metrics.errors.total++;

        // Route tracking (simplified path)
        const route = req.route?.path || req.path?.replace(/\/[a-f0-9-]{36}/g, '/:id') || 'unknown';
        if (!metrics.requests.byRoute[route]) {
            metrics.requests.byRoute[route] = { count: 0, totalMs: 0 };
        }
        metrics.requests.byRoute[route].count++;
        metrics.requests.byRoute[route].totalMs += durationMs;

        // Latency tracking
        metrics.latency.sum += durationMs;
        metrics.latency.count++;
        if (durationMs > metrics.latency.max) metrics.latency.max = durationMs;

        // Histogram buckets
        const buckets = [10, 50, 100, 250, 500, 1000, 2500, 5000];
        for (const b of buckets) {
            if (durationMs <= b) {
                metrics.latency.buckets[`le_${b}ms`] =
                    (metrics.latency.buckets[`le_${b}ms`] || 0) + 1;
                break;
            }
        }
    });
    next();
}

// ── Health Check (Liveness) ────────────────────────────────
function livenessProbe(req, res) {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: Math.floor((Date.now() - metrics.startTime) / 1000),
    });
}

// ── Readiness Check (detailed) ─────────────────────────────
async function readinessProbe(req, res) {
    const checks = {};
    let healthy = true;

    // Check database
    try {
        const { getPool } = require('../database/connection');
        const pool = getPool();
        if (pool) {
            const start = Date.now();
            await pool.query('SELECT 1');
            checks.database = {
                status: 'ok',
                latencyMs: Date.now() - start,
                totalCount: pool.totalCount,
                idleCount: pool.idleCount,
                waitingCount: pool.waitingCount,
            };
        } else {
            checks.database = { status: 'not_connected' };
            healthy = false;
        }
    } catch (err) {
        checks.database = { status: 'error', message: err.message };
        healthy = false;
    }

    // Check Redis
    try {
        const { getRedis } = require('../config/redis');
        const redis = getRedis();
        if (redis) {
            const start = Date.now();
            await redis.ping();
            checks.redis = { status: 'ok', latencyMs: Date.now() - start };
        } else {
            checks.redis = { status: 'not_connected' };
            // Redis is optional, don't mark unhealthy
        }
    } catch (err) {
        checks.redis = { status: 'error', message: err.message };
    }

    // System resources
    checks.system = {
        memoryUsage: {
            rss: `${(process.memoryUsage().rss / 1024 / 1024).toFixed(1)}MB`,
            heapUsed: `${(process.memoryUsage().heapUsed / 1024 / 1024).toFixed(1)}MB`,
            heapTotal: `${(process.memoryUsage().heapTotal / 1024 / 1024).toFixed(1)}MB`,
        },
        cpuLoad: os.loadavg(),
        freeMemory: `${(os.freemem() / 1024 / 1024).toFixed(0)}MB`,
        uptime: `${Math.floor(process.uptime())}s`,
    };

    const statusCode = healthy ? 200 : 503;
    res.status(statusCode).json({
        status: healthy ? 'ready' : 'degraded',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        checks,
    });
}

// ── Metrics Endpoint (Prometheus-style) ────────────────────
function metricsEndpoint(req, res) {
    const avgLatency = metrics.latency.count > 0
        ? (metrics.latency.sum / metrics.latency.count).toFixed(2)
        : 0;

    // Top 10 slowest routes
    const slowRoutes = Object.entries(metrics.requests.byRoute)
        .map(([route, data]) => ({
            route,
            count: data.count,
            avgMs: (data.totalMs / data.count).toFixed(2),
        }))
        .sort((a, b) => b.avgMs - a.avgMs)
        .slice(0, 10);

    res.json({
        uptime: Math.floor((Date.now() - metrics.startTime) / 1000),
        requests: {
            total: metrics.requests.total,
            byMethod: metrics.requests.byMethod,
            byStatus: metrics.requests.byStatus,
        },
        errors: metrics.errors,
        latency: {
            averageMs: parseFloat(avgLatency),
            maxMs: parseFloat(metrics.latency.max.toFixed(2)),
            buckets: metrics.latency.buckets,
        },
        slowRoutes,
        memory: {
            rss: `${(process.memoryUsage().rss / 1024 / 1024).toFixed(1)}MB`,
            heapUsed: `${(process.memoryUsage().heapUsed / 1024 / 1024).toFixed(1)}MB`,
        },
    });
}

// ── Reset Metrics (for testing) ────────────────────────────
function resetMetrics() {
    metrics.requests = { total: 0, byMethod: {}, byStatus: {}, byRoute: {} };
    metrics.errors = { total: 0, by4xx: 0, by5xx: 0 };
    metrics.latency = { sum: 0, count: 0, max: 0, buckets: {} };
    metrics.startTime = Date.now();
}

module.exports = {
    metricsCollector,
    livenessProbe,
    readinessProbe,
    metricsEndpoint,
    resetMetrics,
    metrics,
};
