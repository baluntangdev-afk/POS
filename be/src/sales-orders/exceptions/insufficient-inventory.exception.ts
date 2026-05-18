import { HttpException, HttpStatus } from '@nestjs/common';
import { InsufficientItemDto } from '../../inventory-stocks/dto/inventory-validation-result.dto';

/**
 * Thrown when inventory validation fails: one or more materials have insufficient stock.
 */
export class InsufficientInventoryException extends HttpException {
  constructor(insufficientItems: InsufficientItemDto[]) {
    super(
      {
        statusCode: HttpStatus.CONFLICT,
        error: 'Conflict',
        message: 'Insufficient inventory for one or more recipe materials.',
        insufficientItems,
      },
      HttpStatus.CONFLICT,
    );
  }
}
