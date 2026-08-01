import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { MeDto } from '../dto/me.dto';

export const ADMIN_OR_SUPERVISOR_OR_SELF_PARAM_KEY = 'adminOrSupervisorOrSelfParam';

/**
 * Guard that allows access if the user is an admin, a supervisor, or is acting on their own resource.
 * Expects the route param name for the resource id to be set via
 * SetMetadata(ADMIN_OR_SUPERVISOR_OR_SELF_PARAM_KEY, paramName).
 */
@Injectable()
export class AdminOrSupervisorOrSelfGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{
      user?: MeDto;
      params?: Record<string, string>;
    }>();
    const user = request.user;
    const params = request.params ?? {};

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    if (user.systemAdmin || user.role === 'admin' || user.role === 'supervisor') {
      return true;
    }

    const paramName =
      this.reflector.get<string>(ADMIN_OR_SUPERVISOR_OR_SELF_PARAM_KEY, context.getHandler()) ??
      'id';
    const resourceId = params[paramName];
    const resourceIdNum = resourceId != null ? Number(resourceId) : NaN;

    if (Number.isNaN(resourceIdNum) || user.id !== resourceIdNum) {
      throw new ForbiddenException('Admin or supervisor access required');
    }

    return true;
  }
}
