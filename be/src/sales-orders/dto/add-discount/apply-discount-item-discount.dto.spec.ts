import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { ApplyDiscountItemDiscountDto } from './apply-discount-item-discount.dto';

describe('ApplyDiscountItemDiscountDto', () => {
  it('accepts idNumber and beneficiaryName as optional strings', async () => {
    const dto = plainToInstance(ApplyDiscountItemDiscountDto, {
      id: 1,
      name: 'Senior Citizen / PWD',
      value: 20,
      idNumber: 'SC-2024-00001',
      beneficiaryName: 'Juan Dela Cruz',
    });

    const errors = await validate(dto);

    expect(errors).toHaveLength(0);
    expect(dto.idNumber).toBe('SC-2024-00001');
    expect(dto.beneficiaryName).toBe('Juan Dela Cruz');
  });

  it('is still valid when idNumber and beneficiaryName are omitted', async () => {
    const dto = plainToInstance(ApplyDiscountItemDiscountDto, {
      id: 2,
      name: 'Promo Code',
      value: 10,
    });

    const errors = await validate(dto);

    expect(errors).toHaveLength(0);
  });
});
