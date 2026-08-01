import { ZReadingReportMapper, ZReadingRawInputs } from './z-reading-report.mapper';

function makeRaw(overrides: Partial<ZReadingRawInputs> = {}): ZReadingRawInputs {
  return {
    terminalName: 'POS-01',
    paymentRows: [{ name: 'Cash', amount: '19050.00' }],
    paymentLedgerRows: [
      {
        name: 'Cash',
        paymentDate: new Date('2026-07-15T10:00:00.000Z'),
        transactionReference: null,
        amount: '19050.00',
      },
    ],
    itemRows: [
      { name: 'Iced Latte', amount: '12000.00', quantity: '84' },
      { name: 'Burger', amount: '7050.00', quantity: '35' },
    ],
    discountRows: [{ name: 'Senior Citizen / PWD', amount: '665.00' }],
    salesTotals: {
      totalSales: '19050.00',
      totalDiscounts: '665.00',
      completedTransactions: '42',
      periodStart: new Date('2026-07-14T22:00:00.000Z'),
      periodEnd: new Date('2026-07-15T13:45:00.000Z'),
    },
    voided: { voidedTransactions: '1' },
    refunded: { refundedTransactions: '1' },
    tax: { vatSales: '17000.89', vatAmount: '2041.11' },
    vatExempt: { vatExemptSales: '2008.00' },
    quantity: { totalQuantitySold: '187' },
    cashierBreakdownRows: [
      {
        cashierId: 7,
        cashierName: 'Juan Dela Cruz',
        transactionCount: '20',
        salesTotal: '9050.00',
      },
      { cashierId: 9, cashierName: 'Maria Santos', transactionCount: '22', salesTotal: '10000.00' },
    ],
    beginningBalance: 152340,
    ...overrides,
  };
}

describe('ZReadingReportMapper', () => {
  it('defaults id/zCounter/closedByName/authorizedByName to null when not provided', () => {
    const dto = ZReadingReportMapper.toDto(makeRaw());
    expect(dto.id).toBeNull();
    expect(dto.zCounter).toBeNull();
    expect(dto.closedByName).toBeNull();
    expect(dto.authorizedByName).toBeNull();
  });

  it('carries id/zCounter/closedByName/authorizedByName through when provided (closed report)', () => {
    const dto = ZReadingReportMapper.toDto(
      makeRaw(),
      'report-id-456',
      14,
      'Juan Dela Cruz',
      'Maria Santos',
    );
    expect(dto.id).toBe('report-id-456');
    expect(dto.zCounter).toBe(14);
    expect(dto.closedByName).toBe('Juan Dela Cruz');
    expect(dto.authorizedByName).toBe('Maria Santos');
  });

  it('computes endingBalance as beginningBalance + totalSales', () => {
    const dto = ZReadingReportMapper.toDto(makeRaw());
    expect(dto.beginningBalance).toBe(152340);
    expect(dto.totalSales).toBe(19050);
    expect(dto.endingBalance).toBe(171390);
  });

  it('maps raw rows into the response DTO', () => {
    const dto = ZReadingReportMapper.toDto(makeRaw());

    expect(dto.terminalName).toBe('POS-01');
    expect(dto.periodStart).toBe('2026-07-14T22:00:00.000Z');
    expect(dto.periodEnd).toBe('2026-07-15T13:45:00.000Z');
    expect(dto.completedTransactions).toBe(42);
    expect(dto.voidedTransactions).toBe(1);
    expect(dto.totalTransactions).toBe(43);
    expect(dto.refundedTransactions).toBe(1);
    expect(dto.cashCollected).toBe(19050);
    expect(dto.vatSales).toBe(17000.89);
    expect(dto.vatAmount).toBe(2041.11);
    expect(dto.vatExemptSales).toBe(2008);
    expect(dto.totalQuantitySold).toBe(187);
  });

  it('maps sales by item from item rows', () => {
    const dto = ZReadingReportMapper.toDto(makeRaw());

    expect(dto.salesByItem).toEqual([
      { name: 'Iced Latte', amount: 12000, quantity: 84 },
      { name: 'Burger', amount: 7050, quantity: 35 },
    ]);
  });

  it('groups payment ledger rows by payment method', () => {
    const dto = ZReadingReportMapper.toDto(makeRaw());

    expect(dto.paymentLedgers).toEqual([
      {
        name: 'Cash',
        total: 19050,
        count: 1,
        entries: [
          { time: '2026-07-15T10:00:00.000Z', reference: null, amount: 19050 },
        ],
      },
    ]);
  });

  it('maps and sorts the per-cashier breakdown by sales total descending', () => {
    const dto = ZReadingReportMapper.toDto(makeRaw());

    expect(dto.salesByCashier).toEqual([
      { cashierId: 9, cashierName: 'Maria Santos', transactionCount: 22, salesTotal: 10000 },
      { cashierId: 7, cashierName: 'Juan Dela Cruz', transactionCount: 20, salesTotal: 9050 },
    ]);
  });

  it('defaults every value and nulls the period when queries return nothing', () => {
    const dto = ZReadingReportMapper.toDto(
      makeRaw({
        paymentRows: [],
        paymentLedgerRows: [],
        itemRows: [],
        discountRows: [],
        salesTotals: undefined,
        voided: undefined,
        refunded: undefined,
        tax: undefined,
        vatExempt: undefined,
        quantity: undefined,
        cashierBreakdownRows: [],
        beginningBalance: 0,
      }),
    );

    expect(dto.periodStart).toBeNull();
    expect(dto.periodEnd).toBeNull();
    expect(dto.totalSales).toBe(0);
    expect(dto.completedTransactions).toBe(0);
    expect(dto.voidedTransactions).toBe(0);
    expect(dto.refundedTransactions).toBe(0);
    expect(dto.endingBalance).toBe(0);
    expect(dto.salesByCashier).toEqual([]);
  });
});
