import { DataSource } from 'typeorm';
import { uuidv7 } from 'uuidv7';
import { typeOrmConfig } from '../src/database/config/typeorm.config';
import { entities } from '../src/database/entities-index';

const TAX_RATE = 0.12;

const CASHIER_ID = 3; // cashier1
const KIOSK_PREFIX = 'SO-LATE-2026-';
const ORDERS_BEFORE_MIDNIGHT = 6;
const ORDERS_AFTER_MIDNIGHT = 6;

type Variant = { id: number; product_name: string; variant_name: string; price: string; recipe_id: number | null };

function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick<T>(arr: T[]): T {
  return arr[randInt(0, arr.length - 1)];
}

function randomReference(length: number): string {
  let ref = '';
  for (let i = 0; i < length; i++) ref += randInt(0, 9);
  return ref;
}

function round(n: number): number {
  return Math.round(n * 1e6) / 1e6;
}

async function main() {
  const ds = new DataSource({ ...typeOrmConfig, entities, migrations: [], logging: false });
  await ds.initialize();

  const variants: Variant[] = await ds.query(`
    select pv.id, p.name as product_name, pv.name as variant_name, pv.price, pv.status,
           (select r.id from recipes r where r.product_variant_id = pv.id limit 1) as recipe_id
    from product_variants pv
    join products p on pv.product_id = p.id
    where pv.status = 'Active' and p.status = 'Active'
  `);
  const menuVariants = variants.filter((v) => v.recipe_id !== null);

  const [{ today, yesterday }] = await ds.query(`
    select to_char(CURRENT_DATE, 'YYYY-MM-DD') as today,
           to_char(CURRENT_DATE - INTERVAL '1 day', 'YYYY-MM-DD') as yesterday
  `);

  console.log(`Deleting previously-seeded late-night-shift transactions (prefix ${KIOSK_PREFIX})...`);
  await ds.query(`
    update inventory_counts set sales_order_id = null
    where sales_order_id in (select id from sales_orders where so_number like $1 || '%')
  `, [KIOSK_PREFIX]);
  await ds.query(`delete from payments where sales_order_id in (select id from sales_orders where so_number like $1 || '%')`, [KIOSK_PREFIX]);
  await ds.query(`delete from so_items where so_id in (select id from sales_orders where so_number like $1 || '%')`, [KIOSK_PREFIX]);
  await ds.query(`delete from so_discounts where sales_order_id in (select id from sales_orders where so_number like $1 || '%')`, [KIOSK_PREFIX]);
  const deleted = await ds.query(`delete from sales_orders where so_number like $1 || '%' returning id`, [KIOSK_PREFIX]);
  console.log(`Deleted ${deleted.length} previously-seeded sales orders.`);

  type PlannedOrder = { soDate: string };
  const planned: PlannedOrder[] = [];
  const pad = (n: number) => String(n).padStart(2, '0');

  for (let i = 0; i < ORDERS_BEFORE_MIDNIGHT; i++) {
    const timeOfDay = `${pad(randInt(20, 23))}:${pad(randInt(0, 59))}:${pad(randInt(0, 59))}`;
    planned.push({ soDate: `${yesterday} ${timeOfDay}` });
  }
  for (let i = 0; i < ORDERS_AFTER_MIDNIGHT; i++) {
    const timeOfDay = `${pad(randInt(0, 3))}:${pad(randInt(0, 59))}:${pad(randInt(0, 59))}`;
    planned.push({ soDate: `${today} ${timeOfDay}` });
  }
  planned.sort((a, b) => a.soDate.localeCompare(b.soDate));

  console.log(`Creating ${planned.length} transactions for cashier ${CASHIER_ID} spanning ${yesterday} 8PM - ${today} 4AM...`);

  for (let seq = 0; seq < planned.length; seq++) {
    const order = planned[seq];
    const soNumber = `${KIOSK_PREFIX}${String(seq + 1).padStart(4, '0')}`;
    const soId = uuidv7();

    const itemCount = randInt(2, 3);
    const chosenVariants: Variant[] = [];
    for (let i = 0; i < itemCount; i++) chosenVariants.push(pick(menuVariants));

    let orderSubtotal = 0;
    let orderTax = 0;
    const itemRows: any[] = [];

    chosenVariants.forEach((variant, idx) => {
      const qty = randInt(1, 2);
      const unitPrice = Number(variant.price);
      const vatExclusiveAmount = round((qty * unitPrice) / (1 + TAX_RATE));
      const vatAmount = round(vatExclusiveAmount * TAX_RATE);
      const itemTotalAmount = round(vatExclusiveAmount + vatAmount);
      orderSubtotal = round(orderSubtotal + vatExclusiveAmount);
      orderTax = round(orderTax + vatAmount);

      itemRows.push({
        id: uuidv7(),
        itemSequence: idx + 1,
        productVariantId: variant.id,
        recipeId: variant.recipe_id,
        description: `${variant.variant_name} ${variant.product_name}`,
        qty,
        unitPrice,
        vatExclusiveAmount,
        vatAmount,
        itemSubtotal: vatExclusiveAmount,
        itemTotalAmount,
      });
    });

    const finalTotalAmount = round(orderSubtotal + orderTax);

    await ds.query(
      `insert into sales_orders (
        id, so_number, so_date, so_type, status, discount_rate, discount_amount, tax_rate, tax_amount,
        total_amount, final_total_amount, created_at, updated_at, created_by, updated_by
      ) values ($1,$2,$3,'Dine-In','Confirmed',0,0,0,0,$4,$5,$3,$3,$6,$6)`,
      [soId, soNumber, order.soDate, orderSubtotal, finalTotalAmount, CASHIER_ID],
    );

    for (const item of itemRows) {
      await ds.query(
        `insert into so_items (
          id, so_id, item_sequence, product_variant_id, recipe_id, description, qty, unit_price,
          item_discount_rate, item_discounted_price, vat_exclusive_amount, vat_amount, item_subtotal,
          item_total_amount, item_paid_amount, status, created_at, updated_at, created_by, updated_by
        ) values ($1,$2,$3,$4,$5,$6,$7,$8,0,null,$9,$10,$11,$12,$12,'Completed',$13,$13,$14,$14)`,
        [
          item.id,
          soId,
          item.itemSequence,
          item.productVariantId,
          item.recipeId,
          item.description,
          item.qty,
          item.unitPrice,
          item.vatExclusiveAmount,
          item.vatAmount,
          item.itemSubtotal,
          item.itemTotalAmount,
          order.soDate,
          CASHIER_ID,
        ],
      );
    }

    const tendered = Math.ceil(finalTotalAmount / 50) * 50 + pick([0, 20, 50]);
    const change = round(tendered - finalTotalAmount);

    await ds.query(
      `insert into payments (
        id, sales_order_id, amount_paid, change, payment_method, payment_method_name, payment_date, transaction_reference
      ) values ($1,$2,$3,$4,'Cash',null,$5,$6)`,
      [uuidv7(), soId, tendered, change, order.soDate, randomReference(13)],
    );
  }

  console.log(`Done. ${planned.length} transactions created for cashier_id ${CASHIER_ID}.`);
  console.log(`Earliest: ${planned[0].soDate}  Latest: ${planned[planned.length - 1].soDate}`);

  await ds.destroy();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
