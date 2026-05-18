import { PartialType } from '@nestjs/swagger';
import { CreateProductDto } from './create-product.dto';

/**
 * DTO for updating a product (all fields optional).
 */
export class UpdateProductDto extends PartialType(CreateProductDto) {}
