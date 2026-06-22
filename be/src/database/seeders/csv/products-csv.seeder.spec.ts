import { groupRows } from './products-csv.seeder';

// Column order: Category, Category Desc, Product Name, Product Desc,
// Base Price, Variant Name, Variant Price
const row = (
  category: string,
  productName: string,
  basePrice: string,
  variantName = '',
  variantPrice = '',
): string[] => [category, '', productName, '', basePrice, variantName, variantPrice];

describe('groupRows', () => {
  it('should keep the same product name in different categories as two distinct products', () => {
    // Regression: the same name in two categories must NOT collapse into one
    // product. Product names are unique per category, not globally, so the
    // catalog legitimately has e.g. "Avocado Premium" in Smoothies and Salads.
    const { products } = groupRows([
      row('Smoothies', 'Avocado Premium', '150', 'Regular', '150'),
      row('Salads', 'Avocado Premium', '180', 'Regular', '180'),
    ]);

    expect(products).toHaveLength(2);
    const byCategory = new Map(products.map((p) => [p.categoryName, p]));
    expect(byCategory.get('Smoothies')!.variants[0].price).toBe(150);
    expect(byCategory.get('Salads')!.variants[0].price).toBe(180);
  });

  it('should collapse repeated rows of the same product+category into one product with many variants', () => {
    const { products } = groupRows([
      row('Smoothies', 'Avocado Premium', '150', 'Regular', '150'),
      row('Smoothies', 'Avocado Premium', '150', 'Large', '200'),
    ]);

    expect(products).toHaveLength(1);
    expect(products[0].variants).toEqual([
      { name: 'Regular', price: 150 },
      { name: 'Large', price: 200 },
    ]);
  });

  it('should give a single-price product (blank variant) a default "Regular" variant', () => {
    const { products } = groupRows([row('Coffee', 'Americano', '120')]);

    expect(products).toHaveLength(1);
    expect(products[0].variants).toEqual([{ name: 'Regular', price: 120 }]);
  });

  it('should deduplicate categories', () => {
    const { categories } = groupRows([
      row('Coffee', 'Americano', '120'),
      row('Coffee', 'Latte', '130'),
    ]);

    expect(categories).toHaveLength(1);
    expect(categories[0].name).toBe('Coffee');
  });
});
