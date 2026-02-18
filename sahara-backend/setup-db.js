// Create Database Script
const { Client } = require('pg');

async function createDB() {
    const client = new Client({
        host: 'localhost',
        port: 5432,
        user: 'postgres',
        password: 'Shalaa0780@@',
        database: 'postgres', // connect to default db first
    });

    try {
        await client.connect();
        console.log('✅ متصل بـ PostgreSQL');

        // Check if database exists
        const check = await client.query("SELECT 1 FROM pg_database WHERE datname = 'sahara_fuel'");
        if (check.rows.length === 0) {
            await client.query('CREATE DATABASE sahara_fuel');
            console.log('✅ تم إنشاء قاعدة البيانات sahara_fuel');
        } else {
            console.log('ℹ️ قاعدة البيانات sahara_fuel موجودة مسبقاً');
        }
    } catch (error) {
        console.error('❌ خطأ:', error.message);
    } finally {
        await client.end();
    }
}

createDB();
