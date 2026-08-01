# Product Management (Add / Edit / Delete) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let admin/supervisor users create, edit, and delete products (with variants and an optional image) from the kiosk's Catalog screen, backed by a corrected/guarded backend API.

**Architecture:** Backend: fix the `ProductVariant` write path (price/isDefault were never persisted), add a server-side `products.price = MIN(variant price)` sync, a distinct-variant-names lookup endpoint, and admin/supervisor guards on all product/variant mutation routes. Kiosk: extend the already-live `CatalogProduct`/`CatalogRepository`/`CatalogProductsNotifier` stack (not the dead parallel one) with create/update/delete for both products and variants, a new `SaveProductDialog`/`DeleteProductDialog` pair matching the existing category-management dialogs, and role-gated wiring into `CatalogGridScreen`. Finish by deleting the now-fully-dead parts of the old orphaned admin-CRUD stack — verified file-by-file via import grep, since some of it (`products_api.dart`, `product_groups_api.dart`, `ProductsRoute`) turned out to be shared with the live sales/ordering flow and must be trimmed, not deleted.

**Tech Stack:** NestJS + TypeORM + PostgreSQL (backend), Flutter + Riverpod (hooks_riverpod, incl. experimental `Mutation`) + Dio (kiosk).

**Testing approach:** Backend service logic gets real TDD (write failing Jest test against a mocked repository, then implement) — this matches the existing precedent in `be/src/catalog/catalog.service.spec.ts` and `be/src/products/product-variants.controller.spec.ts`. The kiosk side has no existing test infrastructure beyond the stock `widget_test.dart` (no repository/notifier/widget test precedent to extend), and `CLAUDE.md` explicitly directs verifying UI changes by running the real app rather than fabricating test scaffolding that doesn't exist yet — so kiosk model logic gets one small deterministic unit test (pure JSON parsing, worth locking down), and everything else (repository, dialogs, wiring) is implemented directly and verified with `dart analyze` + a manual pass in the running app at the end.

---

## Backend Tasks

### Task 1: Add `price` to `CreateProductVariantDto`

**Files:**
- Modify: `be/src/products/dto/create-product.variant.dto.ts`

The entity already has a `price` column (`product-variant.entity.ts:39`), but the create DTO never exposed it, so nothing has ever been able to set a variant's price via the API.

- [ ] **Step 1: Add the `price` field**

Replace the full file contents with:

```ts
import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, MaxLength, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for creating a new product variant.
 */
export class CreateProductVariantDto {
  @ApiProperty({ type: () => Number, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  productId: number;

  @ApiProperty({ type: () => String, example: 'Large' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiProperty({ type: () => Number, example: 150.0 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  price: number;

  @ApiProperty({ type: () => Boolean, example: false })
  @IsNotEmpty()
  @IsBoolean()
  isDefault: boolean;
}
```

`UpdateProductVariantDto` (`update-product-variant.dto.ts`) already extends `PartialType(CreateProductVariantDto)`, so it automatically gains an optional `price` — no change needed there.

- [ ] **Step 2: Confirm the project still compiles**

Run: `cd be && npx tsc --noEmit`
Expected: fails referencing `create-product-variant.service.ts` (it doesn't use `price` yet — expected, fixed in Task 3). If it fails for any other file, stop and investigate before continuing.

- [ ] **Step 3: Commit**

```bash
git add be/src/products/dto/create-product.variant.dto.ts
git commit -m "fix: expose price on CreateProductVariantDto"
```

---

### Task 2: `RecomputeProductPriceService`

**Files:**
- Create: `be/src/products/services/recompute-product-price.service.ts`
- Test: `be/src/products/services/recompute-product-price.service.spec.ts`

Keeps `products.price` (read directly by `CatalogService.getProducts()`'s raw SQL, which this feature does not touch) in sync as the minimum price across a product's active, non-deleted variants. Called after every variant create/update/delete (wired in Tasks 3–5).

- [ ] **Step 1: Write the failing test**

Create `be/src/products/services/recompute-product-price.service.spec.ts`:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { Product } from '../entities/product.entity';

describe('RecomputeProductPriceService', () => {
  let service: RecomputeProductPriceService;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getRawOne: jest.fn(),
  };

  const mockVariantsRepo = {
    createQueryBuilder: jest.fn(() => mockQueryBuilder),
  };

  const mockProductsRepo = {
    update: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.where.mockReturnThis();
    mockQueryBuilder.andWhere.mockReturnThis();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RecomputeProductPriceService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductsRepo },
      ],
    }).compile();

    service = module.get<RecomputeProductPriceService>(RecomputeProductPriceService);
  });

  it('sets the product price to the minimum active variant price', async () => {
    mockQueryBuilder.getRawOne.mockResolvedValue({ min: '45.50' });

    await service.execute(7);

    expect(mockVariantsRepo.createQueryBuilder).toHaveBeenCalledWith('pv');
    expect(mockProductsRepo.update).toHaveBeenCalledWith(7, { price: 45.5 });
  });

  it('sets the product price to 0 when the product has no active variants', async () => {
    mockQueryBuilder.getRawOne.mockResolvedValue({ min: null });

    await service.execute(7);

    expect(mockProductsRepo.update).toHaveBeenCalledWith(7, { price: 0 });
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/products/services/recompute-product-price.service.spec.ts`
Expected: FAIL — `Cannot find module './recompute-product-price.service'`

- [ ] **Step 3: Implement the service**

Create `be/src/products/services/recompute-product-price.service.ts`:

```ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../entities/product.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantStatus } from '../products.enum';

@Injectable()
export class RecomputeProductPriceService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
  ) {}

  async execute(productId: number): Promise<void> {
    const result = await this.productVariantsRepository
      .createQueryBuilder('pv')
      .select('MIN(pv.price)', 'min')
      .where('pv.product_id = :productId', { productId })
      .andWhere('pv.deleted_at IS NULL')
      .andWhere('pv.status = :status', { status: ProductVariantStatus.ACTIVE })
      .getRawOne<{ min: string | null }>();

    const price = result?.min != null ? Number(result.min) : 0;
    await this.productsRepository.update(productId, { price });
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/products/services/recompute-product-price.service.spec.ts`
Expected: PASS (2 tests)

- [ ] **Step 5: Register the service in `ProductsModule`**

Modify `be/src/products/products.module.ts`:

Add the import near the other service imports:

```ts
import { RecomputeProductPriceService } from './services/recompute-product-price.service';
```

Add `RecomputeProductPriceService` to the `providers` array (after `DeleteProductVariantService`):

```ts
    DeleteProductVariantService,
    RecomputeProductPriceService,
```

- [ ] **Step 6: Commit**

```bash
git add be/src/products/services/recompute-product-price.service.ts be/src/products/services/recompute-product-price.service.spec.ts be/src/products/products.module.ts
git commit -m "feat: add RecomputeProductPriceService to sync products.price from variants"
```

---

### Task 3: Persist price/isDefault on variant create, recompute product price

**Files:**
- Modify: `be/src/products/services/create-product-variant.service.ts`
- Test: `be/src/products/services/create-product-variant.service.spec.ts`

Today `CreateProductVariantService` only ever sets `name` — `isDefault` and the new `price` field are silently dropped even though the DTO/entity carry them.

- [ ] **Step 1: Write the failing test**

Create `be/src/products/services/create-product-variant.service.spec.ts`:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CreateProductVariantService } from './create-product-variant.service';
import { FindProductService } from './find-product.service';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { Product } from '../entities/product.entity';
import { User } from '../../users/entities/user.entity';

describe('CreateProductVariantService', () => {
  let service: CreateProductVariantService;

  const mockUser = { id: 1 } as User;
  const mockProduct = { id: 9 } as Product;

  const mockVariantsRepo = {
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockFindProductService = { execute: jest.fn() };
  const mockRecomputeProductPriceService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateProductVariantService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: FindProductService, useValue: mockFindProductService },
        { provide: RecomputeProductPriceService, useValue: mockRecomputeProductPriceService },
      ],
    }).compile();

    service = module.get<CreateProductVariantService>(CreateProductVariantService);
  });

  it('persists price and isDefault, then recomputes the product price', async () => {
    mockFindProductService.execute.mockResolvedValue(mockProduct);
    const createdEntity = {
      id: 3,
      name: 'Large',
      price: 150,
      isDefault: true,
      product: mockProduct,
    };
    mockVariantsRepo.create.mockReturnValue(createdEntity);
    mockVariantsRepo.save.mockResolvedValue(createdEntity);

    const result = await service.execute(
      { productId: 9, name: 'Large', price: 150, isDefault: true },
      mockUser,
    );

    expect(mockVariantsRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'Large', price: 150, isDefault: true, product: mockProduct }),
    );
    expect(mockRecomputeProductPriceService.execute).toHaveBeenCalledWith(9);
    expect(result).toEqual({ id: 3, productId: 9, name: 'Large', price: 150, isDefault: true });
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/products/services/create-product-variant.service.spec.ts`
Expected: FAIL — `mockVariantsRepo.create` not called with an object containing `price`/`isDefault` (current implementation only sets `name`), and `RecomputeProductPriceService` isn't injected yet (TS error).

- [ ] **Step 3: Implement**

Replace the full contents of `be/src/products/services/create-product-variant.service.ts`:

```ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateProductVariantDto } from '../dto/create-product.variant.dto';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantDto } from '../dto/product-variant.dto';
import { FindProductService } from './find-product.service';
import { ProductVariantMapper } from '../mapper/product-variant.mapper';
import { RecomputeProductPriceService } from './recompute-product-price.service';

@Injectable()
export class CreateProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    private readonly findProductService: FindProductService,
    private readonly recomputeProductPriceService: RecomputeProductPriceService,
  ) {}

  async execute(
    createProductVariantDto: CreateProductVariantDto,
    causer: User,
  ): Promise<ProductVariantDto> {
    const payload: Partial<ProductVariant> = {
      name: createProductVariantDto.name,
      price: createProductVariantDto.price,
      isDefault: createProductVariantDto.isDefault,
      createdBy: causer,
      updatedBy: causer,
    };

    const product = await this.findProductService.execute(createProductVariantDto.productId);
    payload.product = product;

    const entity = this.productVariantsRepository.create(payload);
    const result = await this.productVariantsRepository.save(entity);

    await this.recomputeProductPriceService.execute(product.id);

    return ProductVariantMapper.toProductVariantDto(result);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/products/services/create-product-variant.service.spec.ts`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add be/src/products/services/create-product-variant.service.ts be/src/products/services/create-product-variant.service.spec.ts
git commit -m "fix: persist variant price/isDefault on create and recompute product price"
```

---

### Task 4: Persist price on variant update, recompute product price

**Files:**
- Modify: `be/src/products/services/update-product-variant.service.ts`
- Test: `be/src/products/services/update-product-variant.service.spec.ts`

`UpdateProductVariantService` currently persists `name`/`isDefault` but not `price`, and has no way to know which product to recompute — it needs to fetch the variant (with its `product` relation) first, both to know the product id and to 404 correctly on a bad id (matching the `NotFoundException` pattern already used in `find-product-variant.service.ts`).

- [ ] **Step 1: Write the failing test**

Create `be/src/products/services/update-product-variant.service.spec.ts`:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { UpdateProductVariantService } from './update-product-variant.service';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { User } from '../../users/entities/user.entity';

describe('UpdateProductVariantService', () => {
  let service: UpdateProductVariantService;

  const mockUser = { id: 1 } as User;

  const mockVariantsRepo = {
    findOne: jest.fn(),
    update: jest.fn(),
  };

  const mockRecomputeProductPriceService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateProductVariantService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: RecomputeProductPriceService, useValue: mockRecomputeProductPriceService },
      ],
    }).compile();

    service = module.get<UpdateProductVariantService>(UpdateProductVariantService);
  });

  it('throws NotFoundException when the variant does not exist', async () => {
    mockVariantsRepo.findOne.mockResolvedValue(null);

    await expect(
      service.execute(99, { name: 'Large', price: 150, isDefault: true }, mockUser),
    ).rejects.toThrow(NotFoundException);
  });

  it('persists the new price and recomputes the product price', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);

    await service.execute(3, { name: 'Large', price: 175, isDefault: true }, mockUser);

    expect(mockVariantsRepo.update).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ name: 'Large', price: 175, isDefault: true }),
    );
    expect(mockRecomputeProductPriceService.execute).toHaveBeenCalledWith(9);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/products/services/update-product-variant.service.spec.ts`
Expected: FAIL — no `NotFoundException` thrown (current code calls `.update()` unconditionally with no existence check), and `price` isn't in the update payload.

- [ ] **Step 3: Implement**

Replace the full contents of `be/src/products/services/update-product-variant.service.ts`:

```ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateProductVariantDto } from '../dto/update-product-variant.dto';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { EntityHelper } from '../../utils/entity.helper';
import { RecomputeProductPriceService } from './recompute-product-price.service';

@Injectable()
export class UpdateProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    private readonly recomputeProductPriceService: RecomputeProductPriceService,
  ) {}

  async execute(
    id: number,
    updateProductVariantDto: UpdateProductVariantDto,
    causer: User,
  ): Promise<void> {
    const existing = await this.productVariantsRepository.findOne({
      where: { id },
      relations: { product: true },
    });

    if (!existing) {
      throw new NotFoundException('Product variant not found');
    }

    const payload: Partial<ProductVariant> = {
      name: updateProductVariantDto.name,
      price: updateProductVariantDto.price,
      isDefault: updateProductVariantDto.isDefault,
      updatedBy: causer,
    };

    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.recomputeProductPriceService.execute(existing.product.id);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/products/services/update-product-variant.service.spec.ts`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add be/src/products/services/update-product-variant.service.ts be/src/products/services/update-product-variant.service.spec.ts
git commit -m "fix: persist variant price on update, 404 on missing variant, recompute product price"
```

---

### Task 5: Recompute product price on variant delete

**Files:**
- Modify: `be/src/products/services/delete-product-variant.service.ts`
- Test: `be/src/products/services/delete-product-variant.service.spec.ts`

- [ ] **Step 1: Write the failing test**

Create `be/src/products/services/delete-product-variant.service.spec.ts`:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { DeleteProductVariantService } from './delete-product-variant.service';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { User } from '../../users/entities/user.entity';

describe('DeleteProductVariantService', () => {
  let service: DeleteProductVariantService;

  const mockUser = { id: 1 } as User;

  const mockVariantsRepo = {
    findOne: jest.fn(),
    update: jest.fn(),
    softDelete: jest.fn(),
  };

  const mockRecomputeProductPriceService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteProductVariantService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: RecomputeProductPriceService, useValue: mockRecomputeProductPriceService },
      ],
    }).compile();

    service = module.get<DeleteProductVariantService>(DeleteProductVariantService);
  });

  it('throws NotFoundException when the variant does not exist', async () => {
    mockVariantsRepo.findOne.mockResolvedValue(null);

    await expect(service.execute(99, mockUser)).rejects.toThrow(NotFoundException);
  });

  it('soft deletes the variant and recomputes the product price', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);
    mockVariantsRepo.softDelete.mockResolvedValue(undefined);

    await service.execute(3, mockUser);

    expect(mockVariantsRepo.softDelete).toHaveBeenCalledWith(3);
    expect(mockRecomputeProductPriceService.execute).toHaveBeenCalledWith(9);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/products/services/delete-product-variant.service.spec.ts`
Expected: FAIL — `RecomputeProductPriceService` not injected (TS error) and no existence check yet.

- [ ] **Step 3: Implement**

Replace the full contents of `be/src/products/services/delete-product-variant.service.ts`:

```ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { EntityHelper } from '../../utils/entity.helper';
import { RecomputeProductPriceService } from './recompute-product-price.service';

@Injectable()
export class DeleteProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    private readonly recomputeProductPriceService: RecomputeProductPriceService,
  ) {}

  async execute(id: number, causer: User): Promise<void> {
    const existing = await this.productVariantsRepository.findOne({
      where: { id },
      relations: { product: true },
    });

    if (!existing) {
      throw new NotFoundException('Product variant not found');
    }

    const payload: Partial<ProductVariant> = { deletedBy: causer };
    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.productVariantsRepository.softDelete(id);
    await this.recomputeProductPriceService.execute(existing.product.id);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/products/services/delete-product-variant.service.spec.ts`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add be/src/products/services/delete-product-variant.service.ts be/src/products/services/delete-product-variant.service.spec.ts
git commit -m "fix: recompute product price on variant delete"
```

---

### Task 6: `FindDistinctVariantNamesService` + `GET /product-variants/names`

**Files:**
- Create: `be/src/products/services/find-distinct-variant-names.service.ts`
- Test: `be/src/products/services/find-distinct-variant-names.service.spec.ts`
- Modify: `be/src/products/product-variants.service.ts`
- Modify: `be/src/products/product-variants.controller.ts`
- Modify: `be/src/products/products.module.ts`

Backs the kiosk's variant-name autocomplete with names already used anywhere in the system.

- [ ] **Step 1: Write the failing test**

Create `be/src/products/services/find-distinct-variant-names.service.spec.ts`:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { FindDistinctVariantNamesService } from './find-distinct-variant-names.service';
import { ProductVariant } from '../entities/product-variant.entity';

describe('FindDistinctVariantNamesService', () => {
  let service: FindDistinctVariantNamesService;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    getRawMany: jest.fn(),
  };

  const mockVariantsRepo = {
    createQueryBuilder: jest.fn(() => mockQueryBuilder),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.where.mockReturnThis();
    mockQueryBuilder.orderBy.mockReturnThis();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FindDistinctVariantNamesService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
      ],
    }).compile();

    service = module.get<FindDistinctVariantNamesService>(FindDistinctVariantNamesService);
  });

  it('returns distinct variant names in ascending order', async () => {
    mockQueryBuilder.getRawMany.mockResolvedValue([{ name: 'Regular' }, { name: 'Venti' }]);

    const result = await service.execute();

    expect(result).toEqual(['Regular', 'Venti']);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/products/services/find-distinct-variant-names.service.spec.ts`
Expected: FAIL — `Cannot find module './find-distinct-variant-names.service'`

- [ ] **Step 3: Implement**

Create `be/src/products/services/find-distinct-variant-names.service.ts`:

```ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductVariant } from '../entities/product-variant.entity';

@Injectable()
export class FindDistinctVariantNamesService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(): Promise<string[]> {
    const rows = await this.productVariantsRepository
      .createQueryBuilder('pv')
      .select('DISTINCT pv.name', 'name')
      .where('pv.deleted_at IS NULL')
      .orderBy('pv.name', 'ASC')
      .getRawMany<{ name: string }>();

    return rows.map((row) => row.name);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/products/services/find-distinct-variant-names.service.spec.ts`
Expected: PASS (1 test)

- [ ] **Step 5: Wire into `ProductVariantsService`**

Modify `be/src/products/product-variants.service.ts` — replace the full contents:

```ts
import { Injectable } from '@nestjs/common';
import { User } from '../users/entities/user.entity';
import { ProductVariantDto } from './dto/product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';
import { CreateProductVariantDto } from './dto/create-product.variant.dto';
import { FindProductVariantsByProductIdService } from './services/find-product-variants-by-product-id.service';
import { CreateProductVariantService } from './services/create-product-variant.service';
import { FindProductVariantService } from './services/find-product-variant.service';
import { DeleteProductVariantService } from './services/delete-product-variant.service';
import { UpdateProductVariantService } from './services/update-product-variant.service';
import { FindDistinctVariantNamesService } from './services/find-distinct-variant-names.service';

@Injectable()
export class ProductVariantsService {
  constructor(
    private readonly createProductVariantService: CreateProductVariantService,
    private readonly findProductVariantsByProductIdService: FindProductVariantsByProductIdService,
    private readonly findProductVariantService: FindProductVariantService,
    private readonly updateProductVariantService: UpdateProductVariantService,
    private readonly deleteProductVariantService: DeleteProductVariantService,
    private readonly findDistinctVariantNamesService: FindDistinctVariantNamesService,
  ) {}

  async create(
    createProductVariantDto: CreateProductVariantDto,
    causer: User,
  ): Promise<ProductVariantDto> {
    return this.createProductVariantService.execute(createProductVariantDto, causer);
  }

  async findByProductId(productId: number): Promise<ProductVariantDto[]> {
    return this.findProductVariantsByProductIdService.execute(productId);
  }

  async findOne(id: number): Promise<ProductVariantDto> {
    return this.findProductVariantService.execute(id);
  }

  async findDistinctNames(): Promise<string[]> {
    return this.findDistinctVariantNamesService.execute();
  }

  async update(
    id: number,
    updateProductVariantDto: UpdateProductVariantDto,
    causer: User,
  ): Promise<ProductVariantDto> {
    await this.updateProductVariantService.execute(id, updateProductVariantDto, causer);
    return this.findProductVariantService.execute(id);
  }

  async remove(id: number, causer: User) {
    await this.findProductVariantService.execute(id);
    await this.deleteProductVariantService.execute(id, causer);
    return { message: 'Product variant deleted successfully' };
  }
}
```

- [ ] **Step 6: Add the controller route**

Modify `be/src/products/product-variants.controller.ts`. Add the import:

```ts
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
```

Add `UseGuards` to the existing `@nestjs/common` import (it currently imports `Controller, Get, Post, Body, Patch, Param, Delete`):

```ts
import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
```

Insert a new `GET /names` route right after `create()` and before `findByProductId()` (must come before the `:id`/`:productId` routes so it isn't swallowed as a path parameter):

```ts
  @Get('names')
  @ApiOperation({ summary: 'Get all distinct variant names used across products' })
  @ApiOkResponse({
    description: 'Distinct variant names, alphabetically sorted.',
    type: [String],
  })
  findDistinctNames() {
    return this.productVariantsService.findDistinctNames();
  }
```

- [ ] **Step 7: Register the new service**

Modify `be/src/products/products.module.ts`. Add the import:

```ts
import { FindDistinctVariantNamesService } from './services/find-distinct-variant-names.service';
```

Add to the `providers` array (after `RecomputeProductPriceService`, added in Task 2):

```ts
    RecomputeProductPriceService,
    FindDistinctVariantNamesService,
```

- [ ] **Step 8: Run the full product-variants test suite**

Run: `cd be && npx jest src/products/product-variants`
Expected: PASS — including the existing `product-variants.controller.spec.ts`.

- [ ] **Step 9: Commit**

```bash
git add be/src/products/services/find-distinct-variant-names.service.ts be/src/products/services/find-distinct-variant-names.service.spec.ts be/src/products/product-variants.service.ts be/src/products/product-variants.controller.ts be/src/products/products.module.ts
git commit -m "feat: add GET /product-variants/names for autocomplete suggestions"
```

---

### Task 7: Guard product and variant mutation routes

**Files:**
- Modify: `be/src/products/products.controller.ts`
- Modify: `be/src/products/product-variants.controller.ts`

Mirrors `CatalogAdminController`'s pattern — `create`/`update`/`remove` require admin or supervisor; reads stay open to any authenticated user (existing ordering/catalog flows depend on unauthenticated-by-JWT reads).

- [ ] **Step 1: Guard `ProductsController`**

Modify `be/src/products/products.controller.ts`. Add imports:

```ts
import { UseGuards } from '@nestjs/common';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
```

(Add `UseGuards` to the existing `@nestjs/common` import line rather than a separate one — the file currently imports `Controller, Get, Post, Body, Patch, Param, Delete, Query, UseInterceptors, UploadedFile` from `@nestjs/common`; append `UseGuards` to that list.)

Add `@UseGuards(AdminOrSupervisorGuard)` directly above each of the three mutating handlers' existing decorators:

```ts
  @Post()
  @UseGuards(AdminOrSupervisorGuard)
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Create a new product' })
  ...
  create(
```

```ts
  @Patch(':id')
  @UseGuards(AdminOrSupervisorGuard)
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Update a product by ID' })
  ...
  update(
```

```ts
  @Delete(':id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Remove a product by ID' })
  ...
  remove(
```

`findAll`/`findOne` are left unguarded (JWT only).

- [ ] **Step 2: Guard `ProductVariantsController`**

Modify `be/src/products/product-variants.controller.ts` (the `AdminOrSupervisorGuard` import and `UseGuards` import were already added in Task 6, Step 6). Add `@UseGuards(AdminOrSupervisorGuard)` above `create`, `update`, and `remove`:

```ts
  @Post()
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Create a new product variant' })
  ...
  create(
```

```ts
  @Patch(':id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Update a product variant by ID' })
  ...
  update(
```

```ts
  @Delete(':id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Remove a product variant by ID' })
  ...
  remove(
```

`findDistinctNames`, `findByProductId`, `findOne` are left unguarded.

- [ ] **Step 3: Run the products test suite**

Run: `cd be && npx jest src/products`
Expected: PASS — `products.controller.spec.ts` only checks `controller` is defined via direct DI, unaffected by route-level guard metadata.

- [ ] **Step 4: Commit**

```bash
git add be/src/products/products.controller.ts be/src/products/product-variants.controller.ts
git commit -m "feat: require admin/supervisor to create, update, or delete products and variants"
```

---

### Task 8: Full backend verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full backend test suite**

Run: `cd be && npm run test`
Expected: all suites PASS, including the new/modified ones from Tasks 2–6.

- [ ] **Step 2: Lint**

Run: `cd be && npm run lint`
Expected: no errors.

- [ ] **Step 3: Build**

Run: `cd be && npm run build`
Expected: succeeds with no TypeScript errors.

No commit — this task only verifies work already committed in Tasks 1–7.

---

## Kiosk Tasks

### Task 9: `CatalogProductVariant` model + `CatalogProduct` draft/copyWith

**Files:**
- Modify: `kiosk/lib/features/catalog/data/models/product.dart`
- Test: `kiosk/test/features/catalog/data/models/product_test.dart`

`CatalogProduct` currently has neither `draft()` nor `copyWith()` (needed to build a working form draft, same as `CatalogCategory` already has). Two backend response shapes need to feed the same `CatalogProductVariant.fromJson`: `ProductVariantDto` (`{id, name, price, isDefault}`, from `POST/PATCH /product-variants`) and `ProductVariantDetailsDto` (`{id, name, displayPrice, isDefault}`, from `GET /products/:id`) — the factory checks for either key.

- [ ] **Step 1: Write the failing test**

Create `kiosk/test/features/catalog/data/models/product_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/catalog/data/models/product.dart';

void main() {
  group('CatalogProductVariant.fromJson', () {
    test('parses the ProductVariantDto shape (raw numeric price)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 3,
        'productId': 9,
        'name': 'Large',
        'price': 150.0,
        'isDefault': true,
      });

      expect(variant.id, '3');
      expect(variant.name, 'Large');
      expect(variant.price, 150.0);
      expect(variant.isDefault, true);
    });

    test('parses the ProductVariantDetailsDto shape (displayPrice string)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 5,
        'name': 'Venti',
        'displayPrice': '175.00',
        'isDefault': false,
      });

      expect(variant.id, '5');
      expect(variant.name, 'Venti');
      expect(variant.price, 175.0);
      expect(variant.isDefault, false);
    });
  });

  group('CatalogProductVariant.copyWith', () {
    test('overrides only the given fields', () {
      const original = CatalogProductVariant(id: '1', name: 'Regular', price: 100, isDefault: false);

      final updated = original.copyWith(price: 120, isDefault: true);

      expect(updated.id, '1');
      expect(updated.name, 'Regular');
      expect(updated.price, 120);
      expect(updated.isDefault, true);
    });
  });

  group('CatalogProduct.draft', () {
    test('produces an empty, unsaved product with no variants', () {
      final draft = CatalogProduct.draft();

      expect(draft.id, '');
      expect(draft.variants, isEmpty);
      expect(draft.category, isNull);
    });
  });

  group('CatalogProduct.copyWith', () {
    test('overrides only the given fields and preserves the rest', () {
      final original = CatalogProduct.draft().copyWith(
        name: 'Latte',
        category: const CatalogCategoryRef(id: '2', name: 'Beverages'),
      );

      final updated = original.copyWith(name: 'Cappuccino');

      expect(updated.name, 'Cappuccino');
      expect(updated.category?.id, '2');
      expect(updated.price, original.price);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd kiosk && fvm flutter test test/features/catalog/data/models/product_test.dart`
Expected: FAIL to compile — `CatalogProductVariant` doesn't exist yet, `CatalogProduct.draft`/`copyWith` don't exist yet.

- [ ] **Step 3: Implement**

Replace the full contents of `kiosk/lib/features/catalog/data/models/product.dart`:

```dart
import 'modifier_group.dart';

class CatalogCategoryRef {
  const CatalogCategoryRef({required this.id, required this.name});

  final String id;
  final String name;

  factory CatalogCategoryRef.fromJson(Map<String, dynamic> json) {
    return CatalogCategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class CatalogProductVariant {
  const CatalogProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
  });

  final String id;
  final String name;
  final double price;
  final bool isDefault;

  factory CatalogProductVariant.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['displayPrice'];
    return CatalogProductVariant(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: double.parse(rawPrice.toString()),
      isDefault: json['isDefault'] as bool,
    );
  }

  CatalogProductVariant copyWith({
    String? id,
    String? name,
    double? price,
    bool? isDefault,
  }) {
    return CatalogProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.sortOrder,
    this.category,
    required this.modifierGroups,
    this.variants = const [],
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int sortOrder;
  final CatalogCategoryRef? category;
  final List<CatalogModifierGroup> modifierGroups;
  final List<CatalogProductVariant> variants;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    return CatalogProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool,
      sortOrder: json['sort_order'] as int,
      category: categoryJson != null
          ? CatalogCategoryRef.fromJson(categoryJson as Map<String, dynamic>)
          : null,
      modifierGroups: (json['modifier_groups'] as List<dynamic>)
          .map((mg) => CatalogModifierGroup.fromJson(mg as Map<String, dynamic>))
          .toList(),
    );
  }

  factory CatalogProduct.draft() {
    return const CatalogProduct(
      id: '',
      name: '',
      description: null,
      price: 0,
      imageUrl: null,
      isAvailable: true,
      sortOrder: 0,
      category: null,
      modifierGroups: [],
      variants: [],
    );
  }

  CatalogProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    int? sortOrder,
    CatalogCategoryRef? category,
    List<CatalogModifierGroup>? modifierGroups,
    List<CatalogProductVariant>? variants,
  }) {
    return CatalogProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      category: category ?? this.category,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      variants: variants ?? this.variants,
    );
  }
}
```

Note: `CatalogProduct.fromJson` (used for the grid-list endpoint, which never returns a `variants` key) intentionally does not attempt to parse `variants` — it stays `const []` via the constructor default. The edit dialog populates variants separately via `CatalogRepository.fetchProductVariants` (Task 11), which returns `List<CatalogProductVariant>` directly rather than going through `CatalogProduct.fromJson`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd kiosk && fvm flutter test test/features/catalog/data/models/product_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/catalog/data/models/product.dart kiosk/test/features/catalog/data/models/product_test.dart
git commit -m "feat: add CatalogProductVariant model and CatalogProduct draft/copyWith"
```

---

### Task 10: `CatalogRepository` — product CRUD + variant CRUD + variant names

**Files:**
- Modify: `kiosk/lib/features/catalog/data/catalog_repository.dart`

No existing test infrastructure covers `CatalogRepository` (its existing category methods have no tests either) — implemented directly, verified via `dart analyze` in Task 16 and manual exercise in Task 17.

- [ ] **Step 1: Add imports**

Modify `kiosk/lib/features/catalog/data/catalog_repository.dart`. Replace the import block at the top of the file:

```dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/api_clients.dart';
import '../../../utils/file_sniffer.dart';
import 'models/category.dart';
import 'models/modifier_group.dart';
import 'models/product.dart';
```

- [ ] **Step 2: Add the new methods**

Insert the following methods into the `CatalogRepository` class, just before the closing `}` (after `fetchModifierGroups`):

```dart
  Future<String> createProduct({
    required String name,
    required String categoryId,
    Uint8List? imageBytes,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'groupId': categoryId,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${imageBytes.fileExtension}',
          contentType: DioMediaType.parse(imageBytes.mimeType),
        ),
    });
    final response = await _secureClient.post<dynamic>('/api/v1/products', data: formData);
    final data = response.data as Map<String, dynamic>;
    return data['id'].toString();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String categoryId,
    Uint8List? imageBytes,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'groupId': categoryId,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${imageBytes.fileExtension}',
          contentType: DioMediaType.parse(imageBytes.mimeType),
        ),
    });
    await _secureClient.patch<dynamic>('/api/v1/products/$id', data: formData);
  }

  Future<void> deleteProduct(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/products/$id');
  }

  Future<List<CatalogProductVariant>> fetchProductVariants(String productId) async {
    final response = await _secureClient.get<dynamic>('/api/v1/products/$productId');
    final data = response.data as Map<String, dynamic>;
    final variantsJson = data['variants'] as List<dynamic>? ?? [];
    return variantsJson
        .map((v) => CatalogProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<CatalogProductVariant> createVariant({
    required String productId,
    required String name,
    required double price,
    required bool isDefault,
  }) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/product-variants',
      data: {
        'productId': int.parse(productId),
        'name': name,
        'price': price,
        'isDefault': isDefault,
      },
    );
    return CatalogProductVariant.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateVariant({
    required String id,
    required String name,
    required double price,
    required bool isDefault,
  }) async {
    await _secureClient.patch<dynamic>(
      '/api/v1/product-variants/$id',
      data: {'name': name, 'price': price, 'isDefault': isDefault},
    );
  }

  Future<void> deleteVariant(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/product-variants/$id');
  }

  Future<List<String>> fetchVariantNames() async {
    final response = await _secureClient.get<dynamic>('/api/v1/product-variants/names');
    return (response.data as List<dynamic>).map((e) => e.toString()).toList();
  }
```

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/data/catalog_repository.dart
git commit -m "feat: add product/variant CRUD methods to CatalogRepository"
```

---

### Task 11: `CatalogProductsNotifier` — save/delete + variant-names provider

**Files:**
- Modify: `kiosk/lib/features/catalog/state/catalog_products_notifier.dart`

- [ ] **Step 1: Replace the file contents**

Replace the full contents of `kiosk/lib/features/catalog/state/catalog_products_notifier.dart`:

```dart
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/product.dart';

final catalogProductsProvider =
    AsyncNotifierProvider<CatalogProductsNotifier, CatalogProductsData>(
  CatalogProductsNotifier.new,
  name: 'catalogProductsProvider',
);

final catalogVariantNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchVariantNames();
});

class CatalogProductsData {
  const CatalogProductsData({
    required this.products,
    this.categoryId,
    this.search,
  });

  final List<CatalogProduct> products;
  final String? categoryId;
  final String? search;
}

class CatalogProductsNotifier extends AsyncNotifier<CatalogProductsData> {
  static final saveAction = Mutation<CatalogProduct>();
  static final deleteAction = Mutation<bool>();

  @override
  Future<CatalogProductsData> build() async {
    final products = await ref.watch(catalogRepositoryProvider).fetchProducts();
    return CatalogProductsData(products: products);
  }

  Future<void> getResults({String? categoryId, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final products = await ref.read(catalogRepositoryProvider).fetchProducts(
            categoryId: categoryId,
            search: search,
          );
      return CatalogProductsData(
        products: products,
        categoryId: categoryId,
        search: search,
      );
    });
  }

  Future<CatalogProduct> save(
    CatalogProduct draft,
    List<CatalogProductVariant> variants, {
    Uint8List? imageBytes,
  }) async {
    final repo = ref.read(catalogRepositoryProvider);
    final categoryId = draft.category!.id;

    final String productId;
    if (draft.id.isEmpty) {
      productId = await repo.createProduct(
        name: draft.name,
        categoryId: categoryId,
        imageBytes: imageBytes,
      );
    } else {
      productId = draft.id;
      await repo.updateProduct(
        id: productId,
        name: draft.name,
        categoryId: categoryId,
        imageBytes: imageBytes,
      );
    }

    final existingIds = draft.id.isEmpty
        ? const <String>{}
        : (await repo.fetchProductVariants(productId)).map((v) => v.id).toSet();
    final incomingIds = variants.where((v) => v.id.isNotEmpty).map((v) => v.id).toSet();

    for (final variant in variants) {
      if (variant.id.isEmpty) {
        await repo.createVariant(
          productId: productId,
          name: variant.name,
          price: variant.price,
          isDefault: variant.isDefault,
        );
      } else {
        await repo.updateVariant(
          id: variant.id,
          name: variant.name,
          price: variant.price,
          isDefault: variant.isDefault,
        );
      }
    }

    for (final removedId in existingIds.difference(incomingIds)) {
      await repo.deleteVariant(removedId);
    }

    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);

    return draft.copyWith(id: productId);
  }

  Future<bool> delete(String id) async {
    await ref.read(catalogRepositoryProvider).deleteProduct(id);
    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);
    return true;
  }
}
```

Note: `Uint8List` is used in the `save` signature without an explicit `dart:typed_data` import — add it:

- [ ] **Step 2: Add the missing import**

Add to the top of `kiosk/lib/features/catalog/state/catalog_products_notifier.dart`, before the `hooks_riverpod` imports:

```dart
import 'dart:typed_data';

```

- [ ] **Step 3: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/state/catalog_products_notifier.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/catalog/state/catalog_products_notifier.dart
git commit -m "feat: add save/delete mutations and variant-names provider to CatalogProductsNotifier"
```

---

### Task 12: `SaveProductDialog` — scaffold, name, category, image

**Files:**
- Create: `kiosk/lib/features/catalog/view/product_dialogs.dart`

This task creates the file with title, name field, category dropdown, and image picker/thumbnail — the variants section is added in Task 13 to keep this diff reviewable. `kiosk/lib/features/catalog/view/product_dialogs.dart` already exists on disk as the old orphaned dialog (`SaveProductDialog`/`DeleteProductDialog` built against the dead `Product` entity) — this task's Step 1 **overwrites it in place** with the new implementation. Task 16's cleanup deletion list does not include this path for that reason — the file survives, its contents change.

- [ ] **Step 1: Write the file**

Create/overwrite `kiosk/lib/features/catalog/view/product_dialogs.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/rules/min_value.dart';
import '../../../validation/validate.dart';
import '../../../widgets/button.dart';
import '../../../widgets/image_picker_form_field.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../data/catalog_repository.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../state/catalog_categories_notifier.dart';
import '../state/catalog_products_notifier.dart';

Future<CatalogProduct?> showSaveProductDialog(BuildContext context, {CatalogProduct? product}) {
  return showDialog<CatalogProduct>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SaveProductDialog(product: product),
  );
}

class SaveProductDialog extends HookConsumerWidget {
  const SaveProductDialog({super.key, this.product});

  final CatalogProduct? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: product?.name);
    final categoryId = useState<String?>(product?.category?.id);
    final imageController = useImagePickerController();

    final variantsFuture = useMemoized(
      () => product != null
          ? ref.read(catalogRepositoryProvider).fetchProductVariants(product!.id)
          : Future.value(const <CatalogProductVariant>[]),
      [product?.id],
    );
    final variantsSnapshot = useFuture(variantsFuture);
    final isLoadingVariants = product != null && !variantsSnapshot.hasData;

    final categoriesAsync = ref.watch(catalogCategoriesProvider);
    final categories = categoriesAsync.value ?? const <CatalogCategory>[];

    final saveAction = CatalogProductsNotifier.saveAction;
    final saveStatus = ref.watch(saveAction);

    ref.listen(saveAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(:final value)
          when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(value);
      }
    });

    final r = context.responsive;

    if (isLoadingVariants) {
      return Dialog(
        backgroundColor: ColorSet.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: ColorSet.primary, strokeWidth: 3),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.value(kiosk: 32, tablet: 24, phone: 16)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: r.value(kiosk: 32, tablet: 24, phone: 16),
        vertical: r.value(kiosk: 32, tablet: 24, phone: 16),
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Container(
            width: r.value(kiosk: 600.0, tablet: 500.0, phone: double.infinity),
            padding: EdgeInsets.symmetric(
              horizontal: r.value(kiosk: 32, tablet: 24, phone: 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: r.value(kiosk: 16, tablet: 12, phone: 8),
              children: [
                Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
                Text(
                  product != null ? 'Edit Product' : 'Add Product',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextBoxFormField(
                  controller: nameController,
                  label: 'Name',
                  hint: 'Enter product name',
                  maxLines: 1,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                ),
                _CategoryField(
                  categories: categories,
                  value: categoryId.value,
                  onChanged: (value) => categoryId.value = value,
                ),
                // Variants section inserted here in Task 13.
                if (product != null && product!.imageUrl != null && product!.imageUrl!.isNotEmpty)
                  _CurrentImageThumbnail(imageUrl: product!.imageUrl!),
                ImagePickerFormField(
                  controller: imageController,
                  label: product != null && product!.imageUrl != null && product!.imageUrl!.isNotEmpty
                      ? 'Replace Image'
                      : 'Image (optional)',
                  height: r.value(kiosk: 180, tablet: 150, phone: 110),
                  style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                ),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () => Navigator.of(context).pop(),
                      label: Text(
                        'Cancel',
                        style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                      ),
                    ),
                    Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Button(
                      onPressed: saveStatus is! MutationPending
                          ? () {
                              if (!formKey.currentState!.validate()) return;

                              final selectedCategory = categories.firstWhere(
                                (c) => c.id == categoryId.value,
                              );
                              final draft = (product ?? CatalogProduct.draft()).copyWith(
                                name: nameController.text.trim(),
                                category: CatalogCategoryRef(
                                  id: selectedCategory.id,
                                  name: selectedCategory.name,
                                ),
                              );

                              saveAction.run(ref, (txn) async {
                                return txn.get(catalogProductsProvider.notifier).save(
                                      draft,
                                      const <CatalogProductVariant>[], // replaced in Task 13
                                      imageBytes: imageController.value,
                                    );
                              }).ignore();
                            }
                          : null,
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      label: Text(
                        saveStatus is MutationPending
                            ? 'Saving...'
                            : (product != null ? 'Update' : 'Save'),
                        style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                      ),
                    ),
                  ],
                ),
                Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.categories, required this.value, required this.onChanged});

  final List<CatalogCategory> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        const Gap(4),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text('Select category'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: POSColors.borderDefault),
            ),
          ),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'Please select a category.' : null,
        ),
      ],
    );
  }
}

class _CurrentImageThumbnail extends StatelessWidget {
  const _CurrentImageThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current image',
          style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        const Gap(4),
        ClipRRect(
          borderRadius: BorderRadius.circular(POSRadius.md),
          child: Image.network(
            imageUrl,
            height: r.value(kiosk: 100, tablet: 90, phone: 70),
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: r.value(kiosk: 100, tablet: 90, phone: 70),
              color: POSColors.surfaceSubtle,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported_rounded, color: POSColors.iconSubtle),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/product_dialogs.dart`
Expected: pre-existing-style warnings acceptable, but no errors. (`min_value.dart` import is unused at this point — that's fine, it's consumed in Task 13; if `dart analyze` flags it as an unused-import error rather than a warning, remove the import for now and re-add it in Task 13.)

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/view/product_dialogs.dart
git commit -m "feat: add SaveProductDialog scaffold (name, category, image)"
```

---

### Task 13: `SaveProductDialog` — variants section + `DeleteProductDialog`

**Files:**
- Modify: `kiosk/lib/features/catalog/view/product_dialogs.dart`

Adds the repeating variant-row editor (name autocomplete, price, default toggle, remove button, add-variant button) and wires the real variant list into the save call. Adds `DeleteProductDialog` alongside it.

- [ ] **Step 1: Add the `_VariantRow` helper class**

In `kiosk/lib/features/catalog/view/product_dialogs.dart`, add this class after `SaveProductDialog` (before `_CategoryField`):

```dart
class _VariantRow {
  _VariantRow({
    required this.id,
    required this.nameController,
    required this.priceController,
    required this.isDefault,
  });

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  bool isDefault;

  factory _VariantRow.blank({required bool isDefault}) {
    return _VariantRow(
      id: '',
      nameController: TextEditingController(),
      priceController: TextEditingController(),
      isDefault: isDefault,
    );
  }

  factory _VariantRow.fromVariant(CatalogProductVariant variant) {
    return _VariantRow(
      id: variant.id,
      nameController: TextEditingController(text: variant.name),
      priceController: TextEditingController(text: variant.price.toStringAsFixed(2)),
      isDefault: variant.isDefault,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

String? _validateVariantRows(List<_VariantRow> rows) {
  if (rows.isEmpty) return 'Add at least one variant.';
  final seenNames = <String>[];
  for (final row in rows) {
    final name = row.nameController.text.trim();
    if (name.isEmpty) return 'Every variant needs a name.';
    if (seenNames.contains(name.toLowerCase())) {
      return 'Variant names must be unique ("$name" is repeated).';
    }
    seenNames.add(name.toLowerCase());

    final price = double.tryParse(row.priceController.text.trim());
    if (price == null || price < 0.01) {
      return 'Every variant needs a price of at least 0.01.';
    }
  }
  return null;
}
```

- [ ] **Step 2: Add the `_VariantsSection` widget**

Add this class after `_validateVariantRows`:

```dart
class _VariantsSection extends HookConsumerWidget {
  const _VariantsSection({required this.rows});

  final ValueNotifier<List<_VariantRow>> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final namesAsync = ref.watch(catalogVariantNamesProvider);
    final existingNames = namesAsync.value ?? const <String>[];

    void setDefault(_VariantRow target) {
      for (final row in rows.value) {
        row.isDefault = identical(row, target);
      }
      rows.value = [...rows.value];
    }

    void addRow() {
      rows.value = [...rows.value, _VariantRow.blank(isDefault: rows.value.isEmpty)];
    }

    void removeRow(_VariantRow row) {
      final wasDefault = row.isDefault;
      row.dispose();
      final updated = rows.value.where((r) => r != row).toList();
      if (wasDefault && updated.isNotEmpty) {
        updated.first.isDefault = true;
      }
      rows.value = updated;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variants',
          style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        Text(
          'e.g. Regular, Venti',
          style: TextStyle(
            fontSize: r.value(kiosk: 12, tablet: 12, phone: 11),
            color: POSColors.textTertiary,
          ),
        ),
        const Gap(8),
        for (final row in rows.value) ...[
          _VariantRowField(
            row: row,
            existingNames: existingNames,
            onSetDefault: () => setDefault(row),
            onRemove: rows.value.length > 1 ? () => removeRow(row) : null,
          ),
          const Gap(8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Button.outlined(
            foregroundColor: ColorSet.primary,
            leading: const Icon(Icons.add, size: 18),
            onPressed: addRow,
            label: Text(
              'Add Variant',
              style: TextStyle(fontSize: r.value(kiosk: 13, tablet: 13, phone: 12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantRowField extends StatelessWidget {
  const _VariantRowField({
    required this.row,
    required this.existingNames,
    required this.onSetDefault,
    required this.onRemove,
  });

  final _VariantRow row;
  final List<String> existingNames;
  final VoidCallback onSetDefault;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Autocomplete<String>(
            textEditingController: row.nameController,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return existingNames;
              return existingNames.where(
                (name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()),
              );
            },
            onSelected: (selection) => row.nameController.text = selection,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'e.g. Regular, Venti',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    borderSide: const BorderSide(color: POSColors.borderDefault),
                  ),
                ),
                validator: Validate(rules: [isRequired()]).call,
              );
            },
          ),
        ),
        const Gap(8),
        Expanded(
          flex: 2,
          child: TextBoxFormField(
            controller: row.priceController,
            hint: 'Price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Required.';
              final price = double.tryParse(trimmed);
              if (price == null) return 'Invalid number.';
              return Validate<double>(rules: [minValue(0.01)]).call(price);
            },
          ),
        ),
        const Gap(4),
        IconButton(
          onPressed: onSetDefault,
          icon: Icon(
            row.isDefault ? Icons.star_rounded : Icons.star_border_rounded,
            color: row.isDefault ? ColorSet.secondary : POSColors.iconSubtle,
          ),
          tooltip: 'Default variant',
        ),
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.close_rounded,
            color: onRemove != null ? ColorSet.danger : POSColors.textDisabled,
          ),
          tooltip: 'Remove variant',
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Wire `_VariantsSection` into `SaveProductDialog`**

In `SaveProductDialog.build`, add the `variantRows` hook state and its lifecycle handling right after the `variantsSnapshot`/`isLoadingVariants` declarations:

```dart
    final variantRows = useState<List<_VariantRow>>(
      product == null ? [_VariantRow.blank(isDefault: true)] : const [],
    );
    final variantsInitialized = useRef(false);

    useEffect(() {
      if (variantsSnapshot.hasData && !variantsInitialized.value) {
        variantsInitialized.value = true;
        final loaded = variantsSnapshot.data!;
        variantRows.value = loaded.isEmpty
            ? [_VariantRow.blank(isDefault: true)]
            : loaded.map(_VariantRow.fromVariant).toList();
      }
      return null;
    }, [variantsSnapshot.hasData]);

    useEffect(() {
      return () {
        for (final row in variantRows.value) {
          row.dispose();
        }
      };
    }, const []);
```

Replace the `// Variants section inserted here in Task 13.` comment with:

```dart
                _VariantsSection(rows: variantRows),
```

Replace the submit handler's validation and payload construction — inside the `onPressed: saveStatus is! MutationPending ? () { ... } : null` closure, replace:

```dart
                              if (!formKey.currentState!.validate()) return;

                              final selectedCategory = categories.firstWhere(
                                (c) => c.id == categoryId.value,
                              );
                              final draft = (product ?? CatalogProduct.draft()).copyWith(
                                name: nameController.text.trim(),
                                category: CatalogCategoryRef(
                                  id: selectedCategory.id,
                                  name: selectedCategory.name,
                                ),
                              );

                              saveAction.run(ref, (txn) async {
                                return txn.get(catalogProductsProvider.notifier).save(
                                      draft,
                                      const <CatalogProductVariant>[], // replaced in Task 13
                                      imageBytes: imageController.value,
                                    );
                              }).ignore();
```

with:

```dart
                              if (!formKey.currentState!.validate()) return;

                              final variantError = _validateVariantRows(variantRows.value);
                              if (variantError != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(variantError),
                                    backgroundColor: ColorSet.danger,
                                  ),
                                );
                                return;
                              }

                              final selectedCategory = categories.firstWhere(
                                (c) => c.id == categoryId.value,
                              );
                              final draft = (product ?? CatalogProduct.draft()).copyWith(
                                name: nameController.text.trim(),
                                category: CatalogCategoryRef(
                                  id: selectedCategory.id,
                                  name: selectedCategory.name,
                                ),
                              );
                              final variants = variantRows.value
                                  .map(
                                    (row) => CatalogProductVariant(
                                      id: row.id,
                                      name: row.nameController.text.trim(),
                                      price: double.parse(row.priceController.text.trim()),
                                      isDefault: row.isDefault,
                                    ),
                                  )
                                  .toList();

                              saveAction.run(ref, (txn) async {
                                return txn.get(catalogProductsProvider.notifier).save(
                                      draft,
                                      variants,
                                      imageBytes: imageController.value,
                                    );
                              }).ignore();
```

- [ ] **Step 4: Add `DeleteProductDialog`**

Add at the end of `kiosk/lib/features/catalog/view/product_dialogs.dart`:

```dart
Future<bool?> showDeleteProductDialog(BuildContext context, CatalogProduct product) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteProductDialog(product: product),
  );
}

class DeleteProductDialog extends ConsumerWidget {
  const DeleteProductDialog({super.key, required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteAction = CatalogProductsNotifier.deleteAction;
    final deleteStatus = ref.watch(deleteAction);

    ref.listen(deleteAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(:final value)
          when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(value);
      }
    });

    final r = context.responsive;

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.value(kiosk: 24, tablet: 20, phone: 16)),
      ),
      child: Container(
        width: r.value<double>(kiosk: 440, tablet: 380, phone: double.infinity),
        padding: EdgeInsets.all(r.value(kiosk: 32.0, tablet: 24.0, phone: 20.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r.value<double>(kiosk: 80, tablet: 64, phone: 56),
              height: r.value<double>(kiosk: 80, tablet: 64, phone: 56),
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: ColorSet.danger,
                size: r.value<double>(kiosk: 40, tablet: 32, phone: 28),
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
            Text(
              'Delete Product',
              style: TextStyle(
                fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                fontWeight: FontWeight.w700,
                color: ColorSet.text,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
            Text(
              'Are you sure you want to delete "${product.name}"?\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                color: ColorSet.text.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 28, tablet: 24, phone: 20)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: ColorSet.text.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                        fontWeight: FontWeight.w600,
                        color: ColorSet.text,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                Expanded(
                  child: FilledButton(
                    onPressed: deleteStatus is! MutationPending
                        ? () {
                            deleteAction.run(ref, (txn) async {
                              return txn.get(catalogProductsProvider.notifier).delete(product.id);
                            }).ignore();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorSet.danger,
                      padding: EdgeInsets.symmetric(
                        vertical: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      deleteStatus is MutationPending ? 'Deleting...' : 'Delete',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                        fontWeight: FontWeight.w600,
                        color: ColorSet.light,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/product_dialogs.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add kiosk/lib/features/catalog/view/product_dialogs.dart
git commit -m "feat: add variant editor and DeleteProductDialog to product dialogs"
```

---

### Task 14: Wire `catalog_grid_screen.dart`

**Files:**
- Modify: `kiosk/lib/features/catalog/view/catalog_grid_screen.dart`

Threads `isAdminOrSupervisor` from `loginStateProvider` down to `_FilterBar` and each `_ProductCard`, wires the Add Product button, and replaces the "Manage" button with role-gated Edit/Delete actions.

- [ ] **Step 1: Add the import**

Add to the import block near the top of `kiosk/lib/features/catalog/view/catalog_grid_screen.dart`:

```dart
import '../../auth/state/login_state_notifier.dart';
```

and

```dart
import 'product_dialogs.dart';
```

- [ ] **Step 2: Compute and thread `isAdminOrSupervisor` from `CatalogGridScreen`**

In `CatalogGridScreen.build`, add right after `final searchQuery = useState<String?>(null);`:

```dart
    final isAdminOrSupervisor =
        ref.watch(loginStateProvider).value?.isAdminOrSupervisor ?? false;
```

Update the returned `Column`'s children to pass the flag down:

```dart
        children: [
          _FilterBar(
            categoryId: categoryId,
            searchQuery: searchQuery,
            isAdminOrSupervisor: isAdminOrSupervisor,
          ),
          _CategoryChips(selectedCategoryId: categoryId),
          Expanded(child: _ProductsGrid(isAdminOrSupervisor: isAdminOrSupervisor)),
        ],
```

- [ ] **Step 3: Update `_FilterBar`**

Replace the `_FilterBar` class constructor and fields:

```dart
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categoryId,
    required this.searchQuery,
    required this.isAdminOrSupervisor,
  });

  final ValueNotifier<String?> categoryId;
  final ValueNotifier<String?> searchQuery;
  final bool isAdminOrSupervisor;
```

Replace the phone add-button and desktop add-button blocks (inside the `Row` children, after the `Expanded(child: HookBuilder(...))`):

```dart
          if (isAdminOrSupervisor)
            if (isPhone)
              FilledButton(
                onPressed: () => showSaveProductDialog(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add, size: 20),
              )
            else
              Button(
                label: const Text('Add Product'),
                leading: const Icon(Icons.add),
                onPressed: () => showSaveProductDialog(context),
              ),
```

(This replaces the two previous unconditional `if (isPhone) ... else ...` blocks with a single `isAdminOrSupervisor`-gated version of the same structure.)

- [ ] **Step 4: Update `_ProductsGrid` → `_Grid` → `_ProductCard` to thread the flag**

Replace `_ProductsGrid`:

```dart
class _ProductsGrid extends ConsumerWidget {
  const _ProductsGrid({required this.isAdminOrSupervisor});

  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogProductsProvider.select((it) => it.whenData((d) => d.products)));

    return state.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(
              color: ColorSet.primary,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
            ),
          ),
      error: (_, __) => const Center(child: SizedBox.shrink()),
      data: (products) {
        if (products.isEmpty) {
          return _EmptyProductsState();
        }

        return ResponsiveBuilder(
          kiosk: (context) => _Grid(
            products: products,
            crossAxisCount: 4,
            ratio: 0.72,
            isAdminOrSupervisor: isAdminOrSupervisor,
          ),
          tablet: (context) => _Grid(
            products: products,
            crossAxisCount: 3,
            ratio: 0.72,
            isAdminOrSupervisor: isAdminOrSupervisor,
          ),
          phone: (context) => _Grid(
            products: products,
            crossAxisCount: 2,
            ratio: 0.70,
            isAdminOrSupervisor: isAdminOrSupervisor,
          ),
        );
      },
    );
  }
}
```

Replace `_Grid`:

```dart
class _Grid extends StatelessWidget {
  const _Grid({
    required this.products,
    required this.crossAxisCount,
    required this.ratio,
    required this.isAdminOrSupervisor,
  });

  final List<CatalogProduct> products;
  final int crossAxisCount;
  final double ratio;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ratio,
        crossAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        mainAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductCard(
        product: products[index],
        isAdminOrSupervisor: isAdminOrSupervisor,
      ),
    );
  }
}
```

- [ ] **Step 5: Update `_ProductCard`'s Manage button**

Replace the `_ProductCard` class constructor:

```dart
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.isAdminOrSupervisor});

  final CatalogProduct product;
  final bool isAdminOrSupervisor;
```

Replace the bottom `Button` (the commented-out "Manage" button block):

```dart
                    if (isAdminOrSupervisor) ...[
                      const Spacer(),
                      Gap(r.value(kiosk: 8, tablet: 6, phone: 4)),
                      Row(
                        children: [
                          Expanded(
                            child: Button(
                              label: Text(
                                'Edit',
                                style: TextStyle(fontSize: r.value(kiosk: 12, tablet: 11, phone: 10)),
                              ),
                              onPressed: () => showSaveProductDialog(context, product: product),
                              backgroundColor: ColorSet.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          Gap(r.value(kiosk: 6, tablet: 5, phone: 4)),
                          IconButton(
                            onPressed: () => showDeleteProductDialog(context, product),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: r.value(kiosk: 20, tablet: 18, phone: 16),
                              color: ColorSet.danger,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: ColorSet.danger.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(POSRadius.md),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const Spacer(),
```

This replaces the previous unconditional block:

```dart
                    const Spacer(),
                    Gap(r.value(kiosk: 8, tablet: 6, phone: 4)),
                    SizedBox(
                      width: double.infinity,
                      child: Button(
                        label: Text(
                          'Manage',
                          style: TextStyle(fontSize: r.value(kiosk: 12, tablet: 11, phone: 10)),
                        ),
                        // onPressed: () => ProductDetailRoute(product.id).push<void>(context),
                        backgroundColor: ColorSet.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
```

- [ ] **Step 6: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/catalog_grid_screen.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add kiosk/lib/features/catalog/view/catalog_grid_screen.dart
git commit -m "feat: wire Add/Edit/Delete Product into CatalogGridScreen, gated to admin/supervisor"
```

---

### Task 15: Trim `products_api.dart` and `product_groups_api.dart`

**Files:**
- Modify: `kiosk/lib/data/backend_api/sources/products_api.dart`
- Modify: `kiosk/lib/data/backend_api/sources/product_groups_api.dart`

Both files are shared with the live sales/ordering flow (`ProductRepositoryImpl.getById` and `ProductGroupRepositoryImpl`/`ProductRepositoryImpl.getByGroup`, verified via import grep) — only their now-dead `create`/`update`/`delete`/`getAll` methods (used solely by the orphaned catalog admin stack deleted in Task 16) are removed, not the files themselves.

- [ ] **Step 1: Trim `products_api.dart`**

Replace the full contents of `kiosk/lib/data/backend_api/sources/products_api.dart`:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/product_details_dto.dart';

final productsApiProvider = Provider<ProductsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductsApi(httpClient);
});

class ProductsApi {
  const ProductsApi(this._httpClient);

  final Dio _httpClient;

  Future<ProductDetailsDto> getById(int id) async {
    final response = await _httpClient.get<dynamic>('/api/v1/products/$id');
    final json = jsonEncode(response.data);
    return ProductDetailsDto.fromJson(json);
  }
}
```

- [ ] **Step 2: Trim `product_groups_api.dart`**

Replace the full contents of `kiosk/lib/data/backend_api/sources/product_groups_api.dart`:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/product_group_dto.dart';
import '../schemas/product_group_query_dto.dart';
import '../schemas/product_list_item_dto.dart';

final productGroupsApiProvider = Provider<ProductGroupsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductGroupsApi(httpClient);
});

class ProductGroupsApi {
  const ProductGroupsApi(this._httpClient);

  final Dio _httpClient;

  Future<PaginatedResponseDto<ProductGroupDto>> getAll(ProductGroupQueryDto query) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/product-groups',
      queryParameters: query.toMap(),
    );
    final json = jsonEncode(response.data);
    ProductGroupDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<ProductGroupDto>(json);
  }

  Future<PaginatedResponseDto<ProductListItemDto>> getProductsByGroup(int id) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/product-groups/$id/products',
      queryParameters: {'limit': 100},
    );
    final json = jsonEncode(response.data);
    ProductListItemDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<ProductListItemDto>(json);
  }
}
```

- [ ] **Step 3: Verify these compile in isolation**

Run: `cd kiosk && fvm dart analyze lib/data/backend_api/sources/products_api.dart lib/data/backend_api/sources/product_groups_api.dart`
Expected: `No issues found!` (full-project analyze happens in Task 17, after Task 16's deletions remove the now-dangling `create`/`update`/`delete`/`getAll` call-sites in the orphaned use-cases — those use-case files themselves are deleted in Task 16, so no code will be left calling the removed methods).

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/data/backend_api/sources/products_api.dart kiosk/lib/data/backend_api/sources/product_groups_api.dart
git commit -m "refactor: trim dead create/update/delete/getAll methods from products/product-groups APIs"
```

---

### Task 16: Delete the fully-dead orphaned catalog stack

**Files:** deletions only (list below)

Every file in this list was verified via `grep` for its exact import path to have **zero importers outside this set** — confirmed distinct from the similarly-named but live `features/sales/entities/*`, `features/sales/repositories/*`, and `data/backend_api/schemas/{product_details_dto,product_variant_details_dto,product_list_item_dto}.dart`.

- [ ] **Step 1: Re-verify zero importers immediately before deleting (safety net)**

Run:

```bash
cd kiosk/lib
grep -rln "import '\.\./entities/product\.dart'\|import '\.\./entities/product_variant\.dart'\|import '\.\./entities/product_group\.dart'\|import '\.\./entities/modifier_group\.dart'" features/catalog
```

Expected output: only files from the deletion list in Step 2 below — `state/products_notifier.dart`, `state/product_groups_notifier.dart`, `use_cases/save_product.dart`, `use_cases/delete_product.dart`, `use_cases/get_products.dart`, `use_cases/save_product_group.dart`, `use_cases/delete_product_group.dart`, `use_cases/get_product_groups.dart`, `view/products_screen.dart`, `view/product_groups_screen.dart`, `view/product_group_dialogs.dart`, `view/product_variants_screen.dart`, `view/product_detail_screen.dart`. (`view/product_dialogs.dart` will NOT appear here even though it imports these entities today — it's overwritten with new content in Tasks 12–13, not deleted, so it's expected to still reference the old entities at this exact point only if Tasks 12–13 haven't run yet; by the time this task runs, it should already be pointing at `CatalogProduct`/`CatalogProductVariant` instead.) If anything outside this set appears, STOP and investigate before deleting.

- [ ] **Step 2: Delete the files**

```bash
cd "C:\Users\Jufiel\Documents\POS\kiosk\lib"
rm features/catalog/entities/product.dart
rm features/catalog/entities/product.mapper.dart
rm features/catalog/entities/product_variant.dart
rm features/catalog/entities/product_variant.mapper.dart
rm features/catalog/entities/product_group.dart
rm features/catalog/entities/product_group.mapper.dart
rm features/catalog/entities/modifier_group.dart
rm features/catalog/entities/modifier_group.mapper.dart
rm features/catalog/state/products_notifier.dart
rm features/catalog/state/products_notifier.mapper.dart
rm features/catalog/state/product_groups_notifier.dart
rm features/catalog/state/product_groups_notifier.mapper.dart
rm features/catalog/use_cases/save_product.dart
rm features/catalog/use_cases/delete_product.dart
rm features/catalog/use_cases/get_products.dart
rm features/catalog/use_cases/save_product_group.dart
rm features/catalog/use_cases/delete_product_group.dart
rm features/catalog/use_cases/get_product_groups.dart
rm features/catalog/view/products_screen.dart
rm features/catalog/view/product_groups_screen.dart
rm features/catalog/view/product_group_dialogs.dart
rm features/catalog/view/product_variants_screen.dart
rm features/catalog/view/product_detail_screen.dart
rm data/backend_api/sources/product_variants_api.dart
rm data/backend_api/schemas/create_product_dto.dart
rm data/backend_api/schemas/create_product_dto.mapper.dart
rm data/backend_api/schemas/update_product_dto.dart
rm data/backend_api/schemas/update_product_dto.mapper.dart
rm data/backend_api/schemas/product_dto.dart
rm data/backend_api/schemas/product_dto.mapper.dart
rm data/backend_api/schemas/product_query_dto.dart
rm data/backend_api/schemas/product_query_dto.mapper.dart
rm data/backend_api/schemas/create_product_group_dto.dart
rm data/backend_api/schemas/create_product_group_dto.mapper.dart
rm data/backend_api/schemas/update_product_group_dto.dart
rm data/backend_api/schemas/update_product_group_dto.mapper.dart
```

Note: `product_dialogs.dart` is intentionally **not** in this list — it was already overwritten with the new dialog implementation in Tasks 12–13, not deleted.

If any `rm` reports "No such file or directory", double-check the path relative to `kiosk/lib` rather than assuming it's already been removed — re-run `git status` to confirm before proceeding.

- [ ] **Step 3: Trim the dead routes in `catalog_route.dart`**

`ProductsRoute` itself is **live** (navigated to from `features/menu/view/menu_grid.dart`) — only remove its two dead child routes. Replace the full contents of `kiosk/lib/navigation/catalog_route.dart`:

```dart
part of 'router.dart';

@TypedGoRoute<ProductsRoute>(path: '/products')
class ProductsRoute extends GoRouteData with $ProductsRoute {
  const ProductsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CatalogScreen();
  }
}
```

- [ ] **Step 4: Regenerate code**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `router.g.dart` no longer references `ProductDetailRoute`/`ProductVariantsRoute`.

- [ ] **Step 5: Commit**

```bash
git add -A kiosk/lib
git commit -m "chore: delete fully-orphaned catalog admin-CRUD stack and dead product detail/variant routes"
```

---

### Task 17: Full kiosk verification

**Files:** none (verification only)

- [ ] **Step 1: Analyze the whole project**

Run: `cd kiosk && fvm dart analyze`
Expected: `No issues found!` If any errors reference a deleted file, re-check Task 16's grep output — something imported a "dead" file that wasn't actually dead, and needs to be restored/re-trimmed rather than deleted outright.

- [ ] **Step 2: Run the kiosk test suite**

Run: `cd kiosk && fvm flutter test`
Expected: PASS — including `test/features/catalog/data/models/product_test.dart` (Task 9) and the pre-existing `test/widget_test.dart`.

- [ ] **Step 3: Confirm no leftover references to deleted symbols**

Run:

```bash
cd kiosk/lib
grep -rn "ProductDetailRoute\|ProductVariantsRoute\|ProductGroupsScreen\|ProductsScreen(" . --include=*.dart
```

Expected: no output (empty).

No commit — verification only.

---

### Task 18: Manual verification in the running app

**Files:** none (manual QA)

Per `CLAUDE.md`, UI changes must be exercised in the real app, not just type-checked. Run the kiosk app and drive the full flow.

- [ ] **Step 1: Start the backend**

Run: `cd be && npm run start:dev`
Expected: server starts on `http://localhost:3000`, `GET http://localhost:3000/api/v1/health` returns 200.

- [ ] **Step 2: Run the kiosk app**

Run: `cd kiosk && fvm flutter run -d windows`

- [ ] **Step 3: Exercise the golden path as an admin/supervisor user**

Log in as a user with `role: admin` or `role: supervisor`. Navigate to the Catalog screen (via the menu grid's Products entry).

- Confirm "Add Product" is visible and opens `SaveProductDialog`.
- Fill in Name, pick a Category, add two variants (e.g. "Regular" / 100, "Large" / 150), leave the image empty, submit.
- Confirm the new product appears in the grid with price = 100.00 (the minimum variant price).
- Open the new product's Edit dialog, confirm both variants loaded with correct name/price, confirm the star icon shows "Regular" (or whichever was added first) as default.
- Add a third variant, remove the "Large" variant, change "Regular"'s price to 90, save.
- Confirm the grid card price updates to 90.00.
- Pick an image via the picker, save again, confirm the card now shows the uploaded image.
- Open Delete on the product, confirm, confirm it disappears from the grid.
- Type a new, never-used variant name into a variant row's name field — confirm it's accepted (autocomplete allows free text). Type a partial match of an existing variant name — confirm suggestions appear.
- Try to submit with zero variants (remove all rows if possible, or attempt save with an empty name) — confirm the inline validation message appears and the request is not sent.
- Try to submit two variants with the same name (case-insensitive, e.g. "Regular" and "regular ") — confirm the duplicate-name validation message appears.

- [ ] **Step 4: Confirm role gating for a non-admin user**

Log in as a `user`-role (cashier) account. Navigate to the Catalog screen.

- Confirm "Add Product" is not visible.
- Confirm product cards show no Edit/Delete affordance.

- [ ] **Step 5: Confirm the live ordering flow still works**

Navigate to the ordering/sales screen, add a product with variants to a cart line item. This exercises `ProductRepositoryImpl.getById` (via the trimmed `products_api.dart`) and confirms Task 15's trim didn't break the live path.

No commit — this task is a verification checklist only. If any step fails, return to the relevant task above, fix, and re-verify before considering the feature complete.
