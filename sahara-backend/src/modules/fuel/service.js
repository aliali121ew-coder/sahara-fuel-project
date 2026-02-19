// ============================================================
// Fuel Module - Service Layer (Business Logic)
// ============================================================
const { v4: uuidv4 } = require('uuid');
const { query, transaction } = require('../../database/connection');
const { cacheGet, cacheSet, cacheDel } = require('../../config/redis');
const logger = require('../../config/logger');

class FuelService {

    /**
     * List fuel transactions with filters and pagination
     */
    async listTransactions(tenantId, filters = {}) {
        const { page = 1, limit = 50, type, fuel_type, status, from, to, tank_id } = filters;
        const offset = (page - 1) * limit;
        const params = [tenantId];
        const conds = ['f.tenant_id = $1'];

        if (type) { params.push(type); conds.push(`f.type = $${params.length}`); }
        if (fuel_type) { params.push(fuel_type); conds.push(`f.fuel_type = $${params.length}`); }
        if (status) { params.push(status); conds.push(`f.status = $${params.length}`); }
        if (tank_id) { params.push(tank_id); conds.push(`f.tank_id = $${params.length}`); }
        if (from) { params.push(from); conds.push(`f.created_at >= $${params.length}`); }
        if (to) { params.push(to); conds.push(`f.created_at <= $${params.length}`); }

        const where = `WHERE ${conds.join(' AND ')}`;
        const countR = await query(`SELECT COUNT(*) FROM fuel_transactions f ${where}`, params);
        params.push(limit, offset);
        const result = await query(
            `SELECT f.*, t.name AS tank_name, u.name AS created_by_name
             FROM fuel_transactions f
             LEFT JOIN tanks t ON f.tank_id = t.id
             LEFT JOIN users u ON f.created_by = u.id
             ${where} ORDER BY f.created_at DESC
             LIMIT $${params.length - 1} OFFSET $${params.length}`, params);

        const total = parseInt(countR.rows[0].count);
        return {
            data: result.rows,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                pages: Math.ceil(total / limit),
            },
        };
    }

    /**
     * Get a single transaction by ID
     */
    async getTransaction(id, tenantId) {
        const result = await query(
            `SELECT f.*, t.name AS tank_name, u.name AS created_by_name, u2.name AS approved_by_name
             FROM fuel_transactions f LEFT JOIN tanks t ON f.tank_id = t.id
             LEFT JOIN users u ON f.created_by = u.id LEFT JOIN users u2 ON f.approved_by = u2.id
             WHERE f.id = $1 AND f.tenant_id = $2`, [id, tenantId]);

        return result.rows[0] || null;
    }

    /**
     * Create a new fuel transaction with tank level updates
     */
    async createTransaction(data, userId, tenantId) {
        const id = uuidv4();
        const { type, fuel_type, quantity, unit_price = 0, supplier, tank_id,
                destination_tank_id, driver_name, truck_number, density, color_rating, notes } = data;
        const total_price = quantity * unit_price;

        const result = await transaction(async (client) => {
            const txn = await client.query(
                `INSERT INTO fuel_transactions
                 (id, tenant_id, type, fuel_type, quantity, unit_price, total_price,
                  supplier, tank_id, destination_tank_id, driver_name, truck_number,
                  density, color_rating, notes, status, created_by, created_at)
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,'pending',$16,NOW())
                 RETURNING *`,
                [id, tenantId, type, fuel_type, quantity, unit_price, total_price,
                 supplier, tank_id, destination_tank_id, driver_name, truck_number,
                 density, color_rating, notes, userId]);

            // Update tank levels based on transaction type
            await this._updateTankLevels(client, type, quantity, tank_id, destination_tank_id, tenantId);

            return txn.rows[0];
        });

        await this._invalidateStatsCache(tenantId);
        logger.info(`Fuel transaction created: ${id} (${type}, ${quantity}L)`);
        return result;
    }

    /**
     * Approve a pending transaction
     */
    async approveTransaction(id, approverId, tenantId) {
        const result = await query(
            `UPDATE fuel_transactions SET status = 'approved', approved_by = $1,
             approved_at = NOW(), updated_at = NOW()
             WHERE id = $2 AND tenant_id = $3 AND status = 'pending' RETURNING *`,
            [approverId, id, tenantId]);

        if (result.rows.length === 0) return null;

        await this._invalidateStatsCache(tenantId);
        logger.info(`Fuel transaction approved: ${id} by ${approverId}`);
        return result.rows[0];
    }

    /**
     * Delete a transaction with tank level reversal
     */
    async deleteTransaction(id, tenantId) {
        const result = await query(
            'DELETE FROM fuel_transactions WHERE id = $1 AND tenant_id = $2 RETURNING id, type, quantity, tank_id',
            [id, tenantId]);

        if (result.rows.length === 0) return null;

        const d = result.rows[0];
        if (d.tank_id) {
            const reversal = d.type === 'incoming' ? -d.quantity : d.quantity;
            await query('UPDATE tanks SET current_level = current_level + $1 WHERE id = $2', [reversal, d.tank_id]);
        }

        await this._invalidateStatsCache(tenantId);
        logger.info(`Fuel transaction deleted: ${id}`);
        return d;
    }

    /**
     * Get fuel statistics with caching
     */
    async getStats(tenantId) {
        const cacheKey = `fuel:stats:${tenantId}`;
        const cached = await cacheGet(cacheKey);
        if (cached) return cached;

        const today = new Date().toISOString().split('T')[0];
        const [todayStats, monthlyStats, typeBreakdown] = await Promise.all([
            query(
                `SELECT COALESCE(SUM(CASE WHEN type='incoming' THEN quantity END),0) AS today_incoming,
                        COALESCE(SUM(CASE WHEN type='outgoing' THEN quantity END),0) AS today_outgoing,
                        COUNT(*) AS today_transactions
                 FROM fuel_transactions WHERE tenant_id=$1 AND created_at::date=$2`,
                [tenantId, today]),
            query(
                `SELECT DATE_TRUNC('month',created_at) AS month, type,
                        SUM(quantity) AS total_quantity, SUM(total_price) AS total_value, COUNT(*) AS count
                 FROM fuel_transactions WHERE tenant_id=$1 AND created_at >= NOW()-INTERVAL '6 months'
                 GROUP BY 1,2 ORDER BY month DESC`,
                [tenantId]),
            query(
                `SELECT fuel_type, type, SUM(quantity) AS total_quantity, COUNT(*) AS count
                 FROM fuel_transactions WHERE tenant_id=$1 AND created_at >= NOW()-INTERVAL '30 days'
                 GROUP BY 1,2`,
                [tenantId]),
        ]);

        const data = {
            today: todayStats.rows[0],
            monthly: monthlyStats.rows,
            byFuelType: typeBreakdown.rows,
        };

        await cacheSet(cacheKey, data, 300); // Cache for 5 minutes
        return data;
    }

    // ==================== Private Helpers ====================

    async _updateTankLevels(client, type, quantity, tankId, destinationTankId, tenantId) {
        if (type === 'incoming' && tankId) {
            await client.query(
                'UPDATE tanks SET current_level = current_level + $1, last_fill = NOW(), updated_at = NOW() WHERE id = $2 AND tenant_id = $3',
                [quantity, tankId, tenantId]);
        }
        if (type === 'transfer' && tankId && destinationTankId) {
            await client.query('UPDATE tanks SET current_level = current_level - $1, updated_at = NOW() WHERE id = $2', [quantity, tankId]);
            await client.query('UPDATE tanks SET current_level = current_level + $1, updated_at = NOW() WHERE id = $2', [quantity, destinationTankId]);
        }
        if (type === 'outgoing' && tankId) {
            await client.query('UPDATE tanks SET current_level = current_level - $1, updated_at = NOW() WHERE id = $2', [quantity, tankId]);
        }
    }

    async _invalidateStatsCache(tenantId) {
        try {
            await cacheDel(`fuel:stats:${tenantId}`);
        } catch (e) {
            logger.warn('Cache invalidation failed:', e.message);
        }
    }
}

module.exports = new FuelService();
