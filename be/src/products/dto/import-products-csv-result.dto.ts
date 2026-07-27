import { ApiProperty } from '@nestjs/swagger';

export class ImportProductsCsvResultDto {
  @ApiProperty() categoriesInserted: number;
  @ApiProperty() categoriesUpdated: number;
  @ApiProperty() categoriesDeleted: number;
  @ApiProperty() productsInserted: number;
  @ApiProperty() productsUpdated: number;
  @ApiProperty() productsDeleted: number;
  @ApiProperty() variantsInserted: number;
  @ApiProperty() variantsUpdated: number;
  @ApiProperty() variantsDeleted: number;
}
