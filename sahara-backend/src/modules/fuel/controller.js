// ============================================================
// Fuel Module - Controller (thin layer, delegates to service)
// ============================================================
const fuelService = require('./service');

exports.list = async (req, res, next) => {
    try {
        const result = await fuelService.listTransactions(req.user.tenantId, req.query);
        res.json({ success: true, ...result });
    } catch (error) { next(error); }
};

exports.getById = async (req, res, next) => {
    try {
        const data = await fuelService.getTransaction(req.params.id, req.user.tenantId);
        if (!data) {
            return res.status(404).json({ success: false, error: 'المعاملة غير موجودة', code: 'NOT_FOUND' });
        }
        res.json({ success: true, data });
    } catch (error) { next(error); }
};

exports.create = async (req, res, next) => {
    try {
        const data = await fuelService.createTransaction(req.body, req.user.id, req.user.tenantId);
        res.status(201).json({ success: true, data });
    } catch (error) { next(error); }
};

exports.approve = async (req, res, next) => {
    try {
        const data = await fuelService.approveTransaction(req.params.id, req.user.id, req.user.tenantId);
        if (!data) {
            return res.status(404).json({ success: false, error: 'المعاملة غير موجودة أو معتمدة', code: 'NOT_FOUND' });
        }
        res.json({ success: true, data });
    } catch (error) { next(error); }
};

exports.remove = async (req, res, next) => {
    try {
        const data = await fuelService.deleteTransaction(req.params.id, req.user.tenantId);
        if (!data) {
            return res.status(404).json({ success: false, error: 'المعاملة غير موجودة', code: 'NOT_FOUND' });
        }
        res.json({ success: true, message: 'تم حذف المعاملة بنجاح' });
    } catch (error) { next(error); }
};

exports.stats = async (req, res, next) => {
    try {
        const data = await fuelService.getStats(req.user.tenantId);
        res.json({ success: true, data });
    } catch (error) { next(error); }
};
