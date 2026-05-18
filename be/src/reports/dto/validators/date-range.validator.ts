import {
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
} from 'class-validator';

export interface DateRangeValidatable {
  startDate?: Date;
  endDate?: Date;
}

/**
 * Validates that startDate is not after endDate when both are present.
 */
@ValidatorConstraint({ name: 'DateRange', async: false })
export class DateRangeConstraint implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    const obj = args.object as DateRangeValidatable;
    const start = obj.startDate?.getTime();
    const end = obj.endDate?.getTime();
    if (start != null && end != null && start > end) {
      return false;
    }
    return true;
  }

  defaultMessage(): string {
    return 'Date filter must be valid: Date Start must not be further than Date End.';
  }
}
