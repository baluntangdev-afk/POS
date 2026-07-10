import { DataSource } from 'typeorm';
import { typeOrmConfig } from '../src/database/config/typeorm.config';
import { entities } from '../src/database/entities-index';

async function main() {
  const ds = new DataSource({ ...typeOrmConfig, entities, migrations: [] });
  await ds.initialize();

  const users = await ds.query(
    `select id, user_id, email, first_name, last_name, role, system_admin, status, pos_terminal_id from users order by id`,
  );
  console.log('--- USERS ---');
  console.log(users);

  const variants = await ds.query(`
    select pv.id, p.name as product_name, pv.name as variant_name, pv.price, pv.status,
           (select r.id from recipes r where r.product_variant_id = pv.id limit 1) as recipe_id
    from product_variants pv
    join products p on pv.product_id = p.id
    order by p.name, pv.name
  `);
  console.log('--- PRODUCT VARIANTS ---', variants.length);
  console.log(variants);

  const discounts = await ds.query(`select id, name, type, value, status from discounts`);
  console.log('--- DISCOUNTS ---');
  console.log(discounts);

  const posPaymentMethods = await ds.query(`select * from pos_terminal_payment_methods`);
  console.log('--- POS TERMINAL PAYMENT METHODS ---');
  console.log(posPaymentMethods);

  const posTerminals = await ds.query(`select * from pos_terminals`);
  console.log('--- POS TERMINALS ---');
  console.log(posTerminals);

  const todayOrders = await ds.query(`select count(*) from sales_orders where so_date::date = CURRENT_DATE`);
  console.log('--- TODAY SALES ORDERS COUNT ---', todayOrders);

  const allOrdersCount = await ds.query(`select count(*) from sales_orders`);
  console.log('--- ALL SALES ORDERS COUNT ---', allOrdersCount);

  const paymentMethodsUsed = await ds.query(`select distinct payment_method, payment_method_name from payments`);
  console.log('--- PAYMENT METHODS USED IN PAYMENTS ---');
  console.log(paymentMethodsUsed);

  await ds.destroy();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
