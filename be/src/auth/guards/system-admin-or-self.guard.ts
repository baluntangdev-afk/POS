import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { MeDto } from '../dto/me.dto';

export const SYSTEM_ADMIN_OR_SELF_PARAM_KEY = 'systemAdminOrSelfParam';

/**
 * Guard that allows access if the user is a system admin or is acting on their own resource.
 * Expects the route param name for the resource id to be set via SetMetadata(SYSTEM_ADMIN_OR_SELF_PARAM_KEY, paramName).
 * Compares request.user.id with request.params[paramName] (e.g. id from PATCH /users/:id).
 */
@Injectable()
export class SystemAdminOrSelfGuard implements CanActivate {
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

    if (user.systemAdmin) {
      return true;
    }

    const paramName =
      this.reflector.get<string>(SYSTEM_ADMIN_OR_SELF_PARAM_KEY, context.getHandler()) ?? 'id';
    const resourceId = params[paramName];
    const resourceIdNum = resourceId != null ? Number(resourceId) : NaN;

    if (Number.isNaN(resourceIdNum) || user.id !== resourceIdNum) {
      throw new ForbiddenException('System admin access required');
    }

    return true;
  }
}
