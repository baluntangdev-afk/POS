import { User } from '../../users/entities/user.entity';
import {
  CashierXReadingReportMapper,
  CashierXReadingRawInputs,
} from './cashier-x-reading-report.mapper';

function makeUser(): User {
  const user = new User();
  user.firstName = 'Juan';
  user.lastName = 'Dela Cruz';
  user.posTerminal = { legalName: 'POS-01' } as User['posTerminal'];
  return user;
}

function makeRaw(overrides: Partial<CashierXReadingRawInputs> = {}): CashierXReadingRawInputs {
  return {
    currentUser: makeUser(),
    paymentRows: [{ name: 'Cash', amount: '19050.00' }],
    paymentLedgerRows: [
      {
        name: 'Cash',
        paymentDate: new Date('2026-07-10T12:00:00.000Z'),
        transactionReference: null,
        amount: '405.00',
      },
    ],
    discountRows: [{ name: 'Senior Citizen / PWD', amount: '665.00' }],
    salesTotals: {
      totalSales: '19050.00',
      totalDiscounts: '665.00',
      completedTransactions: '42',
      averageSale: '453.57',
      highestSale: '1250.00',
      lowestSale: '85.00',
      periodStart: new Date('2026-07-10T20:15:00.000Z'),
      periodEnd: new Date('2026-07-11T03:02:00.000Z'),
    },
    voided: { voidedTransactions: '1' },
    refunded: { refundedTransactions: '1' },
    tax: { vatSales: '17000.89', vatAmount: '2041.11' },
    vatExempt: { vatExemptSales: '2008.00' },
    quantity: { totalQuantitySold: '187' },
    ...overrides,
  };
}

describe('CashierXReadingReportMapper', () => {
  it('defaults id to null when not provided', () => {
    const dto = CashierXReadingReportMapper.toDto(makeRaw());
    expect(dto.id).toBeNull();
  });

  it('carries the given id through when provided (closed/history report)', () => {
    const dto = CashierXReadingReportMapper.toDto(makeRaw(), 'report-id-456');
    expect(dto.id).toBe('report-id-456');
  });

  it('maps raw rows into the response DTO', () => {
    const dto = CashierXReadingReportMapper.toDto(makeRaw());

    expect(dto.cashierName).toBe('Juan Dela Cruz');
    expect(dto.terminalName).toBe('POS-01');
    expect(dto.periodStart).toBe('2026-07-10T20:15:00.000Z');
    expect(dto.periodEnd).toBe('2026-07-11T03:02:00.000Z');
    expect(dto.totalSales).toBe(19050);
    expect(dto.completedTransactions).toBe(42);
    expect(dto.voidedTransactions).toBe(1);
    expect(dto.totalTransactions).toBe(43);
    expect(dto.refundedTransactions).toBe(1);
    expect(dto.cashCollected).toBe(19050);
  });

  it('defaults every value and nulls the period when queries return nothing', () => {
    const dto = CashierXReadingReportMapper.toDto(
      makeRaw({
        paymentRows: [],
        paymentLedgerRows: [],
        discountRows: [],
        salesTotals: undefined,
        voided: undefined,
        refunded: undefined,
        tax: undefined,
        vatExempt: undefined,
        quantity: undefined,
      }),
    );

    expect(dto.periodStart).toBeNull();
    expect(dto.periodEnd).toBeNull();
    expect(dto.totalSales).toBe(0);
    expect(dto.completedTransactions).toBe(0);
    expect(dto.voidedTransactions).toBe(0);
    expect(dto.totalTransactions).toBe(0);
    expect(dto.cashCollected).toBe(0);
  });
});
