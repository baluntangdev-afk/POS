import { applyDecorators, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import {
  SystemAdminOrSelfGuard,
  SYSTEM_ADMIN_OR_SELF_PARAM_KEY,
} from '../guards/system-admin-or-self.guard';

/**
 * Protects a route so only the authenticated user can access if they are the resource owner (by route param),
 * or any system admin can access.
 * Use for e.g. PATCH /users/:id so a user can update their own account without being system admin.
 *
 * @param idParam - Route parameter name holding the resource id (default: 'id')
 */
export function RequireSystemAdminOrSelf(idParam = 'id') {
  return applyDecorators(
    ApiBearerAuth(),
    ApiForbiddenResponse({ description: 'System admin access required' }),
    SetMetadata(SYSTEM_ADMIN_OR_SELF_PARAM_KEY, idParam),
    UseGuards(JwtAuthGuard, SystemAdminOrSelfGuard),
  );
}
