import { PartialType } from '@nestjs/swagger';
import { CreateMenuItemDto } from './create-menu-item.dto';

/**
 * DTO for updating a menu item (all fields optional).
 */
export class UpdateMenuItemDto extends PartialType(CreateMenuItemDto) {}
