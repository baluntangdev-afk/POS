import {
  Catch,
  ExceptionFilter,
  ArgumentsHost,
  HttpStatus,
  UseFilters,
  applyDecorators,
} from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import { Response } from 'express';

@Catch(QueryFailedError)
class InsertUpdateFailed implements ExceptionFilter {
  catch(exception: QueryFailedError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const driverError = exception.driverError as any; // PostgreSQL driver error
    let message = 'A database error occurred';
    let error = 'Internal Server Error';
    let status = HttpStatus.INTERNAL_SERVER_ERROR;

    if (driverError) {
      const errorCode = driverError.code; // Extract PostgreSQL-specific error code

      switch (errorCode) {
        case '23505': // Unique constraint violation
          status = HttpStatus.CONFLICT;
          message = 'A record with the same data already exists.';
          error = 'Conflict';
          break;

        case '23503': // Foreign key violation
          status = HttpStatus.CONFLICT;
          message = 'Invalid reference. The related record does not exist.';
          error = 'Conflict';
          break;

        case '42P01': // Table not found
          status = HttpStatus.NOT_FOUND;
          message = 'The requested table or entity was not found.';
          error = 'Not Found';
          break;

        case '42703': // Column does not exist
          status = HttpStatus.NOT_FOUND;
          message = 'The requested field or column does not exist.';
          error = 'Not Found';
          break;

        case '22001': // Value too long for a column
          status = HttpStatus.BAD_REQUEST;
          message = 'The provided value is too long for the column.';
          error = 'Bad Request';
          break;

        case '22007': // Invalid datetime format
          status = HttpStatus.BAD_REQUEST;
          message = 'Invalid date format provided.';
          error = 'Bad Request';
          break;

        case '22P02': // Invalid text representation (e.g., passing a string instead of an integer)
          status = HttpStatus.BAD_REQUEST;
          message = 'Invalid input syntax.';
          error = 'Bad Request';
          break;

        default:
          status = HttpStatus.UNPROCESSABLE_ENTITY;
          message = driverError.message || 'Database operation failed.';
          error = 'Unprocessable Entity';
      }
    }

    response.status(status).json({
      statusCode: status,
      message,
      error,
    });
  }
}

export const InsertUpdateFailedException = () =>
  applyDecorators(UseFilters(new InsertUpdateFailed()));
