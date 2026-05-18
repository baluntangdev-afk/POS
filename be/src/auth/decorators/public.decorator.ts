import { SetMetadata } from '@nestjs/common';

const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marks a route as public (no JWT required).
 * Use on login, refresh, and any other unauthenticated endpoints.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

export { IS_PUBLIC_KEY };
