import { User } from '../../users/entities/user.entity';
import { CashierDailyReportMapper, CashierDailyReportRawInputs } from './cashier-daily-report.mapper';

function makeUser(): User {
  const user = new User();
  user.firstName = 'Kayesha Mae';
  user.lastName = 'Cabigas';
  user.posTerminal = { legalName: 'T/M#0003' } as User['posTerminal'];
  return user;
}

function makeRaw(overrides: Partial<CashierDailyReportRawInputs> = {}): CashierDailyReportRawInputs {
  return {
    currentUser: makeUser(),
    salesTotals: { totalSales: '10839.00', completedTransactions: '73' },
    tax: { vatSales: '9677.69', vatAmount: '1161.31' },
    vatExempt: { vatExemptSales: null },
    quantity: { totalQuantitySold: '106' },
    productRows: [
      { productName: 'Add on: Pearl', quantity: '1', amount: '15.00' },
      { productName: 'BLENDED COFFEE - CARAMEL', quantity: '1', amount: '135.00' },
    ],
    cashSales: { totalCashSales: '8158.00', cashSalesCount: '56' },
    cashLedgerRows: [
      {
        name: 'Cash',
        paymentDate: new Date('2026-07-10T06:32:00.000Z'),
        transactionReference: null,
        amount: '405.00',
      },
    ],
    ...overrides,
  };
}

describe('CashierDailyReportMapper', () => {
  it('maps raw rows into the response DTO', () => {
    const dto = CashierDailyReportMapper.toDto(makeRaw());

    expect(dto.cashierName).toBe('Kayesha Mae Cabigas');
    expect(dto.terminalName).toBe('T/M#0003');
    expect(dto.grossSales).toBe(10839);
    expect(dto.vatableSales).toBe(9677.69);
    expect(dto.vatAmount).toBe(1161.31);
    expect(dto.vatExemptSales).toBe(0);
    expect(dto.zeroRatedSales).toBe(0);
    expect(dto.netOfTax).toBeCloseTo(10839 - 1161.31, 2);
    expect(dto.transactionCount).toBe(73);
    expect(dto.totalQuantity).toBe(106);
    expect(dto.totalCashSales).toBe(8158);
    expect(dto.cashSalesCount).toBe(56);
  });

  it('preserves product row order and converts quantity/amount to numbers', () => {
    const dto = CashierDailyReportMapper.toDto(makeRaw());

    expect(dto.salesByProduct).toEqual([
      { quantity: 1, productName: 'Add on: Pearl', amount: 15 },
      { quantity: 1, productName: 'BLENDED COFFEE - CARAMEL', amount: 135 },
    ]);
  });

  it('maps cash ledger rows with ISO timestamps', () => {
    const dto = CashierDailyReportMapper.toDto(makeRaw());

    expect(dto.cashLedger).toEqual([
      { time: '2026-07-10T06:32:00.000Z', reference: null, amount: 405 },
    ]);
  });

  it('defaults every value when queries return nothing', () => {
    const dto = CashierDailyReportMapper.toDto(
      makeRaw({
        salesTotals: undefined,
        tax: undefined,
        vatExempt: undefined,
        quantity: undefined,
        productRows: [],
        cashSales: undefined,
        cashLedgerRows: [],
      }),
    );

    expect(dto.grossSales).toBe(0);
    expect(dto.vatableSales).toBe(0);
    expect(dto.vatAmount).toBe(0);
    expect(dto.vatExemptSales).toBe(0);
    expect(dto.netOfTax).toBe(0);
    expect(dto.transactionCount).toBe(0);
    expect(dto.totalQuantity).toBe(0);
    expect(dto.totalCashSales).toBe(0);
    expect(dto.cashSalesCount).toBe(0);
    expect(dto.salesByProduct).toEqual([]);
    expect(dto.cashLedger).toEqual([]);
  });
});
