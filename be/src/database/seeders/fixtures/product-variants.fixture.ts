/**
 * Product variant seed data. Links product name (from ProductsSeeder) to variant names.
 */
export interface ProductVariantFixtureItem {
  /** Product name (must match a product seeded by ProductsSeeder). */
  productName: string;
  /** Variant names to create for this product. First one is used as default (isDefault: true). */
  variantNames: string[];
}

export const PRODUCT_VARIANTS_FIXTURE: ProductVariantFixtureItem[] = [
  { productName: 'Latte', variantNames: ['Regular', 'Medium', 'Large'] },
  { productName: 'Americano', variantNames: ['Regular', 'Medium', 'Large'] },
  { productName: 'Macchiato', variantNames: ['Regular', 'Medium', 'Large'] },
  { productName: 'Matcha', variantNames: ['Regular', 'Medium', 'Large'] },
  { productName: 'Muffin', variantNames: ['Regular'] },
  { productName: 'Salad', variantNames: ['Regular'] },
  { productName: 'Club Sandwich', variantNames: ['Small', 'Large'] },
];
