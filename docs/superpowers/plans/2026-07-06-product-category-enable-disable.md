# Product/Category/Variant Enable-Disable (Replace Delete) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the permanent-feeling "Delete" action for categories, products, and product variants with a reversible Enable/Disable toggle, using flags that already exist on the entities — no hard deletes, no schema changes, no "delete anything" affordance left anywhere in the admin UI.

**Architecture:** Backend: expose `Product.isAvailable` and `ProductVariant.status` through the create/update DTOs (categories already expose their `status` via `isActive`), retire all three `DELETE` routes/services, add an admin-inclusive product listing (mirroring the existing admin-inclusive category listing) so disabled products stay visible to admins, and close a real customer-facing gap where the actual ordering flow (`product-groups` module) doesn't filter disabled categories/products at all today. Kiosk: extend `CatalogRepository`/`CatalogProductsNotifier`/`CatalogCategoriesNotifier` with toggle methods instead of delete methods, swap the trash-can UI affordances for enable/disable ones, and make the customer-facing ordering flow (`features/sales`) filter out disabled variants client-side.

**Tech Stack:** NestJS + TypeORM + PostgreSQL (backend), Flutter + Riverpod + dart_mappable (kiosk).

---

## Important context for whoever implements this

- **No database migration is needed.** `ProductGroup.status`, `Product.isAvailable`, and `ProductVariant.status` already exist as columns. This plan only changes how they're read/written and removes delete code paths.
- There are **three separate backend read paths** for product data, and it's easy to fix the wrong one:
  - `CatalogService` (`be/src/catalog/catalog.service.ts`, raw SQL) — backs the kiosk's **admin** "Manage Products"/"Manage Categories" screen (`CatalogGridScreen`, reached via the `/products` route). This already filters disabled products/categories correctly for its default (non-admin) methods.
  - `ProductsController`/`ProductsService` (`be/src/products/`) — backs `GET/POST/PATCH /products` and `GET/PATCH /product-variants`, used by both the admin edit dialog **and** the real ordering flow's `GET /products/:id` call.
  - `ProductGroupsController`/`ProductGroupsService` (`be/src/product-groups/`) — backs `GET /product-groups` and `GET /product-groups/:id/products`, which is what the **actual order-taking screen** (`OrderingRoute`, `features/sales/...`) uses to list categories and products. **This path currently has zero filtering on `is_available`/`status`** — today, if a category or product were ever marked disabled, it would still show up for a cashier taking an order. Task 8 fixes this.
- Categories already have working enable/disable (`ProductGroup.status`, toggled via `isActive` in `catalog.service.ts`'s `createCategory`/`updateCategory`) — only the "Delete" action needs retiring for categories, no new toggle logic.

---

## Backend Tasks

### Task 1: Expose `isAvailable` on product create/update

**Files:**
- Modify: `be/src/products/dto/create-product.dto.ts`
- Modify: `be/src/products/services/create-product.service.ts`
- Modify: `be/src/products/services/update-product.service.ts`
- Test: `be/src/products/services/create-product.service.spec.ts` (new)
- Test: `be/src/products/services/update-product.service.spec.ts` (new)

- [ ] **Step 1: Write the failing tests**

Create `be/src/products/services/create-product.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CreateProductService } from './create-product.service';
import { FindProductGroupService } from './find-product-group.service';
import { Product } from '../entities/product.entity';
import { User } from '../../users/entities/user.entity';

describe('CreateProductService', () => {
  let service: CreateProductService;

  const mockUser = { id: 1 } as User;
  const mockProductGroup = { id: 2, name: 'Beverages' };

  const mockProductsRepo = {
    create: jest.fn((payload) => payload),
    save: jest.fn((entity) => Promise.resolve({ id: 10, ...entity })),
  };

  const mockFindProductGroupService = { execute: jest.fn().mockResolvedValue(mockProductGroup) };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockFindProductGroupService.execute.mockResolvedValue(mockProductGroup);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateProductService,
        { provide: getRepositoryToken(Product), useValue: mockProductsRepo },
        { provide: FindProductGroupService, useValue: mockFindProductGroupService },
      ],
    }).compile();

    service = module.get<CreateProductService>(CreateProductService);
  });

  it('defaults isAvailable to true when not provided', async () => {
    await service.execute({ groupId: 2, name: 'Cappuccino' }, undefined as never, mockUser, '');

    expect(mockProductsRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ isAvailable: true }),
    );
  });

  it('persists isAvailable: false when explicitly provided', async () => {
    await service.execute(
      { groupId: 2, name: 'Cappuccino', isAvailable: false },
      undefined as never,
      mockUser,
      '',
    );

    expect(mockProductsRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ isAvailable: false }),
    );
  });
});
```

Create `be/src/products/services/update-product.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UpdateProductService } from './update-product.service';
import { FindProductGroupService } from './find-product-group.service';
import { Product } from '../entities/product.entity';
import { User } from '../../users/entities/user.entity';

describe('UpdateProductService', () => {
  let service: UpdateProductService;

  const mockUser = { id: 1 } as User;

  const mockProductsRepo = { update: jest.fn() };
  const mockFindProductGroupService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateProductService,
        { provide: getRepositoryToken(Product), useValue: mockProductsRepo },
        { provide: FindProductGroupService, useValue: mockFindProductGroupService },
      ],
    }).compile();

    service = module.get<UpdateProductService>(UpdateProductService);
  });

  it('persists isAvailable when provided', async () => {
    await service.execute(5, { isAvailable: false }, undefined as never, mockUser, '');

    expect(mockProductsRepo.update).toHaveBeenCalledWith(
      5,
      expect.objectContaining({ isAvailable: false }),
    );
  });

  it('does not touch isAvailable when omitted', async () => {
    await service.execute(5, { name: 'New name' }, undefined as never, mockUser, '');

    const [, payload] = mockProductsRepo.update.mock.calls[0];
    expect(payload.isAvailable).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd be && npx jest src/products/services/create-product.service.spec.ts src/products/services/update-product.service.spec.ts`
Expected: FAIL — `isAvailable` is not read from the DTO anywhere yet.

- [ ] **Step 3: Add `isAvailable` to `CreateProductDto`**

Modify `be/src/products/dto/create-product.dto.ts`:

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';
import { Transform, Type } from 'class-transformer';

/**
 * DTO for creating a new product.
 */
export class CreateProductDto {
  @ApiProperty({ description: 'Product group ID', example: 1 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  groupId: number;

  @ApiProperty({ type: () => String, example: 'Sinigang' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ type: () => String })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Whether the product is available for ordering',
    example: true,
    default: true,
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value === 'true' : value))
  @IsBoolean()
  isAvailable?: boolean;
}
```

`isAvailable` is added here (not as a separate DTO) because `UpdateProductDto` is `PartialType(CreateProductDto)` and will pick it up automatically. The `@Transform` is required because product create/update use `multipart/form-data` (image upload) — form fields arrive as the strings `"true"`/`"false"`, and plain `@IsBoolean()` would reject them; `Boolean("false")` is also `true`, so a naive `@Type(() => Boolean)` would silently invert false values.

- [ ] **Step 4: Pass `isAvailable` through `CreateProductService`**

Modify `be/src/products/services/create-product.service.ts` — in the `payload` object (currently lines 27-32), add the new field with a default of `true`:

```typescript
    const payload: Partial<Product> = {
      name: createProductDto.name,
      description: createProductDto.description,
      isAvailable: createProductDto.isAvailable ?? true,
      createdBy: causer,
      updatedBy: causer,
    };
```

- [ ] **Step 5: Pass `isAvailable` through `UpdateProductService`**

Modify `be/src/products/services/update-product.service.ts` — in the `payload` object (currently lines 27-31):

```typescript
    const payload: Partial<Product> = {
      name: updateProductDto.name,
      description: updateProductDto.description,
      isAvailable: updateProductDto.isAvailable,
      updatedBy: causer,
    };
```

(`updateProductDto.isAvailable` is `undefined` when the field isn't sent; TypeORM's `repository.update()` already ignores `undefined` properties in the SET clause, matching how `name`/`description` are handled here today.)

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd be && npx jest src/products/services/create-product.service.spec.ts src/products/services/update-product.service.spec.ts`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add be/src/products/dto/create-product.dto.ts be/src/products/services/create-product.service.ts be/src/products/services/update-product.service.ts be/src/products/services/create-product.service.spec.ts be/src/products/services/update-product.service.spec.ts
git commit -m "feat: expose isAvailable on product create/update"
```

---

### Task 2: Add `isActive` toggle to product variant update

**Files:**
- Modify: `be/src/products/dto/update-product-variant.dto.ts`
- Modify: `be/src/products/services/update-product-variant.service.ts`
- Test: `be/src/products/services/update-product-variant.service.spec.ts`

- [ ] **Step 1: Write the failing test**

Add to `be/src/products/services/update-product-variant.service.spec.ts` (inside the existing `describe` block, after the current tests):

```typescript
  it('maps isActive: false to status: Disabled', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);

    await service.execute(3, { isActive: false }, mockUser);

    expect(mockVariantsRepo.update).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ status: 'Disabled' }),
    );
  });

  it('maps isActive: true to status: Active', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);

    await service.execute(3, { isActive: true }, mockUser);

    expect(mockVariantsRepo.update).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ status: 'Active' }),
    );
  });

  it('leaves status untouched when isActive is omitted', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);

    await service.execute(3, { name: 'Large', price: 150, isDefault: true }, mockUser);

    const [, payload] = mockVariantsRepo.update.mock.calls[0];
    expect(payload.status).toBeUndefined();
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd be && npx jest src/products/services/update-product-variant.service.spec.ts`
Expected: FAIL — `isActive` doesn't exist on the DTO and is never mapped to `status`.

- [ ] **Step 3: Add `isActive` to `UpdateProductVariantDto`**

Replace the contents of `be/src/products/dto/update-product-variant.dto.ts`:

```typescript
import { ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';
import { CreateProductVariantDto } from './create-product.variant.dto';

/**
 * DTO for updating a product variant.
 */
export class UpdateProductVariantDto extends PartialType(CreateProductVariantDto) {
  @ApiPropertyOptional({
    description: 'Whether the variant is enabled (shown to customers)',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
```

(`isActive` is declared only on the update DTO, not `CreateProductVariantDto` — a variant is always created active; the toggle only ever applies via update.)

- [ ] **Step 4: Map `isActive` to `status` in `UpdateProductVariantService`**

Modify `be/src/products/services/update-product-variant.service.ts`:

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateProductVariantDto } from '../dto/update-product-variant.dto';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantStatus } from '../products.enum';
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

    if (updateProductVariantDto.isActive !== undefined) {
      payload.status = updateProductVariantDto.isActive
        ? ProductVariantStatus.ACTIVE
        : ProductVariantStatus.DISABLED;
    }

    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.recomputeProductPriceService.execute(existing.product.id);
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd be && npx jest src/products/services/update-product-variant.service.spec.ts`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add be/src/products/dto/update-product-variant.dto.ts be/src/products/services/update-product-variant.service.ts be/src/products/services/update-product-variant.service.spec.ts
git commit -m "feat: add isActive toggle to product variant update"
```

---

### Task 3: Surface variant `isActive` in API responses

Both `GET /product-variants/*` (admin edit dialog, via `ProductVariantDto`) and `GET /products/:id` (ordering flow + admin edit dialog, via `ProductDetailsDto`) need to tell callers whether a variant is active, so the kiosk can filter/display accordingly.

**Files:**
- Modify: `be/src/products/dto/product-variant.dto.ts`
- Modify: `be/src/products/mapper/product-variant.mapper.ts`
- Modify: `be/src/products/dto/product-details/variant.dto.ts`
- Modify: `be/src/products/mapper/product-detail.mapper.ts`
- Modify: `be/src/products/services/find-product-details.service.ts`
- Test: `be/src/products/mapper/product-variant.mapper.spec.ts` (new)

- [ ] **Step 1: Write the failing test**

Create `be/src/products/mapper/product-variant.mapper.spec.ts`:

```typescript
import { ProductVariantMapper } from './product-variant.mapper';
import { ProductVariantStatus } from '../products.enum';
import { ProductVariant } from '../entities/product-variant.entity';

describe('ProductVariantMapper.toProductVariantDto', () => {
  it('maps status: Active to isActive: true', () => {
    const entity = {
      id: 1,
      product: { id: 5 },
      name: 'Regular',
      price: 100,
      isDefault: true,
      status: ProductVariantStatus.ACTIVE,
    } as unknown as ProductVariant;

    expect(ProductVariantMapper.toProductVariantDto(entity).isActive).toBe(true);
  });

  it('maps status: Disabled to isActive: false', () => {
    const entity = {
      id: 1,
      product: { id: 5 },
      name: 'Regular',
      price: 100,
      isDefault: true,
      status: ProductVariantStatus.DISABLED,
    } as unknown as ProductVariant;

    expect(ProductVariantMapper.toProductVariantDto(entity).isActive).toBe(false);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/products/mapper/product-variant.mapper.spec.ts`
Expected: FAIL — `isActive` doesn't exist on the returned object.

- [ ] **Step 3: Add `isActive` to `ProductVariantDto` and its mapper**

Modify `be/src/products/dto/product-variant.dto.ts` — add after the `isDefault` property:

```typescript
  @ApiProperty({
    description: 'Whether this variant is enabled (shown to customers)',
    example: true,
  })
  isActive: boolean;
```

Modify `be/src/products/mapper/product-variant.mapper.ts`:

```typescript
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantDto } from '../dto/product-variant.dto';
import { ProductVariantStatus } from '../products.enum';

export class ProductVariantMapper {
  static toProductVariantDto(entity: ProductVariant): ProductVariantDto {
    return {
      id: entity.id,
      productId: entity.product.id,
      name: entity.name,
      price: Number(entity.price),
      isDefault: entity.isDefault,
      isActive: entity.status === ProductVariantStatus.ACTIVE,
    };
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/products/mapper/product-variant.mapper.spec.ts`
Expected: PASS

- [ ] **Step 5: Add `isActive` to `ProductVariantDetailsDto` (the `GET /products/:id` shape)**

Modify `be/src/products/dto/product-details/variant.dto.ts`:

```typescript
import { ApiProperty } from '@nestjs/swagger';

export class ProductVariantDetailsDto {
  @ApiProperty({ description: 'Variant ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Variant name', example: 'Regular' })
  name: string;

  @ApiProperty({ description: 'Display price', example: '100.00' })
  displayPrice: string;

  @ApiProperty({ description: 'Is the default variant', example: true })
  isDefault: boolean;

  @ApiProperty({ description: 'Whether this variant is enabled', example: true })
  isActive: boolean;
}
```

- [ ] **Step 6: Populate it in `ProductDetailMapper`**

Modify `be/src/products/mapper/product-detail.mapper.ts` — add the import and update `toVariantDto` (currently lines 35-42):

```typescript
import { ProductVariantStatus } from '../products.enum';
```

```typescript
  static toVariantDto(variant: ProductVariant, currencySign: string): ProductVariantDetailsDto {
    const dto = new ProductVariantDetailsDto();
    dto.id = variant.id;
    dto.name = variant.name;
    dto.displayPrice = Number(variant.price).toFixed(2);
    dto.isDefault = variant.isDefault;
    dto.isActive = variant.status === ProductVariantStatus.ACTIVE;
    return dto;
  }
```

- [ ] **Step 7: Select `status` in the variant join so it's available to map**

Modify `be/src/products/services/find-product-details.service.ts` — the query currently selects `['pv.id', 'pv.name', 'pv.price', 'pv.isDefault']` for the `product.productVariants` join (line 37). Add `pv.status`:

```typescript
      .addSelect(['pv.id', 'pv.name', 'pv.price', 'pv.isDefault', 'pv.status'])
```

- [ ] **Step 8: Run the full products test suite**

Run: `cd be && npx jest src/products`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add be/src/products/dto/product-variant.dto.ts be/src/products/mapper/product-variant.mapper.ts be/src/products/mapper/product-variant.mapper.spec.ts be/src/products/dto/product-details/variant.dto.ts be/src/products/mapper/product-detail.mapper.ts be/src/products/services/find-product-details.service.ts
git commit -m "feat: surface variant isActive in API responses"
```

---

### Task 4: Retire `DELETE /products/:id`

**Files:**
- Modify: `be/src/products/products.controller.ts`
- Modify: `be/src/products/products.service.ts`
- Modify: `be/src/products/products.service.spec.ts`
- Modify: `be/src/products/products.module.ts`
- Delete: `be/src/products/services/delete-product.service.ts`

- [ ] **Step 1: Remove the route**

Modify `be/src/products/products.controller.ts` — delete the entire `remove` method (lines 129-136):

```typescript
  @Delete(':id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Remove a product by ID' })
  @ApiParam({ name: 'id', description: 'Product ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The product has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.productsService.remove(+id, causer);
  }
```

Also remove `Delete` from the `@nestjs/common` import list (line 8) and `ApiResponse` from the swagger import list (line 22) if nothing else in the file uses them — check with a search of the rest of the file first (`ApiResponse`/`Delete` should have no other usages after this removal).

- [ ] **Step 2: Remove `remove()` from `ProductsService`**

Modify `be/src/products/products.service.ts` — delete the `remove` method (lines 62-66) and the `deleteProductService` constructor param + import (lines 16, 27):

```typescript
import { Injectable } from '@nestjs/common';
import { ProductQueryDto } from './dto/product-query.dto';
import { User } from '../users/entities/user.entity';
import { ProductVariant } from './entities/product-variant.entity';
import { ProductDto } from './dto/product.dto';
import { ProductDetailsDto } from './dto/product-details/product-details.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateProductDto } from './dto/create-product.dto';
import { File } from 'multer';
import { CreateProductService } from './services/create-product.service';
import { FindProductsService } from './services/find-products.service';
import { FindProductService } from './services/find-product.service';
import { FindProductVariantsService } from './services/find-product-variants.service';
import { UpdateProductService } from './services/update-product.service';
import { FindProductDetailsService } from './services/find-product-details.service';

@Injectable()
export class ProductsService {
  constructor(
    private readonly createProductService: CreateProductService,
    private readonly findProductsService: FindProductsService,
    private readonly findProductService: FindProductService,
    private readonly findProductVariantsService: FindProductVariantsService,
    private readonly updateProductService: UpdateProductService,
    private readonly findProductDetailsService: FindProductDetailsService,
  ) {}

  async create(
    createProductDto: CreateProductDto,
    image: File,
    causer: User,
    baseUrl: string,
  ): Promise<ProductDto> {
    return this.createProductService.execute(createProductDto, image, causer, baseUrl);
  }

  async findAll(query: ProductQueryDto) {
    return this.findProductsService.execute(query);
  }

  async findOne(id: number): Promise<ProductDetailsDto> {
    return this.findProductDetailsService.execute(id);
  }

  async findProductVariantsByIds(ids: number[]): Promise<Map<number, ProductVariant>> {
    return this.findProductVariantsService.execute(ids);
  }

  async update(
    id: number,
    updateProductDto: UpdateProductDto,
    image: File,
    causer: User,
    baseUrl: string,
  ): Promise<ProductDetailsDto> {
    await this.updateProductService.execute(id, updateProductDto, image, causer, baseUrl);
    return this.findProductDetailsService.execute(id);
  }
}
```

- [ ] **Step 3: Update `products.service.spec.ts`**

Modify `be/src/products/products.service.spec.ts` — remove the `DeleteProductService` import (line 9) and its provider entry (line 24):

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { ProductsService } from './products.service';
import { CreateProductService } from './services/create-product.service';
import { FindProductsService } from './services/find-products.service';
import { FindProductService } from './services/find-product.service';
import { FindProductVariantsService } from './services/find-product-variants.service';
import { UpdateProductService } from './services/update-product.service';
import { FindProductDetailsService } from './services/find-product-details.service';

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
      ],
    }).compile();

    service = module.get<ProductsService>(ProductsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
```

- [ ] **Step 4: Remove `DeleteProductService` from the module and delete its file**

Modify `be/src/products/products.module.ts` — remove the import (line 16) and the `DeleteProductService` entry from `providers` (line 39).

Delete `be/src/products/services/delete-product.service.ts`.

- [ ] **Step 5: Run the full products test suite and build**

Run: `cd be && npx jest src/products && npm run build`
Expected: PASS, build succeeds.

- [ ] **Step 6: Commit**

```bash
git add be/src/products/products.controller.ts be/src/products/products.service.ts be/src/products/products.service.spec.ts be/src/products/products.module.ts
git rm be/src/products/services/delete-product.service.ts
git commit -m "feat: retire DELETE /products/:id in favor of isAvailable toggle"
```

---

### Task 5: Retire `DELETE /product-variants/:id`

**Files:**
- Modify: `be/src/products/product-variants.controller.ts`
- Modify: `be/src/products/product-variants.controller.spec.ts`
- Modify: `be/src/products/product-variants.service.ts`
- Modify: `be/src/products/products.module.ts`
- Delete: `be/src/products/services/delete-product-variant.service.ts`
- Delete: `be/src/products/services/delete-product-variant.service.spec.ts`

- [ ] **Step 1: Remove the route**

Modify `be/src/products/product-variants.controller.ts` — delete the `remove` method (lines 91-98) and remove `Delete` from the `@nestjs/common` import (line 1) and `ApiResponse` from the swagger import (line 9) if unused elsewhere in the file.

- [ ] **Step 2: Remove the route test**

Modify `be/src/products/product-variants.controller.spec.ts` — remove the `remove: jest.fn()` entry from the mocked service (line 40) and the entire `describe('remove', ...)` block (lines 109-119).

- [ ] **Step 3: Remove `remove()` from `ProductVariantsService`**

Modify `be/src/products/product-variants.service.ts` — remove the `deleteProductVariantService` constructor param + import, and the `remove` method:

```typescript
import { Injectable } from '@nestjs/common';
import { User } from '../users/entities/user.entity';
import { ProductVariantDto } from './dto/product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';
import { CreateProductVariantDto } from './dto/create-product.variant.dto';
import { FindProductVariantsByProductIdService } from './services/find-product-variants-by-product-id.service';
import { CreateProductVariantService } from './services/create-product-variant.service';
import { FindProductVariantService } from './services/find-product-variant.service';
import { UpdateProductVariantService } from './services/update-product-variant.service';
import { FindDistinctVariantNamesService } from './services/find-distinct-variant-names.service';

@Injectable()
export class ProductVariantsService {
  constructor(
    private readonly createProductVariantService: CreateProductVariantService,
    private readonly findProductVariantsByProductIdService: FindProductVariantsByProductIdService,
    private readonly findProductVariantService: FindProductVariantService,
    private readonly updateProductVariantService: UpdateProductVariantService,
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
}
```

- [ ] **Step 4: Remove `DeleteProductVariantService` from the module and delete its files**

Modify `be/src/products/products.module.ts` — remove the import (line 23) and the `DeleteProductVariantService` entry from `providers` (line 45).

Delete `be/src/products/services/delete-product-variant.service.ts` and `be/src/products/services/delete-product-variant.service.spec.ts`.

- [ ] **Step 5: Run the full products test suite and build**

Run: `cd be && npx jest src/products && npm run build`
Expected: PASS, build succeeds.

- [ ] **Step 6: Commit**

```bash
git add be/src/products/product-variants.controller.ts be/src/products/product-variants.controller.spec.ts be/src/products/product-variants.service.ts be/src/products/products.module.ts
git rm be/src/products/services/delete-product-variant.service.ts be/src/products/services/delete-product-variant.service.spec.ts
git commit -m "feat: retire DELETE /product-variants/:id in favor of isActive toggle"
```

---

### Task 6: Retire `DELETE /catalog/admin/categories/:id`

**Files:**
- Modify: `be/src/catalog/catalog-admin.controller.ts`
- Modify: `be/src/catalog/catalog.service.ts`
- Modify: `be/src/catalog/catalog.service.spec.ts`

- [ ] **Step 1: Remove the route**

Modify `be/src/catalog/catalog-admin.controller.ts` — delete the `deleteCategory` method (lines 78-97) and remove `Delete` from the `@nestjs/common` import (line 6) if unused elsewhere in the file.

- [ ] **Step 2: Remove `deleteCategory` from `CatalogService`**

Modify `be/src/catalog/catalog.service.ts` — delete the `deleteCategory` method (lines 141-148).

- [ ] **Step 3: Remove the test**

Modify `be/src/catalog/catalog.service.spec.ts` — delete the entire `describe('deleteCategory', ...)` block (lines 76-93).

- [ ] **Step 4: Run the catalog test suite and build**

Run: `cd be && npx jest src/catalog && npm run build`
Expected: PASS, build succeeds.

- [ ] **Step 5: Commit**

```bash
git add be/src/catalog/catalog-admin.controller.ts be/src/catalog/catalog.service.ts be/src/catalog/catalog.service.spec.ts
git commit -m "feat: retire DELETE /catalog/admin/categories/:id, disable replaces it"
```

---

### Task 7: Admin-inclusive product listing (`GET /catalog/admin/products`)

Today, `CatalogGridScreen` (the kiosk's admin product-management screen) reads products through the same filtered `getProducts()` used by customer ordering — so once a product can be disabled, an admin who disables one loses the ability to see or re-enable it. This closes that gap, mirroring the already-working `getAllCategoriesForAdmin` pattern.

**Files:**
- Modify: `be/src/catalog/catalog.service.ts`
- Modify: `be/src/catalog/catalog.service.spec.ts`
- Modify: `be/src/catalog/catalog-admin.controller.ts`

- [ ] **Step 1: Write the failing test**

Add to `be/src/catalog/catalog.service.spec.ts` (a new `describe` block, using the existing `mockDataSource`):

```typescript
  describe('getProducts', () => {
    it('filters to active/available products by default', async () => {
      mockDataSource.query.mockResolvedValue([]);

      await service.getProducts();

      const [sql] = mockDataSource.query.mock.calls[0];
      expect(sql).toContain("p.status       = 'Active'");
      expect(sql).toContain('p.is_available = true');
    });

    it('drops the active/available filter when includeDisabled is true', async () => {
      mockDataSource.query.mockResolvedValue([]);

      await service.getProducts(undefined, undefined, true);

      const [sql] = mockDataSource.query.mock.calls[0];
      expect(sql).not.toContain("p.status       = 'Active'");
      expect(sql).not.toContain('p.is_available = true');
      expect(sql).toContain('p.deleted_at   IS NULL');
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd be && npx jest src/catalog/catalog.service.spec.ts`
Expected: FAIL — `getProducts` doesn't accept an `includeDisabled` param yet.

- [ ] **Step 3: Add the `includeDisabled` param to `CatalogService.getProducts`**

Modify `be/src/catalog/catalog.service.ts` — change the method signature and the `conditions` initialization (currently lines 150-155):

```typescript
  async getProducts(
    categoryId?: string,
    search?: string,
    includeDisabled = false,
  ): Promise<unknown[]> {
    const conditions: string[] = includeDisabled
      ? ['p.deleted_at   IS NULL']
      : ["p.status       = 'Active'", 'p.is_available = true', 'p.deleted_at   IS NULL'];
    const params: unknown[] = [];
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd be && npx jest src/catalog/catalog.service.spec.ts`
Expected: PASS

- [ ] **Step 5: Add the admin route**

Modify `be/src/catalog/catalog-admin.controller.ts` — add `Query` to the `@nestjs/common` import and `ApiQuery` to the swagger import, then add a new endpoint (placed after `getAllCategories`, before `createCategory`):

```typescript
  @Get('products')
  @ApiOperation({ summary: 'List all products including disabled/unavailable ones (authenticated users)' })
  @ApiQuery({ name: 'category_id', required: false, description: 'Filter by category UUID' })
  @ApiQuery({ name: 'search', required: false, description: 'Case-insensitive name search' })
  @ApiOkResponse({ description: 'All products for the given filters, including disabled ones.' })
  async getAllProducts(
    @Query('category_id') categoryId?: string,
    @Query('search') search?: string,
  ): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getProducts(categoryId, search, true);
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
```

- [ ] **Step 6: Run the full catalog test suite and build**

Run: `cd be && npx jest src/catalog && npm run build`
Expected: PASS, build succeeds.

- [ ] **Step 7: Commit**

```bash
git add be/src/catalog/catalog.service.ts be/src/catalog/catalog.service.spec.ts be/src/catalog/catalog-admin.controller.ts
git commit -m "feat: add admin-inclusive product listing so disabled products stay manageable"
```

---

### Task 8: Filter disabled categories/products out of the real ordering flow

This is the gap described in "Important context" above: `ProductGroupsService` (used by the actual order-taking screen, not `CatalogService`) doesn't filter on `status`/`is_available` at all today.

**Files:**
- Modify: `be/src/product-groups/product-groups.service.ts`
- Modify: `be/src/product-groups/product-groups.service.spec.ts`

- [ ] **Step 1: Write the failing tests**

Replace the contents of `be/src/product-groups/product-groups.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ProductGroupsService } from './product-groups.service';
import { ProductGroup } from './entities/product-group.entity';
import { Product } from '../products/entities/product.entity';
import { BaseStatus } from '../utils/shared-enums';
import { ProductStatus } from '../products/products.enum';

describe('ProductGroupsService', () => {
  let service: ProductGroupsService;

  const mockProductGroupRepo = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    findAndCount: jest.fn().mockResolvedValue([[], 0]),
    update: jest.fn(),
    softDelete: jest.fn(),
  };

  const mockProductRepo = {
    findAndCount: jest.fn().mockResolvedValue([[], 0]),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockProductGroupRepo.findAndCount.mockResolvedValue([[], 0]);
    mockProductRepo.findAndCount.mockResolvedValue([[], 0]);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductGroupsService,
        { provide: getRepositoryToken(ProductGroup), useValue: mockProductGroupRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductRepo },
      ],
    }).compile();

    service = module.get<ProductGroupsService>(ProductGroupsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('only queries active categories', async () => {
      await service.findAll({ page: 1, limit: 20 } as never);

      expect(mockProductGroupRepo.findAndCount).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ status: BaseStatus.ACTIVE }),
        }),
      );
    });
  });

  describe('findProductsByGroupId', () => {
    it('only queries available, active products', async () => {
      await service.findProductsByGroupId(7, { page: 1, limit: 20 } as never);

      expect(mockProductRepo.findAndCount).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            productGroup: { id: 7 },
            isAvailable: true,
            status: ProductStatus.ACTIVE,
          }),
        }),
      );
    });
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd be && npx jest src/product-groups/product-groups.service.spec.ts`
Expected: FAIL — neither method filters on status/availability yet.

- [ ] **Step 3: Add the filters**

Modify `be/src/product-groups/product-groups.service.ts` — add the imports and update `findAll` and `findProductsByGroupId`:

```typescript
import { BaseStatus } from '../utils/shared-enums';
import { ProductStatus } from '../products/products.enum';
```

In `findAll` (currently lines 55-91), change the `where` initialization:

```typescript
    const where: FindOptionsWhere<ProductGroup> = { status: BaseStatus.ACTIVE };
```

In `findProductsByGroupId` (currently lines 93-130), change `baseWhere`:

```typescript
    const baseWhere = {
      productGroup: { id: groupId },
      isAvailable: true,
      status: ProductStatus.ACTIVE,
    };
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd be && npx jest src/product-groups/product-groups.service.spec.ts`
Expected: PASS

- [ ] **Step 5: Run the full backend test suite and build**

Run: `cd be && npm run test && npm run build`
Expected: PASS (aside from any pre-existing unrelated failures — do not attempt to fix suites unrelated to this change), build succeeds.

- [ ] **Step 6: Commit**

```bash
git add be/src/product-groups/product-groups.service.ts be/src/product-groups/product-groups.service.spec.ts
git commit -m "fix: exclude disabled categories/products from the ordering flow"
```

---

### Task 9: Full backend verification

- [ ] **Step 1: Run the full test suite**

Run: `cd be && npm run test`
Expected: All product/catalog/product-groups suites pass. (Pre-existing unrelated failures elsewhere in the suite are not in scope — do not fix them here.)

- [ ] **Step 2: Lint**

Run: `cd be && npm run lint`
Expected: No new lint errors introduced by this change. `lint` auto-fixes and can touch unrelated files — check `git status` afterward and revert anything not part of this feature.

- [ ] **Step 3: Build**

Run: `cd be && npm run build`
Expected: Succeeds.

- [ ] **Step 4: Manual sanity check with a real Postgres instance (if available)**

Start the dev server (`npm run start:dev`) and, via Swagger (`http://localhost:3000/api/docs`) or `curl`:
- `PATCH /api/v1/products/:id` with `{"isAvailable": false}` → confirm the product disappears from `GET /api/v1/catalog/products` and `GET /api/v1/product-groups/:id/products`, but still appears in `GET /api/v1/catalog/admin/products`.
- `PATCH /api/v1/product-variants/:id` with `{"isActive": false}` → confirm `GET /api/v1/products/:id` still returns the variant with `"isActive": false` (not omitted).
- `PATCH /api/v1/catalog/admin/categories/:id` with `{"isActive": false}` → confirm the category disappears from `GET /api/v1/product-groups`, but still appears in `GET /api/v1/catalog/admin/categories`.
- Confirm `DELETE /api/v1/products/:id`, `DELETE /api/v1/product-variants/:id`, and `DELETE /api/v1/catalog/admin/categories/:id` all now return 404 (route no longer exists).

---

## Kiosk Tasks

### Task 10: Add `isActive` to `CatalogProductVariant`

**Files:**
- Modify: `kiosk/lib/features/catalog/data/models/product.dart`
- Test: `kiosk/test/features/catalog/data/models/product_test.dart`

- [ ] **Step 1: Write the failing test**

Modify `kiosk/test/features/catalog/data/models/product_test.dart` — update the two `fromJson` tests and the `copyWith` test to cover `isActive`:

```dart
    test('parses the ProductVariantDto shape (raw numeric price)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 3,
        'productId': 9,
        'name': 'Large',
        'price': 150.0,
        'isDefault': true,
        'isActive': true,
      });

      expect(variant.id, '3');
      expect(variant.name, 'Large');
      expect(variant.price, 150.0);
      expect(variant.isDefault, true);
      expect(variant.isActive, true);
    });

    test('parses the ProductVariantDetailsDto shape (displayPrice string)', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 5,
        'name': 'Venti',
        'displayPrice': '175.00',
        'isDefault': false,
        'isActive': false,
      });

      expect(variant.id, '5');
      expect(variant.name, 'Venti');
      expect(variant.price, 175.0);
      expect(variant.isDefault, false);
      expect(variant.isActive, false);
    });

    test('defaults isActive to true when the backend omits it', () {
      final variant = CatalogProductVariant.fromJson({
        'id': 5,
        'name': 'Venti',
        'displayPrice': '175.00',
        'isDefault': false,
      });

      expect(variant.isActive, true);
    });
```

```dart
  group('CatalogProductVariant.copyWith', () {
    test('overrides only the given fields', () {
      const original = CatalogProductVariant(
        id: '1',
        name: 'Regular',
        price: 100,
        isDefault: false,
        isActive: true,
      );

      final updated = original.copyWith(price: 120, isDefault: true, isActive: false);

      expect(updated.id, '1');
      expect(updated.name, 'Regular');
      expect(updated.price, 120);
      expect(updated.isDefault, true);
      expect(updated.isActive, false);
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd kiosk && fvm flutter test test/features/catalog/data/models/product_test.dart`
Expected: FAIL — `isActive` doesn't exist on `CatalogProductVariant` yet, and other constructor calls in the file are missing the new required-ish param.

- [ ] **Step 3: Add `isActive` to `CatalogProductVariant`**

Modify `kiosk/lib/features/catalog/data/models/product.dart` (lines 17-53):

```dart
class CatalogProductVariant {
  const CatalogProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double price;
  final bool isDefault;
  final bool isActive;

  factory CatalogProductVariant.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['displayPrice'];
    return CatalogProductVariant(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: double.parse(rawPrice.toString()),
      isDefault: json['isDefault'] as bool,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  CatalogProductVariant copyWith({
    String? id,
    String? name,
    double? price,
    bool? isDefault,
    bool? isActive,
  }) {
    return CatalogProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd kiosk && fvm flutter test test/features/catalog/data/models/product_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/catalog/data/models/product.dart kiosk/test/features/catalog/data/models/product_test.dart
git commit -m "feat: add isActive to CatalogProductVariant"
```

---

### Task 11: `CatalogRepository` — toggle methods instead of delete methods

**Files:**
- Modify: `kiosk/lib/features/catalog/data/catalog_repository.dart`

- [ ] **Step 1: Remove the three delete methods, add the replacements**

Modify `kiosk/lib/features/catalog/data/catalog_repository.dart`:

Remove `deleteCategory` (lines 75-77):
```dart
  Future<void> deleteCategory(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/catalog/admin/categories/$id');
  }
```

Remove `deleteProduct` (lines 140-142):
```dart
  Future<void> deleteProduct(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/products/$id');
  }
```

Remove `deleteVariant` (lines 183-185):
```dart
  Future<void> deleteVariant(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/product-variants/$id');
  }
```

Add `fetchAllProductsAdmin`, right after `fetchProducts` (which stays unchanged):

```dart
  Future<List<CatalogProduct>> fetchAllProductsAdmin({String? categoryId, String? search}) async {
    final response = await _secureClient.get<dynamic>(
      '/api/v1/catalog/admin/products',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (search != null) 'search': search,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogProduct.fromJson(json as Map<String, dynamic>))
        .toList();
  }
```

Add `updateProductAvailability`, right after `updateProduct`:

```dart
  Future<void> updateProductAvailability(String id, bool isAvailable) async {
    await _secureClient.patch<dynamic>(
      '/api/v1/products/$id',
      data: {'isAvailable': isAvailable},
    );
  }
```

Change `updateVariant`'s signature to accept `isActive` (replacing the old body):

```dart
  Future<void> updateVariant({
    required String id,
    required String name,
    required double price,
    required bool isDefault,
    required bool isActive,
  }) async {
    await _secureClient.patch<dynamic>(
      '/api/v1/product-variants/$id',
      data: {'name': name, 'price': price, 'isDefault': isDefault, 'isActive': isActive},
    );
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/data/catalog_repository.dart`
Expected: Errors at every call site of the removed/changed methods (notifiers, dialogs) — this is expected; those are fixed in the following tasks. Confirm the errors are only about call sites, not syntax in this file.

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/data/catalog_repository.dart
git commit -m "feat: replace CatalogRepository delete methods with enable/disable toggles"
```

---

### Task 12: `CatalogCategoriesNotifier` — `toggleActive` instead of `delete`

**Files:**
- Modify: `kiosk/lib/features/catalog/state/catalog_categories_notifier.dart`

- [ ] **Step 1: Replace `delete` with `toggleActive`**

Modify `kiosk/lib/features/catalog/state/catalog_categories_notifier.dart` (lines 52-56):

```dart
  Future<CatalogCategory> toggleActive(CatalogCategory category) async {
    final repo = ref.read(catalogRepositoryProvider);
    final result = await repo.updateCategory(
      category.id,
      category.name,
      category.description,
      !category.isActive,
    );
    await refresh();
    return result;
  }
```

Also rename the `deleteAction` mutation to `toggleActiveAction` (line 15):

```dart
  static final toggleActiveAction = Mutation<CatalogCategory>();
```

- [ ] **Step 2: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/state/catalog_categories_notifier.dart`
Expected: No errors in this file (call sites in `categories_tab.dart` are fixed in Task 14).

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/state/catalog_categories_notifier.dart
git commit -m "feat: replace CatalogCategoriesNotifier.delete with toggleActive"
```

---

### Task 13: `CatalogProductsNotifier` — `toggleAvailability` instead of `delete`, disable instead of remove for variants

**Files:**
- Modify: `kiosk/lib/features/catalog/state/catalog_products_notifier.dart`

- [ ] **Step 1: Switch the admin grid to the admin-inclusive fetch**

Modify `kiosk/lib/features/catalog/state/catalog_products_notifier.dart` — `build()` (lines 35-39) and `getResults()` (lines 41-54):

```dart
  @override
  Future<CatalogProductsData> build() async {
    final products = await ref.watch(catalogRepositoryProvider).fetchAllProductsAdmin();
    return CatalogProductsData(products: products);
  }

  Future<void> getResults({String? categoryId, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final products = await ref.read(catalogRepositoryProvider).fetchAllProductsAdmin(
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
```

(This notifier only backs the admin `CatalogGridScreen` — the customer ordering flow uses the separate `features/sales` stack and is untouched.)

- [ ] **Step 2: Replace the variant "delete" branch in `save()` with "disable"**

Modify `save()` (lines 56-112) — the removed-variant loop (currently lines 104-106):

```dart
    for (final removedId in existingIds.difference(incomingIds)) {
      final removed = existingVariants.firstWhere((v) => v.id == removedId);
      await repo.updateVariant(
        id: removed.id,
        name: removed.name,
        price: removed.price,
        isDefault: false,
        isActive: false,
      );
    }
```

This requires the full existing variant list (not just the id set) to be available at that point. Change the two lines above it (currently lines 81-84) from:

```dart
    final existingIds = draft.id.isEmpty
        ? const <String>{}
        : (await repo.fetchProductVariants(productId)).map((v) => v.id).toSet();
    final incomingIds = variants.where((v) => v.id.isNotEmpty).map((v) => v.id).toSet();
```

to:

```dart
    final existingVariants = draft.id.isEmpty
        ? const <CatalogProductVariant>[]
        : await repo.fetchProductVariants(productId);
    final existingIds = existingVariants.map((v) => v.id).toSet();
    final incomingIds = variants.where((v) => v.id.isNotEmpty).map((v) => v.id).toSet();
```

Also update every `create`/`update` call inside the `for (final variant in variants)` loop (lines 86-102) to pass `isActive: variant.isActive` for `updateVariant`:

```dart
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
          isActive: variant.isActive,
        );
      }
    }
```

- [ ] **Step 3: Replace `delete` with `toggleAvailability`**

Modify the `delete` method (lines 114-119):

```dart
  Future<void> toggleAvailability(CatalogProduct product) async {
    await ref.read(catalogRepositoryProvider).updateProductAvailability(
          product.id,
          !product.isAvailable,
        );
    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);
  }
```

Rename the `deleteAction` mutation (line 33) to `toggleAvailabilityAction`:

```dart
  static final toggleAvailabilityAction = Mutation<void>();
```

- [ ] **Step 4: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/state/catalog_products_notifier.dart`
Expected: No errors in this file.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/catalog/state/catalog_products_notifier.dart
git commit -m "feat: replace product delete with availability toggle; disable removed variants instead of deleting"
```

---

### Task 14: `categories_tab.dart` — Disable/Enable instead of Delete

**Files:**
- Modify: `kiosk/lib/features/catalog/view/categories_tab.dart`

- [ ] **Step 1: Replace the `_ActionMenu` delete item with a toggle item**

Modify `kiosk/lib/features/catalog/view/categories_tab.dart` (lines 326-376):

```dart
class _ActionMenu extends ConsumerWidget {
  const _ActionMenu({required this.category});

  final CatalogCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CategoryAction>(
      onSelected: (action) async {
        switch (action) {
          case _CategoryAction.edit:
            await showSaveCategoryDialog(context, category: category);
          case _CategoryAction.toggleActive:
            await ref.read(catalogCategoriesProvider.notifier).toggleActive(category);
        }
      },
      icon: Icon(
        Icons.more_vert_rounded,
        size: context.responsive.value(kiosk: 20.0, tablet: 18.0, phone: 16.0),
        color: POSColors.iconSubtle,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _CategoryAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: ColorSet.primary),
              Gap(12),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CategoryAction.toggleActive,
          child: Row(
            children: [
              Icon(
                category.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                size: 18,
                color: category.isActive ? ColorSet.danger : ColorSet.success,
              ),
              const Gap(12),
              Text(
                category.isActive ? 'Disable' : 'Enable',
                style: TextStyle(
                  color: category.isActive ? ColorSet.danger : ColorSet.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _CategoryAction { edit, toggleActive }
```

(`_ActionMenu` changes from `StatelessWidget` to `ConsumerWidget` since it now reads the provider directly instead of opening a dialog. Check the file's import list already includes `hooks_riverpod/hooks_riverpod.dart` for `ConsumerWidget` — it does, since the file already uses `HookConsumerWidget` elsewhere.)

- [ ] **Step 2: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/categories_tab.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/view/categories_tab.dart
git commit -m "feat: replace category delete action with disable/enable toggle"
```

---

### Task 15: Remove `DeleteCategoryDialog`

**Files:**
- Modify: `kiosk/lib/features/catalog/view/category_dialogs.dart`

- [ ] **Step 1: Delete the dialog and its launcher function**

Modify `kiosk/lib/features/catalog/view/category_dialogs.dart` — remove `showDeleteCategoryDialog` (lines 29-34) and the entire `DeleteCategoryDialog` class (lines 188-313). Nothing else in the file references them after Task 14.

- [ ] **Step 2: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/category_dialogs.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/view/category_dialogs.dart
git commit -m "chore: remove DeleteCategoryDialog, no longer reachable"
```

---

### Task 16: `product_dialogs.dart` — disable toggle for existing variant rows, remove `DeleteProductDialog`

**Files:**
- Modify: `kiosk/lib/features/catalog/view/product_dialogs.dart`

- [ ] **Step 1: Add `isActive` to `_VariantRow`**

Modify `_VariantRow` (lines 336-373):

```dart
class _VariantRow {
  _VariantRow({
    required this.id,
    required this.nameController,
    required this.priceController,
    required this.isDefault,
    required this.isActive,
  }) : nameFocusNode = FocusNode();

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final FocusNode nameFocusNode;
  bool isDefault;
  bool isActive;

  factory _VariantRow.blank({required bool isDefault}) {
    return _VariantRow(
      id: '',
      nameController: TextEditingController(),
      priceController: TextEditingController(),
      isDefault: isDefault,
      isActive: true,
    );
  }

  factory _VariantRow.fromVariant(CatalogProductVariant variant) {
    return _VariantRow(
      id: variant.id,
      nameController: TextEditingController(text: variant.name),
      priceController: TextEditingController(text: variant.price.toStringAsFixed(2)),
      isDefault: variant.isDefault,
      isActive: variant.isActive,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    nameFocusNode.dispose();
  }
}
```

- [ ] **Step 2: Update validation to only require an active variant, but still check all names for duplicates**

Modify `_validateVariantRows` (lines 375-392):

```dart
String? _validateVariantRows(List<_VariantRow> rows) {
  if (rows.where((r) => r.isActive).isEmpty) return 'Add at least one enabled variant.';
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

- [ ] **Step 3: Replace row removal with row disabling in `_VariantsSection`**

Modify `_VariantsSection` (lines 394-465) — the `addRow`/`removeRow` closures and the `for` loop building `_VariantRowField`:

```dart
    void addRow() {
      rows.value = [...rows.value, _VariantRow.blank(isDefault: rows.value.isEmpty)];
    }

    void removeUnsavedRow(_VariantRow row) {
      final wasDefault = row.isDefault;
      row.dispose();
      final updated = rows.value.where((r) => r != row).toList();
      if (wasDefault && updated.isNotEmpty) {
        updated.first.isDefault = true;
      }
      rows.value = updated;
    }

    void toggleActive(_VariantRow row) {
      row.isActive = !row.isActive;
      if (!row.isActive && row.isDefault) {
        row.isDefault = false;
        final firstActive = rows.value.where((r) => r.isActive && r != row);
        if (firstActive.isNotEmpty) firstActive.first.isDefault = true;
      }
      rows.value = [...rows.value];
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
            onRemove: row.id.isEmpty ? () => removeUnsavedRow(row) : null,
            onToggleActive: () => toggleActive(row),
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
```

(`setDefault` is unchanged from the existing file — only `removeRow`/`addRow` are touched, and a new `toggleActive` closure is added. `onRemove` is now only ever non-null for unsaved rows — an existing/persisted row, identified by a non-empty `id`, always gets `onRemove: null` and instead exposes the new toggle.)

- [ ] **Step 4: Add the disable/enable toggle to `_VariantRowField`, keep remove for unsaved rows only**

Modify `_VariantRowField` (lines 467-555) — add `onToggleActive` to the constructor, and replace the trailing two `IconButton`s:

```dart
class _VariantRowField extends StatelessWidget {
  const _VariantRowField({
    required this.row,
    required this.existingNames,
    required this.onSetDefault,
    required this.onRemove,
    required this.onToggleActive,
  });

  final _VariantRow row;
  final List<String> existingNames;
  final VoidCallback onSetDefault;
  final VoidCallback? onRemove;
  final VoidCallback onToggleActive;
```

Replace the final two `IconButton`s at the end of `build` (lines 536-552) with:

```dart
        const Gap(4),
        IconButton(
          onPressed: row.isActive ? onSetDefault : null,
          icon: Icon(
            row.isDefault ? Icons.star_rounded : Icons.star_border_rounded,
            color: row.isDefault
                ? ColorSet.secondary
                : (row.isActive ? POSColors.iconSubtle : POSColors.textDisabled),
          ),
          tooltip: 'Default variant',
        ),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: ColorSet.danger),
            tooltip: 'Remove variant',
          )
        else
          IconButton(
            onPressed: onToggleActive,
            icon: Icon(
              row.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: row.isActive ? POSColors.iconSubtle : ColorSet.danger,
            ),
            tooltip: row.isActive ? 'Disable variant' : 'Enable variant',
          ),
```

Also wrap the row's name/price fields with a muted opacity when disabled — wrap the outer `Row` (the widget returned by `build`, currently starting at `return Row(`) with an `Opacity`:

```dart
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Opacity(
      opacity: row.isActive ? 1.0 : 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing children unchanged...
        ],
      ),
    );
  }
```

(Keep the existing children list exactly as-is inside this new `Opacity`/`Row` wrapper — only the two trailing `IconButton`s and the wrapping widget change, per the steps above.)

- [ ] **Step 5: Remove `DeleteProductDialog` and its launcher**

Delete `showDeleteProductDialog` (lines 557-562) and the entire `DeleteProductDialog` class (lines 564-687).

- [ ] **Step 6: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/product_dialogs.dart`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add kiosk/lib/features/catalog/view/product_dialogs.dart
git commit -m "feat: disable existing variant rows instead of deleting them; remove DeleteProductDialog"
```

---

### Task 17: `catalog_grid_screen.dart` — toggle instead of delete, disabled badge

**Files:**
- Modify: `kiosk/lib/features/catalog/view/catalog_grid_screen.dart`

- [ ] **Step 1: Replace the delete icon button with a toggle**

Modify `catalog_grid_screen.dart` around lines 596-610 — replace the trash `IconButton`:

```dart
                          Gap(r.value(kiosk: 6, tablet: 5, phone: 4)),
                          IconButton(
                            onPressed: () => ref
                                .read(catalogProductsProvider.notifier)
                                .toggleAvailability(product),
                            icon: Icon(
                              product.isAvailable
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: r.value(kiosk: 20, tablet: 18, phone: 16),
                              color: product.isAvailable ? ColorSet.danger : ColorSet.success,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: (product.isAvailable
                                      ? ColorSet.danger
                                      : ColorSet.success)
                                  .withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(POSRadius.md),
                              ),
                            ),
                          ),
```

(This requires the surrounding widget to have access to `ref` — confirm it's already a `ConsumerWidget`/`HookConsumerWidget` build method with `WidgetRef ref` in scope; the file already calls `showSaveProductDialog(context, product: product)` a few lines above using the same `context`, and per the class structure this card widget receives `ref` from its parent build method.)

- [ ] **Step 2: Add a "Disabled" badge and dim the card when unavailable**

Find the card's image/badge area (around lines 540-550, the `_CategoryBadge` overlay) and add a sibling badge when the product is disabled:

```dart
                  _ProductImage(imageUrl: product.imageUrl, categoryName: product.category?.name),
                  // Category badge overlay
                  if (product.category != null)
                    Positioned(
                      left: r.value(kiosk: 8, tablet: 7, phone: 6),
                      bottom: r.value(kiosk: 8, tablet: 7, phone: 6),
                      child: _CategoryBadge(name: product.category!.name),
                    ),
                  if (!product.isAvailable)
                    Positioned(
                      right: r.value(kiosk: 8, tablet: 7, phone: 6),
                      top: r.value(kiosk: 8, tablet: 7, phone: 6),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.value(kiosk: 8, tablet: 7, phone: 6),
                          vertical: r.value(kiosk: 3, tablet: 3, phone: 2),
                        ),
                        decoration: BoxDecoration(
                          color: ColorSet.danger,
                          borderRadius: BorderRadius.circular(POSRadius.sm),
                        ),
                        child: Text(
                          'Disabled',
                          style: TextStyle(
                            fontSize: r.value(kiosk: 10, tablet: 9, phone: 8),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
```

Wrap the outer card container (the widget that currently holds the whole `_ProductCard` layout) with an `Opacity` when disabled, matching the pattern used for variant rows in Task 16 — wrap at the same level `_ProductImage`'s parent `Stack`/`Column` is built, applying `opacity: product.isAvailable ? 1.0 : 0.6` to the outermost returned widget of `_ProductCard`'s `build` method.

- [ ] **Step 3: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/catalog/view/catalog_grid_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/catalog/view/catalog_grid_screen.dart
git commit -m "feat: replace product delete button with disable/enable toggle, show Disabled badge"
```

---

### Task 18: Filter disabled variants out of the ordering flow

**Files:**
- Modify: `kiosk/lib/data/backend_api/schemas/product_variant_details_dto.dart`
- Modify: `kiosk/lib/features/sales/repositories/product_repository.dart`

- [ ] **Step 1: Add `isActive` to the wire schema**

Modify `kiosk/lib/data/backend_api/schemas/product_variant_details_dto.dart`:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'product_variant_details_dto.mapper.dart';

@MappableClass()
class ProductVariantDetailsDto with ProductVariantDetailsDtoMappable {
  const ProductVariantDetailsDto({
    required this.id,
    required this.name,
    required this.displayPrice,
    required this.isDefault,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String displayPrice;
  final bool isDefault;
  final bool isActive;

  static const fromJson = ProductVariantDetailsDtoMapper.fromJson;
}
```

- [ ] **Step 2: Regenerate the mapper**

Run: `cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `product_variant_details_dto.mapper.dart` is regenerated with the new `isActive` field, no errors.

- [ ] **Step 3: Filter to active variants when building the ordering-facing `Product`**

Modify `kiosk/lib/features/sales/repositories/product_repository.dart` — replace `_productFromDetailsDto` (lines 70-81):

```dart
  Product _productFromDetailsDto(ProductDetailsDto dto) {
    final activeVariants = dto.variants.where((v) => v.isActive).toList();
    final defaultStillActive =
        activeVariants.any((v) => v.id == dto.defaultVariantId);
    final resolvedDefaultId = defaultStillActive
        ? (dto.defaultVariantId ?? 0)
        : (activeVariants.isNotEmpty ? activeVariants.first.id : 0);

    return Product(
      categoryName: dto.categoryName ?? '',
      id: dto.id,
      name: dto.name,
      image: dto.imageUrl ?? '',
      price: Decimal.parse(dto.displayPrice),
      modifierGroups: dto.modifierGroups.map(_modifierGroupFromDto).toIList(),
      variants: activeVariants.map(_productVariantFromDto).toIList(),
      defaultVariantId: resolvedDefaultId,
    );
  }
```

(A disabled default variant falls back to the first remaining active variant instead of leaving `defaultVariantId` pointing at something no longer in the list.)

- [ ] **Step 4: Verify it compiles**

Run: `cd kiosk && fvm dart analyze lib/features/sales/repositories/product_repository.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/data/backend_api/schemas/product_variant_details_dto.dart kiosk/lib/data/backend_api/schemas/product_variant_details_dto.mapper.dart kiosk/lib/features/sales/repositories/product_repository.dart
git commit -m "feat: hide disabled variants from the ordering flow, fall back default selection"
```

---

### Task 19: Full kiosk verification

- [ ] **Step 1: Analyze the whole project**

Run: `cd kiosk && fvm dart analyze`
Expected: No errors. Warnings pre-existing and unrelated to this change are out of scope.

- [ ] **Step 2: Run the test suite**

Run: `cd kiosk && fvm flutter test`
Expected: All tests pass, including the updated `product_test.dart`.

- [ ] **Step 3: Build**

Run: `cd kiosk && fvm flutter build windows`
Expected: Succeeds.

- [ ] **Step 4: Manual verification in the running app**

With the backend from Task 9 running:
1. Open the admin "Manage Products" screen, disable a product. Confirm it stays visible (greyed, "Disabled" badge) in this screen.
2. Open the real order-taking screen (`Ordering`/POS flow). Confirm the disabled product no longer appears.
3. Re-enable the product from the admin screen. Confirm it reappears in the ordering flow.
4. Repeat steps 1-3 for a category (Disable/Enable in the categories tab's action menu).
5. Edit a multi-variant product, disable one variant (toggle its visibility icon, not remove it), save. Confirm: the variant still appears in the edit dialog (greyed out) on reopen; the ordering flow no longer offers that variant as a choice for the product.
6. Confirm there is no "Delete" affordance anywhere in the categories tab, product grid, or product edit dialog.

---

## Self-review notes

- **Spec coverage:** Every section of `docs/superpowers/specs/2026-07-06-product-category-enable-disable-design.md` maps to a task: categories (Task 6), products (Tasks 1, 4, 7), variants (Tasks 2, 3, 5), admin visibility gap (Task 7), ordering-flow exclusion (Tasks 8, 18), kiosk dialogs/screens (Tasks 14-17), variant row toggle UX (Task 16). The spec's "audit the ordering feature's read paths" open item is resolved concretely by Task 8 (found: `ProductGroupsService`, not `CatalogService`, backs the real ordering flow, and had zero filtering).
- **Type/name consistency check:** `toggleActive(CatalogCategory)` (Task 12) is called the same way in Task 14. `toggleAvailability(CatalogProduct)` (Task 13) is called the same way in Task 17. `updateVariant(..., isActive:)` (Task 11) is called with that exact parameter name in Task 13. `CatalogProductVariant.isActive` (Task 10) is read in Tasks 13, 16, 17. `ProductVariantDetailsDto.isActive` (Task 18) matches the backend's `isActive` field name added in Task 3 — no snake_case/camelCase mismatch since `dart_mappable`'s default JSON key casing is confirmed by the existing `isDefault` field working the same way today.
