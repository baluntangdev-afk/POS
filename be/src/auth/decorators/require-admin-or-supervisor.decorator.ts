import { applyDecorators, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AdminOrSupervisorGuard } from '../guards/admin-or-supervisor.guard';

/**
 * Protects a route so only users with role === 'admin' or 'supervisor' can access.
 * Combines JWT auth + admin-or-supervisor role check.
 */
export function RequireAdminOrSupervisor() {
  return applyDecorators(
    ApiBearerAuth(),
    ApiForbiddenResponse({ description: 'Admin or supervisor access required' }),
    UseGuards(JwtAuthGuard, AdminOrSupervisorGuard),
  );
}
