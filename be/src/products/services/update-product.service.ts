import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateProductDto } from '../dto/update-product.dto';
import { User } from '../../users/entities/user.entity';
import { Product } from '../entities/product.entity';
import { EntityHelper } from '../../utils/entity.helper';
import { File } from 'multer';
import { FindProductGroupService } from './find-product-group.service';

@Injectable()
export class UpdateProductService {
  constructor(
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
    private readonly findProductGroupService: FindProductGroupService,
  ) {}

  async execute(
    id: number,
    updateProductDto: UpdateProductDto,
    image: File,
    causer: User,
  ): Promise<void> {
    const payload: Partial<Product> = {
      name: updateProductDto.name,
      description: updateProductDto.description,
      updatedBy: causer,
    };

    if (updateProductDto.groupId) {
      const productGroup = await this.findProductGroupService.execute(updateProductDto.groupId);
      payload.productGroup = productGroup;
    }

    if (image) {
      payload.imageUrl = image.buffer;
    }

    await this.productsRepository.update(id, EntityHelper.toPartialEntity(payload));
  }
}
