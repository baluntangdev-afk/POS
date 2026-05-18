import { applyDecorators, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { SystemAdminGuard } from '../guards/system-admin.guard';

/**
 * Protects a route so only users with systemAdmin === true can access.
 * Combines JWT auth + system-admin check.
 */
export function RequireSystemAdmin() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiForbiddenResponse({ description: 'System admin access required' }),
    UseGuards(JwtAuthGuard, SystemAdminGuard),
  );
}
