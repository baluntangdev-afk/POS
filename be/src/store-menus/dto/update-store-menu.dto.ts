import { PartialType } from '@nestjs/swagger';
import { CreateStoreMenuDto } from './create-store-menu.dto';

/**
 * DTO for updating a store menu (all fields optional).
 */
export class UpdateStoreMenuDto extends PartialType(CreateStoreMenuDto) {}
