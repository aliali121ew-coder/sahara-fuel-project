// ============================================================
// Database Seed - Default Data
// ============================================================
require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '..', '.env') });
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'sahara_fuel',
    user: process.env.DB_USER || 'sahara_admin',
    password: process.env.DB_PASSWORD || 'your_strong_password',
});

async function seed() {
    console.log('🌱 بدء إدخال البيانات الافتراضية...');
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        await client.query(`
      INSERT INTO subscription_plans (id, name, name_en, price, duration_days, max_users, max_stations, max_tanks, features) VALUES
        ('trial','تجريبي','Trial',0,30,3,1,5,'["لوحة التحكم","إدارة الخزانات"]'),
        ('basic','أساسي','Basic',50000,365,5,2,10,'["التقارير","إدارة المستخدمين"]'),
        ('professional','احترافي','Professional',120000,365,15,5,30,'["تقارير متقدمة","سجل التدقيق"]'),
        ('enterprise','مؤسسي','Enterprise',250000,365,-1,-1,-1,'["غير محدود","دعم أولوي"]')
      ON CONFLICT (id) DO NOTHING`);

        const tenantId = uuidv4();
        await client.query(`INSERT INTO tenants (id,name,code,owner_email,plan,is_active,created_at) VALUES ($1,'شركة صحاري للوقود','SAHARA','admin@sahara-fuel.com','professional',true,NOW())`, [tenantId]);

        await client.query(`INSERT INTO subscriptions (id,tenant_id,plan_id,status,start_date,end_date,amount_paid) VALUES ($1,$2,'professional','active',NOW(),NOW()+INTERVAL '365 days',120000)`, [uuidv4(), tenantId]);

        const users = [
            { name: 'مدير النظام', email: 'admin@sahara-fuel.com', password: 'admin123', role: 'admin' },
            { name: 'مدير المحطة', email: 'manager@sahara-fuel.com', password: 'manager123', role: 'manager' },
            { name: 'المشغّل', email: 'operator@sahara-fuel.com', password: 'operator123', role: 'operator' },
            { name: 'المستعرض', email: 'viewer@sahara-fuel.com', password: 'viewer123', role: 'viewer' },
            { name: 'المدقق', email: 'auditor@sahara-fuel.com', password: 'auditor123', role: 'auditor' },
        ];
        for (const u of users) {
            const hash = await bcrypt.hash(u.password, 12);
            await client.query(
                `INSERT INTO users (id,tenant_id,name,email,password_hash,role,is_active,permissions,created_at) VALUES ($1,$2,$3,$4,$5,$6,true,'{}',NOW())`,
                [uuidv4(), tenantId, u.name, u.email, hash, u.role]);
        }

        const branchId = uuidv4();
        await client.query(`INSERT INTO branches (id,tenant_id,name,code,address,phone,daily_target,is_active,created_at) VALUES ($1,$2,'المحطة الرئيسية','MAIN','كربلاء','07801234567',50000,true,NOW())`, [branchId, tenantId]);

        const tanksData = [
            { name: 'خزان البنزين الرئيسي', type: 'benzene', cap: 50000, cur: 35000 },
            { name: 'خزان الديزل الرئيسي', type: 'diesel', cap: 80000, cur: 60000 },
            { name: 'خزان الكاز', type: 'kerosene', cap: 30000, cur: 15000 },
            { name: 'خزان البنزين الفرعي', type: 'benzene', cap: 25000, cur: 10000 },
            { name: 'خزان الغاز', type: 'gas', cap: 20000, cur: 8000 },
        ];
        for (const t of tanksData) {
            await client.query(
                `INSERT INTO tanks (id,tenant_id,name,location,fuel_type,capacity,current_level,min_level,status,branch_id,created_at) VALUES ($1,$2,$3,'المحطة الرئيسية',$4,$5,$6,$7,'active',$8,NOW())`,
                [uuidv4(), tenantId, t.name, t.type, t.cap, t.cur, t.cap * 0.1, branchId]);
        }

        await client.query('COMMIT');
        console.log('✅ تم إدخال البيانات الافتراضية!');
        console.log('📋 بيانات الدخول:');
        console.log('  admin@sahara-fuel.com    / admin123');
        console.log('  manager@sahara-fuel.com  / manager123');
        console.log('  operator@sahara-fuel.com / operator123');
        console.log('  viewer@sahara-fuel.com   / viewer123');
        console.log('  auditor@sahara-fuel.com  / auditor123');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ خطأ:', error.message);
        throw error;
    } finally { client.release(); await pool.end(); }
}

seed().catch(() => process.exit(1));
