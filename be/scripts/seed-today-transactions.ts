import { DataSource } from 'typeorm';
import { uuidv7 } from 'uuidv7';
import { typeOrmConfig } from '../src/database/config/typeorm.config';
import { entities } from '../src/database/entities-index';

const TAX_RATE = 0.12;

const CASHIER_IDS = [1, 2, 3]; // admin, supervisor, cashier1 - all process sales on this terminal
const KIOSK_PREFIX = 'SO-001-2026-';
const MIN_ORDERS_PER_CASHIER = 30;
const MAX_ORDERS_PER_CASHIER = 36;

type Variant = { id: number; product_name: string; variant_name: string; price: string; recipe_id: number | null };
type Discount = { id: number; name: string; type: string; value: string };

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

  const discounts: Discount[] = await ds.query(`select id, name, type, value from discounts where status = 'Active'`);

  const [{ today }] = await ds.query(`select to_char(CURRENT_DATE, 'YYYY-MM-DD') as today`);

  console.log('Deleting existing transactions for today...');
  await ds.query(`
    update inventory_counts set sales_order_id = null
    where sales_order_id in (select id from sales_orders where to_char(so_date, 'YYYY-MM-DD') = $1)
  `, [today]);
  await ds.query(`
    delete from payments where sales_order_id in (select id from sales_orders where to_char(so_date, 'YYYY-MM-DD') = $1)
  `, [today]);
  await ds.query(`
    delete from so_items where so_id in (select id from sales_orders where to_char(so_date, 'YYYY-MM-DD') = $1)
  `, [today]);
  await ds.query(`
    delete from so_discounts where sales_order_id in (select id from sales_orders where to_char(so_date, 'YYYY-MM-DD') = $1)
  `, [today]);
  const deleted = await ds.query(
    `delete from sales_orders where to_char(so_date, 'YYYY-MM-DD') = $1 returning id`,
    [today],
  );
  console.log(`Deleted ${deleted.length} existing sales orders for today.`);

  const [{ maxseq }] = await ds.query(
    `select coalesce(max(cast(substring(so_number from length($1::text) + 1) as int)), 0) as maxseq
     from sales_orders where so_number like $1 || '%'`,
    [KIOSK_PREFIX],
  );
  let seq = Number(maxseq);

  // Build orders (unsequenced), then sort by literal time-of-day string so so_number increases with time.
  // soDate is a plain 'YYYY-MM-DD HH:MI:SS' literal string (never a JS Date) so it is stored
  // verbatim with no local/session timezone conversion in either direction.
  type PlannedOrder = {
    cashierId: number;
    soDate: string;
    soType: string;
  };
  const planned: PlannedOrder[] = [];
  const soTypes = ['Dine-In', 'Take-Out', 'Delivery'];
  const pad = (n: number) => String(n).padStart(2, '0');

  for (const cashierId of CASHIER_IDS) {
    const count = randInt(MIN_ORDERS_PER_CASHIER, MAX_ORDERS_PER_CASHIER);
    for (let i = 0; i < count; i++) {
      const timeOfDay = `${pad(randInt(7, 20))}:${pad(randInt(0, 59))}:${pad(randInt(0, 59))}`;
      const soDate = `${today} ${timeOfDay}`;
      planned.push({ cashierId, soDate, soType: pick(soTypes) });
    }
  }
  planned.sort((a, b) => a.soDate.localeCompare(b.soDate));

  console.log(`Creating ${planned.length} new transactions for ${CASHIER_IDS.length} cashiers...`);

  const perCashierCount: Record<number, number> = {};

  for (const order of planned) {
    seq += 1;
    const soNumber = `${KIOSK_PREFIX}${String(seq).padStart(4, '0')}`;
    const soId = uuidv7();
    const cashierId = order.cashierId;
    perCashierCount[cashierId] = (perCashierCount[cashierId] ?? 0) + 1;

    const itemCount = randInt(3, 4);
    const chosenVariants: Variant[] = [];
    for (let i = 0; i < itemCount; i++) chosenVariants.push(pick(menuVariants));

    // ~30% of orders get a discount, applied to one random line item.
    const applyDiscount = Math.random() < 0.3;
    const discount = applyDiscount ? pick(discounts) : null;
    const discountedItemIndex = discount ? randInt(0, chosenVariants.length - 1) : -1;

    let orderSubtotal = 0;
    let orderTax = 0;
    let orderDiscountAmount = 0;

    const itemRows: any[] = [];

    chosenVariants.forEach((variant, idx) => {
      const qty = randInt(1, 3);
      const unitPrice = Number(variant.price);
      const vatExclusiveAmount = round((qty * unitPrice) / (1 + TAX_RATE));

      let itemDiscountRate = 0;
      let itemDiscountedPrice: number | null = null;
      let itemSubtotal = vatExclusiveAmount;
      let vatAmount = round(itemSubtotal * TAX_RATE);

      if (discount && idx === discountedItemIndex) {
        itemDiscountRate = Number(discount.value);
        itemDiscountedPrice = round(vatExclusiveAmount * (itemDiscountRate / 100));
        itemSubtotal = round(vatExclusiveAmount - itemDiscountedPrice);
        const isVatExempt = discount.name === 'Senior Citizen / PWD';
        vatAmount = isVatExempt ? 0 : round(itemSubtotal * TAX_RATE);
        orderDiscountAmount = round(orderDiscountAmount + itemDiscountedPrice);
      }

      const itemTotalAmount = round(itemSubtotal + vatAmount);
      orderSubtotal = round(orderSubtotal + itemSubtotal);
      orderTax = round(orderTax + vatAmount);

      itemRows.push({
        id: uuidv7(),
        itemSequence: idx + 1,
        productVariantId: variant.id,
        recipeId: variant.recipe_id,
        description: `${variant.variant_name} ${variant.product_name}`,
        qty,
        unitPrice,
        itemDiscountRate,
        itemDiscountedPrice,
        vatExclusiveAmount,
        vatAmount,
        itemSubtotal,
        itemTotalAmount,
      });
    });

    const finalTotalAmount = round(orderSubtotal + orderTax);
    const discountRate = discount ? Number(discount.value) : 0;

    await ds.query(
      `insert into sales_orders (
        id, so_number, so_date, so_type, status, discount_rate, discount_amount, tax_rate, tax_amount,
        total_amount, final_total_amount, created_at, updated_at, created_by, updated_by
      ) values ($1,$2,$3,$4,'Confirmed',$5,$6,0,0,$7,$8,$3,$3,$9,$9)`,
      [
        soId,
        soNumber,
        order.soDate,
        order.soType,
        discountRate,
        orderDiscountAmount,
        orderSubtotal,
        finalTotalAmount,
        cashierId,
      ],
    );

    for (const item of itemRows) {
      await ds.query(
        `insert into so_items (
          id, so_id, item_sequence, product_variant_id, recipe_id, description, qty, unit_price,
          item_discount_rate, item_discounted_price, vat_exclusive_amount, vat_amount, item_subtotal,
          item_total_amount, item_paid_amount, status, created_at, updated_at, created_by, updated_by
        ) values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$14,'Completed',$15,$15,$16,$16)`,
        [
          item.id,
          soId,
          item.itemSequence,
          item.productVariantId,
          item.recipeId,
          item.description,
          item.qty,
          item.unitPrice,
          item.itemDiscountRate,
          item.itemDiscountedPrice,
          item.vatExclusiveAmount,
          item.vatAmount,
          item.itemSubtotal,
          item.itemTotalAmount,
          order.soDate,
          cashierId,
        ],
      );
    }

    if (discount) {
      await ds.query(
        `insert into so_discounts (id, sales_order_id, discount_id, applied_amount, created_at, updated_at, created_by, updated_by)
         values ($1,$2,$3,$4,$5,$5,$6,$6)`,
        [uuidv7(), soId, discount.id, orderDiscountAmount, order.soDate, cashierId],
      );
    }

    // Payment: weighted random method using the terminal's configured methods.
    const roll = Math.random();
    let paymentMethod: string;
    let paymentMethodName: string | null = null;
    let transactionReference: string | null = null;
    let amountPaid = finalTotalAmount;
    let change = 0;

    if (roll < 0.45) {
      paymentMethod = 'Cash';
      const tendered = Math.ceil(finalTotalAmount / 50) * 50 + pick([0, 0, 20, 50, 100]);
      amountPaid = tendered;
      change = round(tendered - finalTotalAmount);
    } else if (roll < 0.75) {
      paymentMethod = 'GCash';
      transactionReference = randomReference(13);
    } else if (roll < 0.88) {
      paymentMethod = 'Other';
      paymentMethodName = 'BPI';
      transactionReference = randomReference(12);
    } else {
      paymentMethod = 'Other';
      paymentMethodName = 'Metrobank';
      transactionReference = randomReference(12);
    }

    await ds.query(
      `insert into payments (
        id, sales_order_id, amount_paid, change, payment_method, payment_method_name, payment_date, transaction_reference
      ) values ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [uuidv7(), soId, amountPaid, change, paymentMethod, paymentMethodName, order.soDate, transactionReference],
    );
  }

  console.log('Done. Orders created per cashier:');
  for (const [cashierId, count] of Object.entries(perCashierCount)) {
    console.log(`  user_id ${cashierId}: ${count} transactions`);
  }
  console.log(`Total: ${planned.length}`);

  await ds.destroy();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
