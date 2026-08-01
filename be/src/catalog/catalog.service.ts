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
      status: (dto.isActive ?? true) ? BaseStatus.ACTIVE : BaseStatus.CANCELLED,
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
      update.status = dto.isActive ? BaseStatus.ACTIVE : BaseStatus.CANCELLED;
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

  async getProducts(
    categoryId?: string,
    search?: string,
    includeDisabled = false,
  ): Promise<unknown[]> {
    const conditions: string[] = includeDisabled
      ? ['p.deleted_at   IS NULL']
      : ["p.status       = 'Active'", 'p.is_available = true', 'p.deleted_at   IS NULL'];
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
