import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Injectable()
export class CatalogService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async getCategories(): Promise<unknown[]> {
    const rows = await this.dataSource.query<
      {
        id: string;
        name: string;
        description: string | null;
        image_url: string | null;
        sort_order: number;
        is_active: boolean;
        product_count: string;
      }[]
    >(`
      SELECT
        c.id, c.name, c.description, c.image_url, c.sort_order, c.is_active,
        COUNT(p.id) FILTER (WHERE p.is_available = true)::int AS product_count
      FROM catalog_categories c
      LEFT JOIN catalog_products p ON p.category_id = c.id
      WHERE c.is_active = true
      GROUP BY c.id
      ORDER BY c.sort_order ASC
    `);

    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      description: r.description,
      image_url: r.image_url,
      sort_order: r.sort_order,
      is_active: r.is_active,
      product_count: Number(r.product_count),
    }));
  }

  async getProducts(categoryId?: string, search?: string): Promise<unknown[]> {
    const conditions: string[] = ['p.is_available = true'];
    const params: unknown[] = [];

    if (categoryId) {
      params.push(categoryId);
      conditions.push(`p.category_id = $${params.length}`);
    }

    if (search) {
      params.push(`%${search}%`);
      conditions.push(`p.name ILIKE $${params.length}`);
    }

    const where = conditions.join(' AND ');

    const rows = await this.dataSource.query<
      {
        id: string;
        name: string;
        description: string | null;
        price: string;
        image_url: string | null;
        is_available: boolean;
        sort_order: number;
        category: { id: string; name: string } | null;
        modifier_groups: unknown[];
      }[]
    >(
      `
      WITH modifier_data AS (
        SELECT
          pmg.product_id,
          pmg.sort_order AS group_sort,
          json_build_object(
            'id',             mg.id,
            'name',           mg.name,
            'selection_type', mg.selection_type,
            'is_required',    mg.is_required,
            'min_selections', mg.min_selections,
            'max_selections', mg.max_selections,
            'sort_order',     pmg.sort_order,
            'modifiers', COALESCE(
              (SELECT json_agg(
                json_build_object(
                  'id',               m.id,
                  'name',             m.name,
                  'price_adjustment', m.price_adjustment::text,
                  'is_available',     m.is_available,
                  'sort_order',       m.sort_order
                ) ORDER BY m.sort_order
              ) FROM catalog_modifiers m WHERE m.modifier_group_id = mg.id),
              '[]'::json
            )
          ) AS mg_json
        FROM catalog_product_modifier_groups pmg
        JOIN catalog_modifier_groups mg ON mg.id = pmg.modifier_group_id
      )
      SELECT
        p.id, p.name, p.description, p.price::text AS price,
        p.image_url, p.is_available, p.sort_order,
        CASE WHEN c.id IS NULL THEN NULL
             ELSE json_build_object('id', c.id, 'name', c.name)
        END AS category,
        COALESCE(
          json_agg(md.mg_json ORDER BY md.group_sort)
            FILTER (WHERE md.mg_json IS NOT NULL),
          '[]'::json
        ) AS modifier_groups
      FROM catalog_products p
      LEFT JOIN catalog_categories c ON c.id = p.category_id
      LEFT JOIN modifier_data md ON md.product_id = p.id
      WHERE ${where}
      GROUP BY p.id, c.id, c.name
      ORDER BY p.sort_order ASC
    `,
      params,
    );

    return rows;
  }

  async getModifierGroups(): Promise<unknown[]> {
    const rows = await this.dataSource.query<
      {
        id: string;
        name: string;
        description: string | null;
        selection_type: string;
        min_selections: number;
        max_selections: number;
        is_required: boolean;
        modifiers: unknown[];
      }[]
    >(`
      SELECT
        mg.id, mg.name, mg.description,
        mg.selection_type, mg.min_selections, mg.max_selections, mg.is_required,
        COALESCE(
          json_agg(
            json_build_object(
              'id',               m.id,
              'name',             m.name,
              'price_adjustment', m.price_adjustment::text,
              'is_available',     m.is_available,
              'sort_order',       m.sort_order
            ) ORDER BY m.sort_order
          ) FILTER (WHERE m.id IS NOT NULL),
          '[]'::json
        ) AS modifiers
      FROM catalog_modifier_groups mg
      LEFT JOIN catalog_modifiers m ON m.modifier_group_id = mg.id
      GROUP BY mg.id
      ORDER BY mg.name ASC
    `);

    return rows;
  }
}
