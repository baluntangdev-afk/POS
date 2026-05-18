import { PartialType } from '@nestjs/swagger';
import { CreateProductGroupDto } from './create-product-group.dto';

/**
 * DTO for updating a product group (all fields optional).
 */
export class UpdateProductGroupDto extends PartialType(CreateProductGroupDto) {}
