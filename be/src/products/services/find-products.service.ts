import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike, FindOptionsWhere } from 'typeorm';
import { Product } from '../entities/product.entity';
import { ProductQueryDto } from '../dto/product-query.dto';
import { PaginatedResult, parseSort } from '../../utils/pagination';
import { PRODUCT_LIST_SELECT } from '../products.constant';
import { ProductMapper } from '../mapper/product.mapper';
import { ProductDto } from '../dto/product.dto';

@Injectable()
export class FindProductsService {
  constructor(
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
  ) {}

  async execute(query: ProductQueryDto): Promise<PaginatedResult<ProductDto>> {
    const { page, limit, sort, name, description, groupId } = query;
    const skip = (page - 1) * limit;

    const PRODUCT_SORTABLE_FIELDS: (keyof Product)[] = ['id', 'name', 'createdAt'];
    const order = parseSort<Product>(sort, {
      allowedFields: PRODUCT_SORTABLE_FIELDS,
      defaultOrder: { id: 'ASC' },
    });

    const where: FindOptionsWhere<Product> = {};

    if (name) {
      where.name = ILike(`%${name}%`);
    }

    if (description) {
      where.description = ILike(`%${description}%`);
    }

    if (groupId) {
      where.productGroup = { id: groupId };
    }

    const [results, total] = await this.productsRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      select: PRODUCT_LIST_SELECT,
      relations: {
        productGroup: true,
      },
    });

    const data = results.map(ProductMapper.toProductDto);

    return { data, total, page, limit };
  }
}
