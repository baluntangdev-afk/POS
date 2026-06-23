import { groupRows } from './products-csv.seeder';

// Column order: Category, Category Desc, Product Name, Product Desc,
// Base Price, Variant Name, Variant Price, [Product Image URL]
const row = (
  category: string,
  productName: string,
  basePrice: string,
  variantName = '',
  variantPrice = '',
  imageUrl = '',
): string[] => [category, '', productName, '', basePrice, variantName, variantPrice, imageUrl];

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

  it('should capture an optional product image URL from the CSV', () => {
    const { products } = groupRows([
      row('Coffee', 'Americano', '120', 'Regular', '120', 'https://cdn.example/americano.png'),
    ]);

    expect(products[0].imageUrl).toBe('https://cdn.example/americano.png');
  });

  it('should leave imageUrl null when the image column is absent or blank', () => {
    // Legacy 7-column row (no image field at all) and an explicit blank both null.
    const { products } = groupRows([
      ['Coffee', '', 'Americano', '', '120', 'Regular', '120'],
      row('Tea', 'Matcha', '130', 'Regular', '130', '   '),
    ]);

    const byCategory = new Map(products.map((p) => [p.categoryName, p]));
    expect(byCategory.get('Coffee')!.imageUrl).toBeNull();
    expect(byCategory.get('Tea')!.imageUrl).toBeNull();
  });

  it('should take the first non-empty image URL across a product\'s variant rows', () => {
    const { products } = groupRows([
      row('Coffee', 'Latte', '150', 'Regular', '150', ''),
      row('Coffee', 'Latte', '150', 'Large', '200', 'https://cdn.example/latte.png'),
    ]);

    expect(products).toHaveLength(1);
    expect(products[0].imageUrl).toBe('https://cdn.example/latte.png');
  });
});
