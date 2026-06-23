import { applyDecorators, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import {
  AdminOrSupervisorOrSelfGuard,
  ADMIN_OR_SUPERVISOR_OR_SELF_PARAM_KEY,
} from '../guards/admin-or-supervisor-or-self.guard';

/**
 * Protects a route so only admins, supervisors, or the resource owner can access.
 *
 * @param idParam - Route parameter name holding the resource id (default: 'id')
 */
export function RequireAdminOrSupervisorOrSelf(idParam = 'id') {
  return applyDecorators(
    ApiBearerAuth(),
    ApiForbiddenResponse({ description: 'Admin or supervisor access required' }),
    SetMetadata(ADMIN_OR_SUPERVISOR_OR_SELF_PARAM_KEY, idParam),
    UseGuards(JwtAuthGuard, AdminOrSupervisorOrSelfGuard),
  );
}
