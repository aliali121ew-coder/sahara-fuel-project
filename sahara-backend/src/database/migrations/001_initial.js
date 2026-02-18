// ============================================================
// Database Migration - Initial Schema
// ============================================================
require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '..', '.env') });
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'sahara_fuel',
    user: process.env.DB_USER || 'sahara_admin',
    password: process.env.DB_PASSWORD || 'your_strong_password',
});

const MIGRATION_SQL = `
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(200) NOT NULL, code VARCHAR(50) UNIQUE,
  owner_email VARCHAR(200), plan VARCHAR(50) DEFAULT 'trial',
  is_active BOOLEAN DEFAULT true, settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription_plans (
  id VARCHAR(50) PRIMARY KEY, name VARCHAR(100) NOT NULL, name_en VARCHAR(100),
  price DECIMAL(12,2) DEFAULT 0, duration_days INTEGER DEFAULT 365,
  max_users INTEGER DEFAULT 5, max_stations INTEGER DEFAULT 2, max_tanks INTEGER DEFAULT 10,
  features JSONB DEFAULT '[]', is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  plan_id VARCHAR(50) NOT NULL REFERENCES subscription_plans(id),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','expired','cancelled','suspended')),
  start_date TIMESTAMPTZ DEFAULT NOW(), end_date TIMESTAMPTZ NOT NULL,
  amount_paid DECIMAL(12,2) DEFAULT 0, payment_method VARCHAR(50), notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant ON subscriptions(tenant_id);

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL, email VARCHAR(200) NOT NULL,
  password_hash VARCHAR(200) NOT NULL, phone VARCHAR(20) DEFAULT '',
  role VARCHAR(30) NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin','manager','operator','viewer','auditor')),
  is_active BOOLEAN DEFAULT true, permissions JSONB DEFAULT '{}',
  branch_id UUID, last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(email, tenant_id)
);
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL, code VARCHAR(20) DEFAULT '',
  address VARCHAR(300) DEFAULT '', phone VARCHAR(20) DEFAULT '',
  manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
  daily_target DECIMAL(12,2) DEFAULT 0, is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_branches_tenant ON branches(tenant_id);

DO $$ BEGIN
  ALTER TABLE users ADD CONSTRAINT fk_users_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS tanks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL, location VARCHAR(200) DEFAULT '',
  fuel_type VARCHAR(30) NOT NULL CHECK (fuel_type IN ('benzene','diesel','kerosene','gas')),
  capacity DECIMAL(12,2) NOT NULL, current_level DECIMAL(12,2) DEFAULT 0,
  min_level DECIMAL(12,2) DEFAULT 0, temperature DECIMAL(5,2) DEFAULT 25,
  max_temperature DECIMAL(5,2) DEFAULT 45,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','maintenance','inactive')),
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  last_fill TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tanks_tenant ON tanks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tanks_branch ON tanks(branch_id);

CREATE TABLE IF NOT EXISTS fuel_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('incoming','outgoing','transfer')),
  fuel_type VARCHAR(30) NOT NULL CHECK (fuel_type IN ('benzene','diesel','kerosene','gas')),
  quantity DECIMAL(12,2) NOT NULL, unit_price DECIMAL(12,2) DEFAULT 0,
  total_price DECIMAL(14,2) DEFAULT 0, supplier VARCHAR(200),
  tank_id UUID REFERENCES tanks(id) ON DELETE SET NULL,
  destination_tank_id UUID REFERENCES tanks(id) ON DELETE SET NULL,
  driver_name VARCHAR(100), truck_number VARCHAR(50),
  density DECIMAL(5,3), color_rating DECIMAL(3,1), notes TEXT,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','cancelled')),
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_fuel_tenant ON fuel_transactions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fuel_created ON fuel_transactions(created_at DESC);

CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL, description VARCHAR(200) DEFAULT '',
  permissions JSONB DEFAULT '{}', is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(50) NOT NULL, resource VARCHAR(50) NOT NULL,
  resource_id VARCHAR(100), details JSONB DEFAULT '{}',
  ip_address VARCHAR(45), created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_tenant ON audit_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL, message TEXT, 
  type VARCHAR(30) DEFAULT 'info' CHECK (type IN ('info','warning','error','success')),
  is_read BOOLEAN DEFAULT false, data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS incoming_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  supplier VARCHAR(200) NOT NULL, fuel_type VARCHAR(30) NOT NULL,
  quantity DECIMAL(12,2) NOT NULL, unit_price DECIMAL(12,2) DEFAULT 0,
  total_price DECIMAL(14,2) DEFAULT 0,
  tank_id UUID REFERENCES tanks(id) ON DELETE SET NULL, tank_name VARCHAR(100),
  driver_name VARCHAR(100), truck_number VARCHAR(50),
  density DECIMAL(5,3) DEFAULT 0.85, color_rating DECIMAL(3,1) DEFAULT 2.0,
  notes TEXT, created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS union_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('credit','debit')),
  amount DECIMAL(14,2) NOT NULL, source VARCHAR(200), notes TEXT,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
`;

async function migrate() {
    console.log('🔄 بدء إنشاء جداول قاعدة البيانات...');
    try {
        await pool.query(MIGRATION_SQL);
        console.log('✅ تم إنشاء جميع الجداول بنجاح (12 جدول)!');
    } catch (error) {
        console.error('❌ خطأ:', error.message);
        throw error;
    } finally { await pool.end(); }
}

migrate().catch(() => process.exit(1));
