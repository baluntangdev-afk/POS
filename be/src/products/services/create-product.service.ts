import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateProductDto } from '../dto/create-product.dto';
import { User } from '../../users/entities/user.entity';
import { Product } from '../entities/product.entity';
import { ProductDto } from '../dto/product.dto';
import { ProductMapper } from '../mapper/product.mapper';
import { File } from 'multer';
import { FindProductGroupService } from './find-product-group.service';

@Injectable()
export class CreateProductService {
  constructor(
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
    private readonly findProductGroupService: FindProductGroupService,
  ) {}

  async execute(
    createProductDto: CreateProductDto,
    image: File,
    causer: User,
  ): Promise<ProductDto> {
    const payload: Partial<Product> = {
      name: createProductDto.name,
      description: createProductDto.description,
      createdBy: causer,
      updatedBy: causer,
    };

    const productGroup = await this.findProductGroupService.execute(createProductDto.groupId);
    payload.productGroup = productGroup;

    if (image) {
      payload.imageUrl = image.buffer;
    }

    const entity = this.productsRepository.create(payload);
    const result = await this.productsRepository.save(entity);

    return ProductMapper.toProductDto(result);
  }
}
