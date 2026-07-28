import { ApplyDiscountToItemMapper } from './apply-discount-to-item.mapper';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { User } from '../../users/entities/user.entity';
import { ItemDiscountAmounts } from '../sales-order.interface';

describe('ApplyDiscountToItemMapper.applyDiscountAmountsToItem', () => {
  const amounts: ItemDiscountAmounts = {
    discountedUnitPrice: '80.000000',
    subTotalAmount: '80.000000',
    totalAmount: '80.000000',
    vatAmount: '0.000000',
  };
  const causer = { id: 'user-1' } as User;

  it('persists beneficiary id number and name when provided', () => {
    const item = new SalesOrderItem();

    ApplyDiscountToItemMapper.applyDiscountAmountsToItem(item, 20, amounts, causer, {
      idNumber: 'SC-2024-00001',
      beneficiaryName: 'Juan Dela Cruz',
    });

    expect(item.discountBeneficiaryIdNumber).toBe('SC-2024-00001');
    expect(item.discountBeneficiaryName).toBe('Juan Dela Cruz');
  });

  it('leaves beneficiary fields null when not provided', () => {
    const item = new SalesOrderItem();

    ApplyDiscountToItemMapper.applyDiscountAmountsToItem(item, 10, amounts, causer);

    expect(item.discountBeneficiaryIdNumber).toBeNull();
    expect(item.discountBeneficiaryName).toBeNull();
  });
});
