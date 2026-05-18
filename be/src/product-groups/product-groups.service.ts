import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateProductGroupDto } from './dto/create-product-group.dto';
import { UpdateProductGroupDto } from './dto/update-product-group.dto';
import { ProductGroupDto } from './dto/product-group.dto';
import { ProductGroupQueryDto } from './dto/product-group-query.dto';
import { User } from '../users/entities/user.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike, FindOptionsWhere } from 'typeorm';
import { ProductGroup } from './entities/product-group.entity';
import { Product } from '../products/entities/product.entity';
import {
  PaginatedQueryDto,
  PaginatedResult,
  parseSort,
  buildFilterWhere,
} from '../utils/pagination';
import { PRODUCT_LIST_SELECT } from './product-group.constant';
import { EntityHelper } from '../utils/entity.helper';
import { ProductGroupMapper } from './mapper/product-group.mapper';
import { File } from 'multer';

@Injectable()
export class ProductGroupsService {
  constructor(
    @InjectRepository(ProductGroup)
    private readonly productGroupRepository: Repository<ProductGroup>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
  ) {}

  async create(
    createProductGroupDto: CreateProductGroupDto,
    image: File,
    causer: User,
  ): Promise<ProductGroupDto> {
    const payload: Partial<ProductGroup> = {
      name: createProductGroupDto.name,
      description: createProductGroupDto.description,
      createdBy: causer,
      updatedBy: causer,
    };

    if (image) {
      payload.imageUrl = image.buffer;
    }

    const entity = this.productGroupRepository.create(payload);

    const result = await this.productGroupRepository.save(entity);

    return ProductGroupMapper.toResponse(result);
  }

  async findAll(query: ProductGroupQueryDto): Promise<PaginatedResult<ProductGroupDto>> {
    const { page, limit, sort, name, description } = query;
    const skip = (page - 1) * limit;

    const PRODUCT_GROUP_SORTABLE_FIELDS: (keyof ProductGroup)[] = ['id', 'name', 'createdAt'];
    const order = parseSort<ProductGroup>(sort, {
      allowedFields: PRODUCT_GROUP_SORTABLE_FIELDS,
      defaultOrder: { id: 'ASC' },
    });

    const where: FindOptionsWhere<ProductGroup> = {};

    if (name) {
      where.name = ILike(`%${name}%`);
    }

    if (description) {
      where.description = ILike(`%${description}%`);
    }

    const [results, total] = await this.productGroupRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      select: {
        id: true,
        name: true,
        description: true,
        imageUrl: true,
      },
    });

    const data = results.map(ProductGroupMapper.toResponse);

    return { data, total, page, limit };
  }

  async findProductsByGroupId(
    groupId: number,
    query: PaginatedQueryDto,
  ): Promise<PaginatedResult<Product>> {
    const { page, limit, sort, filter } = query;
    const skip = (page - 1) * limit;

    const PRODUCT_SORTABLE_FIELDS: (keyof Product)[] = ['id', 'name', 'createdAt'];
    const order = parseSort<Product>(sort, {
      allowedFields: PRODUCT_SORTABLE_FIELDS,
      defaultOrder: { name: 'ASC' },
    });

    const PRODUCT_FILTERABLE_FIELDS: (keyof Product)[] = ['name', 'description'];
    const filterWhere = buildFilterWhere<Product>(filter, PRODUCT_FILTERABLE_FIELDS);

    const baseWhere = { productGroup: { id: groupId } };
    const where = filterWhere ? filterWhere.map((w) => ({ ...w, ...baseWhere })) : baseWhere;

    const [data, total] = await this.productRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      select: PRODUCT_LIST_SELECT,
    });
    return { data, total, page, limit };
  }

  async findOne(id: number): Promise<ProductGroupDto> {
    const result = await this.productGroupRepository.findOne({
      where: { id },
      select: {
        id: true,
        name: true,
        description: true,
        imageUrl: true,
      },
    });

    if (!result) {
      throw new NotFoundException('Product group not found');
    }

    return ProductGroupMapper.toResponse(result);
  }

  async update(
    id: number,
    updateProductGroupDto: UpdateProductGroupDto,
    image: File,
    causer: User,
  ): Promise<ProductGroupDto> {
    const payload: Partial<ProductGroup> = {
      name: updateProductGroupDto.name,
      description: updateProductGroupDto.description,
      updatedBy: causer,
    };

    if (image) {
      payload.imageUrl = image.buffer;
    }

    await this.productGroupRepository.update(id, EntityHelper.toPartialEntity(payload));

    return this.findOne(id);
  }

  async remove(id: number, causer: User) {
    await this.findOne(id);

    const payload: Partial<ProductGroup> = { deletedBy: causer };
    await this.productGroupRepository.update(id, EntityHelper.toPartialEntity(payload));

    await this.productGroupRepository.softDelete(id);

    return { message: 'Product group deleted successfully' };
  }
}
