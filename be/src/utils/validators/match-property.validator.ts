import { registerDecorator, ValidationArguments, ValidationOptions } from 'class-validator';

/**
 * Validates that the property value equals the value of another property.
 * @param propertyName - Name of the property to match against.
 * @param validationOptions - Optional class-validator options.
 */
export function MatchProperty(propertyName: string, validationOptions?: ValidationOptions) {
  return function (object: object, propertyNameToValidate: string): void {
    registerDecorator({
      name: 'matchProperty',
      target: object.constructor,
      propertyName: propertyNameToValidate,
      constraints: [propertyName],
      options: validationOptions,
      validator: {
        validate(value: unknown, args: ValidationArguments): boolean {
          const [relatedPropertyName] = args.constraints as [string];
          const relatedValue = (args.object as Record<string, unknown>)[relatedPropertyName];
          return value === relatedValue;
        },
        defaultMessage(args: ValidationArguments): string {
          const [relatedPropertyName] = args.constraints as [string];
          return `${args.property} must match ${relatedPropertyName}`;
        },
      },
    });
  };
}
