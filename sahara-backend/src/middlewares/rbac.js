// ============================================================
// RBAC - Role-Based Access Control + Validation Middleware
// ============================================================
const Joi = require('joi');

/**
 * Middleware للتحقق من صحة البيانات (Joi Validation)
 * @param {Object} schema - { body, params, query }
 */
function validate(schema) {
    return (req, res, next) => {
        const errors = [];

        ['body', 'params', 'query'].forEach((key) => {
            if (schema[key]) {
                const { error, value } = schema[key].validate(req[key], {
                    abortEarly: false,
                    stripUnknown: true,
                    messages: {
                        'any.required': '{{#label}} مطلوب',
                        'string.empty': '{{#label}} لا يمكن أن يكون فارغاً',
                        'string.email': 'البريد الإلكتروني غير صالح',
                        'string.min': '{{#label}} يجب أن يكون {{#limit}} أحرف على الأقل',
                        'string.max': '{{#label}} يجب ألا يتجاوز {{#limit}} حرف',
                        'number.min': '{{#label}} يجب أن يكون {{#limit}} على الأقل',
                        'number.max': '{{#label}} يجب ألا يتجاوز {{#limit}}',
                        'number.positive': '{{#label}} يجب أن يكون رقماً موجباً',
                    },
                });

                if (error) {
                    errors.push(
                        ...error.details.map((d) => ({
                            field: d.path.join('.'),
                            message: d.message,
                        }))
                    );
                } else {
                    req[key] = value;
                }
            }
        });

        if (errors.length > 0) {
            return res.status(400).json({
                success: false,
                error: 'بيانات غير صالحة',
                code: 'VALIDATION_ERROR',
                details: errors,
            });
        }

        next();
    };
}

/**
 * الصلاحيات الافتراضية لكل دور
 */
const DEFAULT_PERMISSIONS = {
    admin: {
        dashboard: true, incoming_report: true, sahara_balance: true,
        union_balance: true, tanks: true, reports: true,
        advanced_reports: true, station_manager: true,
        notifications: true, settings: true, audit_trail: true,
        users_manage: true, branches_manage: true,
        fuel_create: true, fuel_approve: true, fuel_delete: true,
        tanks_manage: true, export_data: true,
    },
    manager: {
        dashboard: true, incoming_report: true, sahara_balance: true,
        union_balance: true, tanks: true, reports: true,
        advanced_reports: true, station_manager: true,
        notifications: true, settings: false, audit_trail: false,
        users_manage: false, branches_manage: false,
        fuel_create: true, fuel_approve: true, fuel_delete: false,
        tanks_manage: true, export_data: true,
    },
    operator: {
        dashboard: true, incoming_report: true, sahara_balance: false,
        union_balance: false, tanks: true, reports: true,
        advanced_reports: false, station_manager: false,
        notifications: true, settings: false, audit_trail: false,
        users_manage: false, branches_manage: false,
        fuel_create: true, fuel_approve: false, fuel_delete: false,
        tanks_manage: false, export_data: false,
    },
    viewer: {
        dashboard: true, incoming_report: false, sahara_balance: false,
        union_balance: false, tanks: false, reports: true,
        advanced_reports: false, station_manager: false,
        notifications: true, settings: false, audit_trail: false,
        users_manage: false, branches_manage: false,
        fuel_create: false, fuel_approve: false, fuel_delete: false,
        tanks_manage: false, export_data: false,
    },
    auditor: {
        dashboard: true, incoming_report: true, sahara_balance: true,
        union_balance: true, tanks: true, reports: true,
        advanced_reports: true, station_manager: true,
        notifications: true, settings: false, audit_trail: true,
        users_manage: false, branches_manage: false,
        fuel_create: false, fuel_approve: false, fuel_delete: false,
        tanks_manage: false, export_data: true,
    },
};

function getDefaultPermissions(role) {
    return DEFAULT_PERMISSIONS[role] || DEFAULT_PERMISSIONS.viewer;
}

module.exports = { validate, getDefaultPermissions, DEFAULT_PERMISSIONS };
