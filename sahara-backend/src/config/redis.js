// ============================================================
// Redis Configuration
// ============================================================
const { createClient } = require('redis');
const logger = require('./logger');

let client = null;

async function connectRedis() {
    try {
        const redisClient = createClient({
            url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`,
            password: process.env.REDIS_PASSWORD || undefined,
            socket: {
                connectTimeout: 3000,
                reconnectStrategy: false,  // لا تحاول إعادة الاتصال
            },
        });

        redisClient.on('error', () => { });  // صامت - لا نطبع أخطاء متكررة

        await redisClient.connect();
        logger.info('✅ Redis متصل');
        client = redisClient;
        return client;
    } catch (error) {
        logger.warn('⚠️ Redis غير متاح - يعمل بدون cache');
        client = null;
        return null;
    }
}

function getRedis() { return client; }

async function cacheGet(key) {
    if (!client) return null;
    try {
        const data = await client.get(key);
        return data ? JSON.parse(data) : null;
    } catch { return null; }
}

async function cacheSet(key, value, ttlSeconds = 300) {
    if (!client) return;
    try { await client.setEx(key, ttlSeconds, JSON.stringify(value)); }
    catch (err) { logger.warn('Cache set error:', err.message); }
}

async function cacheDel(pattern) {
    if (!client) return;
    try {
        const keys = await client.keys(pattern);
        if (keys.length > 0) await client.del(keys);
    } catch (err) { logger.warn('Cache delete error:', err.message); }
}

module.exports = { connectRedis, getRedis, cacheGet, cacheSet, cacheDel };
