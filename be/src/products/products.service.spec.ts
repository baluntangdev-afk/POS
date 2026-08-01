import { Test, TestingModule } from '@nestjs/testing';
import { ProductsService } from './products.service';
import { CreateProductService } from './services/create-product.service';
import { FindProductsService } from './services/find-products.service';
import { FindProductService } from './services/find-product.service';
import { FindProductVariantsService } from './services/find-product-variants.service';
import { UpdateProductService } from './services/update-product.service';
import { FindProductDetailsService } from './services/find-product-details.service';
import { ImportProductsCsvService } from './services/import-products-csv.service';

describe('ProductsService', () => {
  let service: ProductsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductsService,
        { provide: CreateProductService, useValue: {} },
        { provide: FindProductsService, useValue: {} },
        { provide: FindProductService, useValue: {} },
        { provide: FindProductVariantsService, useValue: {} },
        { provide: UpdateProductService, useValue: {} },
        { provide: FindProductDetailsService, useValue: {} },
        { provide: ImportProductsCsvService, useValue: {} },
      ],
    }).compile();

    service = module.get<ProductsService>(ProductsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
