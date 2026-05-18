import { Type } from '@nestjs/common';
import { ApiProperty } from '@nestjs/swagger';

export function PaginatedResponse<T>(classReference: Type<T>) {
  abstract class Pagination {
    @ApiProperty({ description: 'The list of items in the current page', type: [classReference] })
    data!: T[];

    @ApiProperty({
      description: 'The total number of items in the collection',
      type: Number,
    })
    total: number;

    @ApiProperty({
      description: 'Current page number (1-based)',
      type: Number,
    })
    page: number;

    @ApiProperty({
      description: 'Number of items per page',
      type: Number,
    })
    limit: number;
  }

  Object.defineProperty(Pagination, 'name', {
    writable: false,
    value: `Paginated${classReference.name}ResponseDto`,
  });

  return Pagination;
}
