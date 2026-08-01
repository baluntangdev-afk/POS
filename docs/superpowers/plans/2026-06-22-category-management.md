# Category Management (Admin/Supervisor) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add create/update/delete category functionality for admin and supervisor users, with modal dialogs in the kiosk's Catalog Management → Categories tab.

**Architecture:** New `CatalogAdminController` at `/api/v1/catalog/admin/categories[/:id]` — GET is JWT-only (any authenticated user), mutations are JWT + `AdminOrSupervisorGuard`. Frontend adds `Mutation` actions to `CatalogCategoriesNotifier` and wires `SaveCategoryDialog` / `DeleteCategoryDialog` into `CategoriesTab`. Role is added to the JWT payload and propagated to `Auth` entity.

**Tech Stack:** NestJS (TypeORM, Passport JWT, class-validator), Flutter (hooks_riverpod experimental Mutation, dart_mappable, flutter_hooks), PostgreSQL

---

## File Map

### Backend — Modified
| File | Change |
|---|---|
| `be/src/auth/dto/jwt-payload.dto.ts` | Add `role: string` |
| `be/src/auth/dto/me.dto.ts` | Add optional `role?: string` |
| `be/src/auth/strategies/jwt.strategy.ts` | Map `payload.role`, default `'user'` if absent |
| `be/src/auth/auth.service.ts` | Include `user.role` in `buildTokens()` |
| `be/src/catalog/catalog.service.ts` | Inject `ProductGroup` repo; add 4 admin methods |
| `be/src/catalog/catalog.module.ts` | Register `TypeOrmModule.forFeature([ProductGroup])` + new controller |

### Backend — Created
| File | Purpose |
|---|---|
| `be/src/auth/guards/admin-or-supervisor.guard.ts` | Role gate for admin/supervisor |
| `be/src/auth/guards/admin-or-supervisor.guard.spec.ts` | Guard unit tests |
| `be/src/catalog/dto/create-category.dto.ts` | Validated input DTO for POST |
| `be/src/catalog/dto/update-category.dto.ts` | Partial input DTO for PATCH |
| `be/src/catalog/catalog-admin.controller.ts` | CRUD controller (4 routes) |
| `be/src/catalog/catalog.service.spec.ts` | Service unit tests for admin methods |

### Frontend — Modified
| File | Change |
|---|---|
| `kiosk/lib/features/auth/entities/auth.dart` | Add `role` field (default `'user'`) |
| `kiosk/lib/features/auth/repositories/auth_repository.dart` | Map `UserDto.role` → `Auth.role` |
| `kiosk/lib/features/catalog/data/models/category.dart` | Add `copyWith()` + `CatalogCategory.draft()` |
| `kiosk/lib/features/catalog/data/catalog_repository.dart` | Inject `secureApiClientProvider`; add 4 admin methods |
| `kiosk/lib/features/catalog/state/catalog_categories_notifier.dart` | Add `saveAction`, `deleteAction`, `save()`, `delete()`; switch `build()` to admin endpoint |
| `kiosk/lib/features/catalog/view/categories_tab.dart` | Wire Add/Edit/Delete buttons; role-gate action buttons |

### Frontend — Created
| File | Purpose |
|---|---|
| `kiosk/lib/features/catalog/view/category_dialogs.dart` | `SaveCategoryDialog` + `DeleteCategoryDialog` |

---

### Task 1: Update JWT Payload to Include Role

**Files:**
- Modify: `be/src/auth/dto/jwt-payload.dto.ts`
- Modify: `be/src/auth/dto/me.dto.ts`
- Modify: `be/src/auth/strategies/jwt.strategy.ts`
- Modify: `be/src/auth/auth.service.ts`

- [ ] **Step 1: Update `JwtPayloadDto`**

Replace the entire contents of `be/src/auth/dto/jwt-payload.dto.ts`:

```ts
export interface JwtPayloadDto {
  sub: number;
  email: string;
  type: 'access' | 'refresh';
  systemAdmin: boolean;
  isPinChanged: boolean;
  role: string;
}
```

- [ ] **Step 2: Update `MeDto`**

Replace the entire contents of `be/src/auth/dto/me.dto.ts`:

```ts
import { ApiProperty } from '@nestjs/swagger';

export class MeDto {
  @ApiProperty({ description: 'User ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Email', example: 'test@example.com' })
  email: string;

  @ApiProperty({ description: 'System admin', example: true })
  systemAdmin: boolean;

  @ApiProperty({ description: 'PIN changed', example: false })
  isPinChanged: boolean;

  @ApiProperty({ description: 'User role', example: 'admin' })
  role?: string;
}
```

- [ ] **Step 3: Update `JwtStrategy.validate()` to map role**

In `be/src/auth/strategies/jwt.strategy.ts`, replace the `validate` method:

```ts
validate(payload: JwtPayloadDto): MeDto {
  return {
    id: payload.sub,
    email: payload.email,
    systemAdmin: payload.systemAdmin,
    isPinChanged: payload.isPinChanged,
    role: payload.role ?? 'user',
  };
}
```

- [ ] **Step 4: Include `user.role` in `buildTokens()`**

In `be/src/auth/auth.service.ts`, update the `buildTokens` private method — add `role: user.role` to both `accessPayload` and `refreshPayload`:

```ts
private buildTokens(user: User): AuthTokensDto {
  const accessPayload: JwtPayloadDto = {
    sub: user.id,
    email: user.email,
    type: 'access',
    systemAdmin: user.systemAdmin,
    isPinChanged: user.isPinChanged,
    role: user.role,
  };
  const refreshPayload: JwtPayloadDto = {
    sub: user.id,
    email: user.email,
    type: 'refresh',
    systemAdmin: user.systemAdmin,
    isPinChanged: user.isPinChanged,
    role: user.role,
  };

  const accessToken = this.jwtService.sign(accessPayload, {
    secret: this.appConfig.jwtSecret,
    expiresIn: this.appConfig.jwtExpiresIn,
  });

  const refreshToken = this.jwtService.sign(refreshPayload, {
    secret: this.appConfig.jwtRefreshSecret,
    expiresIn: this.appConfig.jwtRefreshExpiresIn,
  });

  return {
    accessToken,
    refreshToken,
    expiresIn: this.appConfig.jwtExpiresIn,
    isPinChanged: user.isPinChanged,
    id: user.id,
  };
}
```

- [ ] **Step 5: Verify TypeScript compiles with no errors**

```bash
cd be && npm run build 2>&1 | tail -20
```

Expected: no TypeScript errors. Fix any before proceeding.

- [ ] **Step 6: Commit**

```bash
git add be/src/auth/dto/jwt-payload.dto.ts be/src/auth/dto/me.dto.ts be/src/auth/strategies/jwt.strategy.ts be/src/auth/auth.service.ts
git commit -m "feat(auth): include user role in JWT payload"
```

---

### Task 2: Create `AdminOrSupervisorGuard`

**Files:**
- Create: `be/src/auth/guards/admin-or-supervisor.guard.ts`
- Create: `be/src/auth/guards/admin-or-supervisor.guard.spec.ts`

- [ ] **Step 1: Write failing tests**

Create `be/src/auth/guards/admin-or-supervisor.guard.spec.ts`:

```ts
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { AdminOrSupervisorGuard } from './admin-or-supervisor.guard';

function makeContext(role: string | undefined): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ user: role !== undefined ? { role } : {} }),
    }),
  } as unknown as ExecutionContext;
}

describe('AdminOrSupervisorGuard', () => {
  let guard: AdminOrSupervisorGuard;

  beforeEach(() => {
    guard = new AdminOrSupervisorGuard();
  });

  it('allows admin role', () => {
    expect(guard.canActivate(makeContext('admin'))).toBe(true);
  });

  it('allows supervisor role', () => {
    expect(guard.canActivate(makeContext('supervisor'))).toBe(true);
  });

  it('blocks user role', () => {
    expect(() => guard.canActivate(makeContext('user'))).toThrow(ForbiddenException);
  });

  it('blocks missing role', () => {
    expect(() => guard.canActivate(makeContext(undefined))).toThrow(ForbiddenException);
  });
});
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd be && npx jest --testPathPattern=admin-or-supervisor.guard.spec --no-coverage 2>&1 | tail -10
```

Expected: `Cannot find module './admin-or-supervisor.guard'`

- [ ] **Step 3: Implement the guard**

Create `be/src/auth/guards/admin-or-supervisor.guard.ts`:

```ts
import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import type { MeDto } from '../dto/me.dto';

@Injectable()
export class AdminOrSupervisorGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: MeDto }>();
    const role = request.user?.role;

    if (role !== 'admin' && role !== 'supervisor') {
      throw new ForbiddenException('Admin or supervisor access required');
    }

    return true;
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd be && npx jest --testPathPattern=admin-or-supervisor.guard.spec --no-coverage 2>&1 | tail -10
```

Expected: `Tests: 4 passed, 4 total`

- [ ] **Step 5: Commit**

```bash
git add be/src/auth/guards/admin-or-supervisor.guard.ts be/src/auth/guards/admin-or-supervisor.guard.spec.ts
git commit -m "feat(auth): add AdminOrSupervisorGuard"
```

---

### Task 3: Create Category DTOs

**Files:**
- Create: `be/src/catalog/dto/create-category.dto.ts`
- Create: `be/src/catalog/dto/update-category.dto.ts`

- [ ] **Step 1: Create `CreateCategoryDto`**

Create `be/src/catalog/dto/create-category.dto.ts`:

```ts
import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateCategoryDto {
  @ApiProperty({ example: 'Beverages' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @ApiProperty({ example: 'Hot and cold drinks', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiProperty({ example: true, required: false, default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
```

- [ ] **Step 2: Create `UpdateCategoryDto`**

Create `be/src/catalog/dto/update-category.dto.ts`:

```ts
import { PartialType } from '@nestjs/swagger';
import { CreateCategoryDto } from './create-category.dto';

export class UpdateCategoryDto extends PartialType(CreateCategoryDto) {}
```

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd be && npm run build 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add be/src/catalog/dto/
git commit -m "feat(catalog): add CreateCategoryDto and UpdateCategoryDto"
```

---

### Task 4: Add Admin Methods to `CatalogService`

**Files:**
- Modify: `be/src/catalog/catalog.service.ts`
- Create: `be/src/catalog/catalog.service.spec.ts`

- [ ] **Step 1: Write failing tests**

Create `be/src/catalog/catalog.service.spec.ts`:

```ts
import { Test, TestingModule } from '@nestjs/testing';
import { getDataSourceToken, getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { CatalogService } from './catalog.service';
import { ProductGroup } from '../product-groups/entities/product-group.entity';
import { User } from '../users/entities/user.entity';
import { BaseStatus } from '../utils/shared-enums';

const mockDataSource = { query: jest.fn() };

const mockPgRepo = {
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  update: jest.fn(),
  softDelete: jest.fn(),
  manager: { query: jest.fn() },
};

const mockUser = { id: 1, role: 'admin' } as User;

describe('CatalogService (admin methods)', () => {
  let service: CatalogService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CatalogService,
        { provide: getDataSourceToken(), useValue: mockDataSource },
        { provide: getRepositoryToken(ProductGroup), useValue: mockPgRepo },
      ],
    }).compile();

    service = module.get<CatalogService>(CatalogService);
  });

  describe('createCategory', () => {
    it('saves a new ProductGroup and returns mapped response', async () => {
      const dto = { name: 'Beverages', description: 'Drinks', isActive: true };
      const saved = { id: 5, name: 'Beverages', description: 'Drinks', status: BaseStatus.ACTIVE };
      mockPgRepo.create.mockReturnValue(saved);
      mockPgRepo.save.mockResolvedValue(saved);

      const result = await service.createCategory(dto, mockUser);

      expect(mockPgRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'Beverages', status: BaseStatus.ACTIVE }),
      );
      expect(result).toMatchObject({ id: '5', name: 'Beverages', is_active: true, product_count: 0 });
    });
  });

  describe('updateCategory', () => {
    it('throws NotFoundException when category does not exist', async () => {
      mockPgRepo.findOne.mockResolvedValue(null);

      await expect(service.updateCategory(999, { name: 'X' }, mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('updates the category and returns mapped response', async () => {
      const existing = { id: 3, name: 'Old', description: null, status: BaseStatus.ACTIVE };
      const updated = { id: 3, name: 'New', description: null, status: BaseStatus.INACTIVE };
      mockPgRepo.findOne.mockResolvedValueOnce(existing).mockResolvedValueOnce(updated);
      mockPgRepo.update.mockResolvedValue(undefined);

      const result = await service.updateCategory(3, { name: 'New', isActive: false }, mockUser);

      expect(mockPgRepo.update).toHaveBeenCalled();
      expect(result).toMatchObject({ id: '3', name: 'New', is_active: false });
    });
  });

  describe('deleteCategory', () => {
    it('throws NotFoundException when category does not exist', async () => {
      mockPgRepo.findOne.mockResolvedValue(null);

      await expect(service.deleteCategory(999, mockUser)).rejects.toThrow(NotFoundException);
    });

    it('soft deletes an existing category', async () => {
      mockPgRepo.findOne.mockResolvedValue({ id: 2 });
      mockPgRepo.update.mockResolvedValue(undefined);
      mockPgRepo.softDelete.mockResolvedValue(undefined);

      const result = await service.deleteCategory(2, mockUser);

      expect(mockPgRepo.softDelete).toHaveBeenCalledWith(2);
      expect(result).toEqual({ message: 'Category deleted successfully' });
    });
  });
});
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd be && npx jest --testPathPattern=catalog.service.spec --no-coverage 2>&1 | tail -15
```

Expected: fails because `CatalogService` does not yet have the admin methods.

- [ ] **Step 3: Update `CatalogService` with injected repository and admin methods**

Replace the full contents of `be/src/catalog/catalog.service.ts`:

```ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { ProductGroup } from '../product-groups/entities/product-group.entity';
import { User } from '../users/entities/user.entity';
import { BaseStatus } from '../utils/shared-enums';
import { EntityHelper } from '../utils/entity.helper';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CatalogService {
  constructor(
    @InjectDataSource() private readonly dataSource: DataSource,
    @InjectRepository(ProductGroup)
    private readonly pgRepo: Repository<ProductGroup>,
  ) {}

  async getCategories(): Promise<unknown[]> {
    const rows = await this.dataSource.query<
      {
        id: string;
        name: string;
        description: string | null;
        is_active: boolean;
        product_count: string;
      }[]
    >(`
      SELECT
        pg.id::text,
        pg.name,
        pg.description,
        NULL::text                                                              AS image_url,
        0                                                                       AS sort_order,
        (pg.status = 'Active')                                                  AS is_active,
        COUNT(p.id) FILTER (WHERE p.is_available = true
                              AND p.status       = 'Active'
                              AND p.deleted_at   IS NULL)::int                  AS product_count
      FROM   product_groups pg
      LEFT   JOIN products p ON p.group_id   = pg.id
      WHERE  pg.status     = 'Active'
        AND  pg.deleted_at IS NULL
      GROUP  BY pg.id
      ORDER  BY pg.name ASC
    `);

    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      description: r.description,
      image_url: null,
      sort_order: 0,
      is_active: r.is_active,
      product_count: Number(r.product_count),
    }));
  }

  async getAllCategoriesForAdmin(): Promise<unknown[]> {
    const rows = await this.dataSource.query<
      {
        id: string;
        name: string;
        description: string | null;
        is_active: boolean;
        product_count: string;
      }[]
    >(`
      SELECT
        pg.id::text,
        pg.name,
        pg.description,
        NULL::text                                                              AS image_url,
        0                                                                       AS sort_order,
        (pg.status = 'Active')                                                  AS is_active,
        COUNT(p.id) FILTER (WHERE p.is_available = true
                              AND p.status       = 'Active'
                              AND p.deleted_at   IS NULL)::int                  AS product_count
      FROM   product_groups pg
      LEFT   JOIN products p ON p.group_id   = pg.id
      WHERE  pg.deleted_at IS NULL
      GROUP  BY pg.id
      ORDER  BY pg.name ASC
    `);

    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      description: r.description,
      image_url: null,
      sort_order: 0,
      is_active: r.is_active,
      product_count: Number(r.product_count),
    }));
  }

  async createCategory(dto: CreateCategoryDto, causer: User): Promise<unknown> {
    const entity = this.pgRepo.create({
      name: dto.name,
      description: dto.description ?? null,
      status: (dto.isActive ?? true) ? BaseStatus.ACTIVE : BaseStatus.INACTIVE,
      createdBy: causer,
      updatedBy: causer,
    });
    const result = await this.pgRepo.save(entity);
    return {
      id: result.id.toString(),
      name: result.name,
      description: result.description,
      image_url: null,
      sort_order: 0,
      is_active: result.status === BaseStatus.ACTIVE,
      product_count: 0,
    };
  }

  async updateCategory(id: number, dto: UpdateCategoryDto, causer: User): Promise<unknown> {
    const existing = await this.pgRepo.findOne({ where: { id } });
    if (!existing) throw new NotFoundException('Category not found');

    const update: Partial<ProductGroup> = { updatedBy: causer };
    if (dto.name !== undefined) update.name = dto.name;
    if (dto.description !== undefined) update.description = dto.description;
    if (dto.isActive !== undefined) {
      update.status = dto.isActive ? BaseStatus.ACTIVE : BaseStatus.INACTIVE;
    }

    await this.pgRepo.update(id, EntityHelper.toPartialEntity(update));
    const updated = await this.pgRepo.findOne({ where: { id } });

    return {
      id: updated!.id.toString(),
      name: updated!.name,
      description: updated!.description,
      image_url: null,
      sort_order: 0,
      is_active: updated!.status === BaseStatus.ACTIVE,
      product_count: 0,
    };
  }

  async deleteCategory(id: number, causer: User): Promise<{ message: string }> {
    const existing = await this.pgRepo.findOne({ where: { id } });
    if (!existing) throw new NotFoundException('Category not found');

    await this.pgRepo.update(id, EntityHelper.toPartialEntity({ deletedBy: causer }));
    await this.pgRepo.softDelete(id);
    return { message: 'Category deleted successfully' };
  }

  async getProducts(categoryId?: string, search?: string): Promise<unknown[]> {
    const conditions: string[] = [
      "p.status       = 'Active'",
      'p.is_available = true',
      'p.deleted_at   IS NULL',
    ];
    const params: unknown[] = [];

    if (categoryId) {
      params.push(categoryId);
      conditions.push(`p.group_id = $${params.length}::int`);
    }

    if (search) {
      params.push(`%${search}%`);
      conditions.push(`p.name ILIKE $${params.length}`);
    }

    const where = conditions.join(' AND ');

    const rows = await this.dataSource.query(
      `
      WITH modifier_data AS (
        SELECT
          pmg.product_id,
          pmg.sort_order AS group_sort,
          json_build_object(
            'id',             mg.id::text,
            'name',           mg.name,
            'selection_type', mg.selection_type,
            'is_required',    mg.is_required,
            'min_selections', mg.min_selection,
            'max_selections', mg.max_selection,
            'modifiers', COALESCE(
              (SELECT json_agg(
                json_build_object(
                  'id',               mo.id::text,
                  'name',             mo.name,
                  'price_adjustment', mo.price_add_on::text,
                  'is_available',     mo.is_available,
                  'sort_order',       mo.sort_order
                ) ORDER BY mo.sort_order
              )
              FROM modifier_options mo
              WHERE mo.modifier_group_id = mg.id
                AND mo.deleted_at        IS NULL
                AND mo.is_available      = true),
              '[]'::json
            )
          ) AS mg_json
        FROM product_modifier_groups pmg
        JOIN modifier_groups mg ON mg.id         = pmg.modifier_group_id
                                AND mg.deleted_at IS NULL
      )
      SELECT
        p.id::text,
        p.name,
        p.description,
        p.price::text  AS price,
        p.image_url,
        p.is_available,
        p.sort_order,
        CASE WHEN pg.id IS NULL THEN NULL
             ELSE json_build_object('id', pg.id::text, 'name', pg.name)
        END AS category,
        COALESCE(
          json_agg(md.mg_json ORDER BY md.group_sort)
            FILTER (WHERE md.mg_json IS NOT NULL),
          '[]'::json
        ) AS modifier_groups
      FROM  products p
      LEFT  JOIN product_groups  pg ON pg.id = p.group_id AND pg.deleted_at IS NULL
      LEFT  JOIN modifier_data   md ON md.product_id = p.id
      WHERE ${where}
      GROUP BY p.id, pg.id, pg.name
      ORDER BY p.sort_order ASC
      `,
      params,
    );

    return rows;
  }

  async getModifierGroups(): Promise<unknown[]> {
    const rows = await this.dataSource.query(`
      SELECT
        mg.id::text,
        mg.name,
        mg.description,
        mg.selection_type,
        mg.min_selection  AS min_selections,
        mg.max_selection  AS max_selections,
        mg.is_required,
        COALESCE(
          json_agg(
            json_build_object(
              'id',               mo.id::text,
              'name',             mo.name,
              'price_adjustment', mo.price_add_on::text,
              'is_available',     mo.is_available,
              'sort_order',       mo.sort_order
            ) ORDER BY mo.sort_order
          ) FILTER (WHERE mo.id IS NOT NULL AND mo.is_available = true),
          '[]'::json
        ) AS modifiers
      FROM   modifier_groups mg
      LEFT   JOIN modifier_options mo ON mo.modifier_group_id = mg.id
                                     AND mo.deleted_at        IS NULL
      WHERE  mg.deleted_at IS NULL
      GROUP  BY mg.id
      ORDER  BY mg.name ASC
    `);

    return rows;
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd be && npx jest --testPathPattern=catalog.service.spec --no-coverage 2>&1 | tail -15
```

Expected: `Tests: 5 passed, 5 total`

- [ ] **Step 5: Commit**

```bash
git add be/src/catalog/catalog.service.ts be/src/catalog/catalog.service.spec.ts
git commit -m "feat(catalog): add admin methods to CatalogService"
```

---

### Task 5: Create `CatalogAdminController` and Update `CatalogModule`

**Files:**
- Create: `be/src/catalog/catalog-admin.controller.ts`
- Modify: `be/src/catalog/catalog.module.ts`

- [ ] **Step 1: Create `CatalogAdminController`**

Create `be/src/catalog/catalog-admin.controller.ts`:

```ts
import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiParam, ApiOkResponse, ApiCreatedResponse } from '@nestjs/swagger';
import { CatalogService } from './catalog.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Catalog Admin')
@Controller('catalog/admin')
export class CatalogAdminController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('categories')
  @ApiOperation({ summary: 'List all categories including inactive (authenticated users)' })
  @ApiOkResponse({ description: 'All categories sorted by name.' })
  async getAllCategories(): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getAllCategoriesForAdmin();
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Post('categories')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Create a new category (admin/supervisor only)' })
  @ApiCreatedResponse({ description: 'Category created.' })
  async createCategory(
    @Body() dto: CreateCategoryDto,
    @CurrentUser() causer: User,
  ): Promise<{ success: boolean; data: unknown }> {
    try {
      const data = await this.catalogService.createCategory(dto, causer);
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Patch('categories/:id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Update a category (admin/supervisor only)' })
  @ApiParam({ name: 'id', description: 'Category ID', example: 1 })
  @ApiOkResponse({ description: 'Category updated.' })
  async updateCategory(
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
    @CurrentUser() causer: User,
  ): Promise<{ success: boolean; data: unknown }> {
    try {
      const data = await this.catalogService.updateCategory(+id, dto, causer);
      return { success: true, data };
    } catch (error) {
      if (error instanceof HttpException) throw error;
      const message = error instanceof Error ? error.message : 'Internal server error';
      const status =
        message === 'Category not found' ? HttpStatus.NOT_FOUND : HttpStatus.INTERNAL_SERVER_ERROR;
      throw new HttpException({ success: false, error: message }, status);
    }
  }

  @Delete('categories/:id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Delete a category (admin/supervisor only)' })
  @ApiParam({ name: 'id', description: 'Category ID', example: 1 })
  @ApiOkResponse({ description: 'Category deleted.' })
  async deleteCategory(
    @Param('id') id: string,
    @CurrentUser() causer: User,
  ): Promise<{ success: boolean; message: string }> {
    try {
      const result = await this.catalogService.deleteCategory(+id, causer);
      return { success: true, message: result.message };
    } catch (error) {
      if (error instanceof HttpException) throw error;
      const message = error instanceof Error ? error.message : 'Internal server error';
      const status =
        message === 'Category not found' ? HttpStatus.NOT_FOUND : HttpStatus.INTERNAL_SERVER_ERROR;
      throw new HttpException({ success: false, error: message }, status);
    }
  }
}
```

- [ ] **Step 2: Update `CatalogModule`**

Replace the full contents of `be/src/catalog/catalog.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CatalogController } from './catalog.controller';
import { CatalogAdminController } from './catalog-admin.controller';
import { CatalogService } from './catalog.service';
import { ProductGroup } from '../product-groups/entities/product-group.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ProductGroup])],
  controllers: [CatalogController, CatalogAdminController],
  providers: [CatalogService],
})
export class CatalogModule {}
```

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd be && npm run build 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 4: Start backend and smoke-test the new routes**

```bash
cd be && npm run start:dev
```

In a separate terminal:
```bash
# Should return 401 (JWT required — not public)
curl -s http://localhost:3000/api/v1/catalog/admin/categories | jq .

# Existing public endpoint must still work
curl -s http://localhost:3000/api/v1/catalog/categories | jq .status
```

Expected first: `{"statusCode":401,"message":"Unauthorized"}`.  
Expected second: `true` (public endpoint unaffected).

- [ ] **Step 5: Commit**

```bash
git add be/src/catalog/catalog-admin.controller.ts be/src/catalog/catalog.module.ts
git commit -m "feat(catalog): add CatalogAdminController with CRUD endpoints"
```

---

### Task 6: Update `Auth` Entity and `AuthRepository`

**Files:**
- Modify: `kiosk/lib/features/auth/entities/auth.dart`
- Modify: `kiosk/lib/features/auth/repositories/auth_repository.dart`

- [ ] **Step 1: Add `role` field to `Auth` entity**

Replace the full contents of `kiosk/lib/features/auth/entities/auth.dart`:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'auth.mapper.dart';

@MappableClass()
class Auth with AuthMappable {
  const Auth({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.suffix,
    this.isPinChanged = false,
    this.role = 'user',
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? suffix;
  final bool isPinChanged;
  final String role;

  bool get isAdminOrSupervisor => role == 'admin' || role == 'supervisor';

  String get fullName => [
    firstName.trim(),
    middleName?.trim(),
    lastName.trim(),
    suffix?.trim(),
  ].where((e) => e?.isNotEmpty ?? false).join(' ');
}
```

- [ ] **Step 2: Run `build_runner` to regenerate `.mapper.dart`**

```bash
cd kiosk && fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: `auth.mapper.dart` regenerated, no errors.

- [ ] **Step 3: Update `AuthRepository._authFromUserDto()` to map `role`**

In `kiosk/lib/features/auth/repositories/auth_repository.dart`, update `_authFromUserDto`:

```dart
Auth _authFromUserDto(UserDto dto) {
  return Auth(
    id: dto.id,
    username: dto.userId,
    firstName: dto.firstName,
    lastName: dto.lastName,
    middleName: dto.middleName,
    suffix: dto.suffix == 'None' ? null : dto.suffix,
    isPinChanged: dto.isPinChanged,
    role: dto.role,
  );
}
```

- [ ] **Step 4: Verify no analysis errors**

```bash
cd kiosk && fvm dart analyze lib/features/auth/ 2>&1 | tail -10
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add kiosk/lib/features/auth/entities/auth.dart kiosk/lib/features/auth/entities/auth.mapper.dart kiosk/lib/features/auth/repositories/auth_repository.dart
git commit -m "feat(auth): add role field to Auth entity"
```

---

### Task 7: Update `CatalogCategory` Model

**Files:**
- Modify: `kiosk/lib/features/catalog/data/models/category.dart`

- [ ] **Step 1: Add `copyWith` and `draft` to `CatalogCategory`**

Replace the full contents of `kiosk/lib/features/catalog/data/models/category.dart`:

```dart
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.productCount,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final int productCount;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
      productCount: json['product_count'] as int,
    );
  }

  factory CatalogCategory.draft() {
    return const CatalogCategory(
      id: '',
      name: '',
      description: null,
      imageUrl: null,
      sortOrder: 0,
      isActive: true,
      productCount: 0,
    );
  }

  CatalogCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    int? productCount,
  }) {
    return CatalogCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd kiosk && fvm dart analyze lib/features/catalog/data/models/ 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/data/models/category.dart
git commit -m "feat(catalog): add copyWith and draft() to CatalogCategory"
```

---

### Task 8: Update `CatalogRepository` with Admin CRUD Methods

**Files:**
- Modify: `kiosk/lib/features/catalog/data/catalog_repository.dart`

- [ ] **Step 1: Update `catalogRepositoryProvider` to inject both HTTP clients and add admin methods**

Replace the full contents of `kiosk/lib/features/catalog/data/catalog_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/api_clients.dart';
import 'models/category.dart';
import 'models/modifier_group.dart';
import 'models/product.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final openClient = ref.watch(openApiClientProvider);
  final secureClient = ref.watch(secureApiClientProvider);
  return CatalogRepository(openClient, secureClient);
});

class CatalogRepository {
  const CatalogRepository(this._openClient, this._secureClient);

  final Dio _openClient;
  final Dio _secureClient;

  Future<List<CatalogCategory>> fetchCategories() async {
    final response = await _openClient.get<dynamic>('/api/v1/catalog/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogCategory>> fetchAllCategoriesAdmin() async {
    final response = await _secureClient.get<dynamic>('/api/v1/catalog/admin/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CatalogCategory> createCategory(
    String name,
    String? description,
    bool isActive,
  ) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/catalog/admin/categories',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'isActive': isActive,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CatalogCategory.fromJson(data);
  }

  Future<CatalogCategory> updateCategory(
    String id,
    String name,
    String? description,
    bool isActive,
  ) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/catalog/admin/categories/$id',
      data: {
        'name': name,
        'description': description,
        'isActive': isActive,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CatalogCategory.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/catalog/admin/categories/$id');
  }

  Future<List<CatalogProduct>> fetchProducts({String? categoryId, String? search}) async {
    final response = await _openClient.get<dynamic>(
      '/api/v1/catalog/products',
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

  Future<List<CatalogModifierGroup>> fetchModifierGroups() async {
    final response = await _openClient.get<dynamic>('/api/v1/catalog/modifier-groups');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogModifierGroup.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd kiosk && fvm dart analyze lib/features/catalog/data/ 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/data/catalog_repository.dart
git commit -m "feat(catalog): add admin CRUD methods to CatalogRepository"
```

---

### Task 9: Update `CatalogCategoriesNotifier` with Mutations

**Files:**
- Modify: `kiosk/lib/features/catalog/state/catalog_categories_notifier.dart`

- [ ] **Step 1: Update the notifier**

Replace the full contents of `kiosk/lib/features/catalog/state/catalog_categories_notifier.dart`:

```dart
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/category.dart';

final catalogCategoriesProvider =
    AsyncNotifierProvider<CatalogCategoriesNotifier, List<CatalogCategory>>(
  CatalogCategoriesNotifier.new,
  name: 'catalogCategoriesProvider',
);

class CatalogCategoriesNotifier extends AsyncNotifier<List<CatalogCategory>> {
  static final saveAction = Mutation<CatalogCategory>();
  static final deleteAction = Mutation<bool>();

  @override
  Future<List<CatalogCategory>> build() {
    return ref.watch(catalogRepositoryProvider).fetchAllCategoriesAdmin();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).fetchAllCategoriesAdmin(),
    );
  }

  Future<CatalogCategory> save(CatalogCategory category) async {
    final repo = ref.read(catalogRepositoryProvider);
    final CatalogCategory result;

    if (category.id.isEmpty) {
      result = await repo.createCategory(
        category.name,
        category.description,
        category.isActive,
      );
    } else {
      result = await repo.updateCategory(
        category.id,
        category.name,
        category.description,
        category.isActive,
      );
    }

    await refresh();
    return result;
  }

  Future<bool> delete(String id) async {
    await ref.read(catalogRepositoryProvider).deleteCategory(id);
    await refresh();
    return true;
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd kiosk && fvm dart analyze lib/features/catalog/state/ 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/state/catalog_categories_notifier.dart
git commit -m "feat(catalog): add save/delete mutations to CatalogCategoriesNotifier"
```

---

### Task 10: Create `category_dialogs.dart`

**Files:**
- Create: `kiosk/lib/features/catalog/view/category_dialogs.dart`

- [ ] **Step 1: Create the dialogs file**

Create `kiosk/lib/features/catalog/view/category_dialogs.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../data/models/category.dart';
import '../state/catalog_categories_notifier.dart';

Future<CatalogCategory?> showSaveCategoryDialog(
  BuildContext context, {
  CatalogCategory? category,
}) {
  return showDialog<CatalogCategory>(
    context: context,
    builder: (context) => SaveCategoryDialog(category: category),
    barrierDismissible: false,
  );
}

Future<bool?> showDeleteCategoryDialog(BuildContext context, CatalogCategory category) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteCategoryDialog(category: category),
  );
}

class SaveCategoryDialog extends HookConsumerWidget {
  const SaveCategoryDialog({super.key, this.category});

  final CatalogCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: category?.name);
    final descriptionController = useTextEditingController(text: category?.description);
    final isActive = useState(category?.isActive ?? true);

    final saveAction = CatalogCategoriesNotifier.saveAction;
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
            width: r.value(kiosk: 560.0, tablet: 480.0, phone: double.infinity),
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
                  category != null ? 'Edit Category' : 'Add Category',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextBoxFormField(
                  controller: nameController,
                  label: 'Name',
                  hint: 'Enter category name',
                  maxLines: 1,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                TextBoxFormField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Enter category description (optional)',
                  maxLines: 3,
                  maxLength: 500,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                        fontWeight: FontWeight.w500,
                        color: POSColors.textPrimary,
                      ),
                    ),
                    Switch(
                      value: isActive.value,
                      onChanged: (v) => isActive.value = v,
                      activeColor: ColorSet.primary,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () => Navigator.of(context).pop(),
                      label: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                        ),
                      ),
                    ),
                    Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Button(
                      onPressed: saveStatus is! MutationPending
                          ? () {
                              if (!formKey.currentState!.validate()) return;
                              final updated = (category ?? CatalogCategory.draft()).copyWith(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                isActive: isActive.value,
                              );
                              saveAction.run(ref, (txn) async {
                                return txn.get(catalogCategoriesProvider.notifier).save(updated);
                              }).ignore();
                            }
                          : null,
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      label: Text(
                        saveStatus is MutationPending
                            ? 'Saving...'
                            : (category != null ? 'Update' : 'Save'),
                        style: TextStyle(
                          fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                        ),
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

class DeleteCategoryDialog extends ConsumerWidget {
  const DeleteCategoryDialog({super.key, required this.category});

  final CatalogCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteAction = CatalogCategoriesNotifier.deleteAction;
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
              'Delete Category',
              style: TextStyle(
                fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                fontWeight: FontWeight.w700,
                color: ColorSet.text,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
            Text(
              'Are you sure you want to delete "${category.name}"?\nThis action cannot be undone.',
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
                          vertical: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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
                              return txn
                                  .get(catalogCategoriesProvider.notifier)
                                  .delete(category.id);
                            }).ignore();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorSet.danger,
                      padding: EdgeInsets.symmetric(
                          vertical: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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

- [ ] **Step 2: Verify no analysis errors**

```bash
cd kiosk && fvm dart analyze lib/features/catalog/view/category_dialogs.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add kiosk/lib/features/catalog/view/category_dialogs.dart
git commit -m "feat(catalog): add SaveCategoryDialog and DeleteCategoryDialog"
```

---

### Task 11: Wire `CategoriesTab` and `_CategoryCard`

**Files:**
- Modify: `kiosk/lib/features/catalog/view/categories_tab.dart`

- [ ] **Step 1: Replace the full contents of `categories_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../auth/state/login_state_notifier.dart';
import '../data/models/category.dart';
import '../state/catalog_categories_notifier.dart';
import 'category_dialogs.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogCategoriesProvider);

    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: ColorSet.primary,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: context.responsive.value(kiosk: 64.0, tablet: 52.0, phone: 40.0),
                color: POSColors.textDisabled,
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 13, phone: 12),
                  color: POSColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Button(
                label: const Text('Retry'),
                leading: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(catalogCategoriesProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (categories) => categories.isEmpty
            ? _EmptyCategoriesState()
            : _CategoriesGrid(categories: categories),
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_rounded,
            size: context.responsive.value(kiosk: 64.0, tablet: 52.0, phone: 40.0),
            color: POSColors.textDisabled,
          ),
          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18.0, tablet: 16.0, phone: 14.0),
              fontWeight: FontWeight.w700,
              color: POSColors.textSecondary,
            ),
          ),
          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
          Text(
            'Add categories to organise your catalog',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
              color: POSColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesGrid extends ConsumerWidget {
  const _CategoriesGrid({required this.categories});

  final List<CatalogCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(loginStateProvider).value;
    final canManage = user?.isAdminOrSupervisor ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${categories.length} ${categories.length == 1 ? 'Category' : 'Categories'}',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
              ),
            ),
            if (canManage)
              Button(
                label: const Text('Add Category'),
                leading: const Icon(Icons.add),
                onPressed: () async {
                  await showSaveCategoryDialog(context);
                },
              ),
          ],
        ),
        Expanded(
          child: ResponsiveBuilder(
            kiosk: (context) =>
                _CategoryGridView(categories: categories, crossAxisCount: 4, canManage: canManage),
            tablet: (context) =>
                _CategoryGridView(categories: categories, crossAxisCount: 3, canManage: canManage),
            phone: (context) =>
                _CategoryGridView(categories: categories, crossAxisCount: 2, canManage: canManage),
          ),
        ),
      ],
    );
  }
}

class _CategoryGridView extends StatelessWidget {
  const _CategoryGridView({
    required this.categories,
    required this.crossAxisCount,
    required this.canManage,
  });

  final List<CatalogCategory> categories;
  final int crossAxisCount;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.4,
        crossAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        mainAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) =>
          _CategoryCard(category: categories[index], canManage: canManage),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.canManage});

  final CatalogCategory category;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Padding(
          padding: EdgeInsets.all(context.responsive.value(kiosk: 20, tablet: 16, phone: 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: context.responsive.value(kiosk: 44.0, tablet: 38.0, phone: 32.0),
                    height: context.responsive.value(kiosk: 44.0, tablet: 38.0, phone: 32.0),
                    decoration: BoxDecoration(
                      color: ColorSet.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(POSRadius.md),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      color: ColorSet.primary,
                      size: context.responsive.value(kiosk: 22.0, tablet: 20.0, phone: 16.0),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.value(kiosk: 10, tablet: 8, phone: 6),
                      vertical: context.responsive.value(kiosk: 4, tablet: 3, phone: 2),
                    ),
                    decoration: BoxDecoration(
                      color: category.isActive
                          ? ColorSet.success.withValues(alpha: 0.12)
                          : POSColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                    ),
                    child: Text(
                      category.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize:
                            context.responsive.value(kiosk: 11.0, tablet: 10.0, phone: 9.0),
                        fontWeight: FontWeight.w600,
                        color: category.isActive ? ColorSet.success : POSColors.textTertiary,
                      ),
                    ),
                  ),
                  if (canManage) ...[
                    Gap(context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
                    _ActionMenu(category: category),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 15.0, tablet: 14.0, phone: 12.0),
                  fontWeight: FontWeight.w700,
                  color: POSColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.description != null && category.description!.isNotEmpty) ...[
                Gap(context.responsive.value(kiosk: 2, tablet: 2, phone: 1)),
                Text(
                  category.description!,
                  style: TextStyle(
                    fontSize:
                        context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                    color: POSColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                    color: POSColors.iconSubtle,
                  ),
                  Gap(context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
                  Text(
                    '${category.productCount} ${category.productCount == 1 ? 'product' : 'products'}',
                    style: TextStyle(
                      fontSize:
                          context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                      color: POSColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.category});

  final CatalogCategory category;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: context.responsive.value(kiosk: 20.0, tablet: 18.0, phone: 16.0),
        color: POSColors.iconSubtle,
      ),
      onSelected: (value) async {
        if (value == 'edit') {
          await showSaveCategoryDialog(context, category: category);
        } else if (value == 'delete') {
          await showDeleteCategoryDialog(context, category);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: ColorSet.danger),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: ColorSet.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors across the whole catalog feature**

```bash
cd kiosk && fvm dart analyze lib/features/catalog/ 2>&1 | tail -10
```

Expected: `No issues found!`

- [ ] **Step 3: Run the app and verify end-to-end**

```bash
cd kiosk && fvm flutter run -d windows
```

Log in as an **admin or supervisor** user, navigate to Catalog Management → Categories tab and verify:
- The category list loads (shows active + inactive categories)
- `Add Category` button is visible and opens the Save dialog
- Filling name + description + toggle and tapping Save creates a new category and refreshes the list
- The `⋮` menu appears on each card; Edit opens dialog pre-populated with existing data; Update saves and refreshes
- The `⋮` menu Delete option shows the confirmation dialog; confirming removes the category from the list

Log in as a **user** role and verify:
- Category list still loads normally
- `Add Category` button is NOT shown
- No `⋮` menu on cards

- [ ] **Step 4: Commit**

```bash
git add kiosk/lib/features/catalog/view/categories_tab.dart
git commit -m "feat(catalog): wire category create/edit/delete in CategoriesTab"
```
