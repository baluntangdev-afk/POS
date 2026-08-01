import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { getDataSourceToken } from '@nestjs/typeorm';
import { ImportProductsCsvService } from './import-products-csv.service';
import { ProductsCsvSeeder } from '../../database/seeders/csv/products-csv.seeder';

const PRODUCTS_CSV = 'Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price\nCoffee,,Latte,,120,Regular,120\n';
const MODIFIERS_CSV = 'Modifier Group Name,Group Description,Selection Type,Is Required,Min Selection,Max Selection,Linked Product Group,Option Name,Option Price Add-On,Option Available\nMilk,,single,false,0,1,,Whole,0,true\n';
const INVALID_PRODUCTS_CSV = 'Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price\n,,Latte,,not-a-number,,\n';

describe('ImportProductsCsvService', () => {
  let service: ImportProductsCsvService;
  const fakeDataSource = {};

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ImportProductsCsvService,
        { provide: getDataSourceToken(), useValue: fakeDataSource },
      ],
    }).compile();

    service = module.get<ImportProductsCsvService>(ImportProductsCsvService);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should reject content with an unrecognized header', async () => {
    await expect(service.execute('foo,bar\n1,2\n', 'upsert')).rejects.toThrow(BadRequestException);
  });

  it('should reject a modifiers CSV (not supported from this endpoint)', async () => {
    await expect(service.execute(MODIFIERS_CSV, 'upsert')).rejects.toThrow(BadRequestException);
  });

  it('should reject rows that fail validation, listing row-level errors', async () => {
    await expect(service.execute(INVALID_PRODUCTS_CSV, 'upsert')).rejects.toMatchObject({
      response: {
        errors: expect.arrayContaining([expect.objectContaining({ row: 2, column: 'Category' })]),
      },
    });
  });

  it('should run the seeder in non-authoritative mode for "upsert"', async () => {
    const runSpy = jest
      .spyOn(ProductsCsvSeeder.prototype, 'run')
      .mockResolvedValue({
        categoriesInserted: 1,
        categoriesUpdated: 0,
        categoriesDeleted: 0,
        productsInserted: 1,
        productsUpdated: 0,
        productsDeleted: 0,
        variantsInserted: 1,
        variantsUpdated: 0,
        variantsDeleted: 0,
      });

    const summary = await service.execute(PRODUCTS_CSV, 'upsert');

    expect(runSpy).toHaveBeenCalledWith(fakeDataSource, expect.any(Array), {
      authoritative: false,
    });
    expect(summary.productsInserted).toBe(1);
  });

  it('should run the seeder in authoritative mode for "replace"', async () => {
    const runSpy = jest.spyOn(ProductsCsvSeeder.prototype, 'run').mockResolvedValue({
      categoriesInserted: 0,
      categoriesUpdated: 1,
      categoriesDeleted: 2,
      productsInserted: 0,
      productsUpdated: 1,
      productsDeleted: 3,
      variantsInserted: 0,
      variantsUpdated: 1,
      variantsDeleted: 4,
    });

    await service.execute(PRODUCTS_CSV, 'replace');

    expect(runSpy).toHaveBeenCalledWith(fakeDataSource, expect.any(Array), {
      authoritative: true,
    });
  });
});
