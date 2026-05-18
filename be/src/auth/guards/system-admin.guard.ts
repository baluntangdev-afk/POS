import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import type { MeDto } from '../dto/me.dto';

/**
 * Guard that allows only users with systemAdmin === true.
 * Use after JwtAuthGuard so req.user is set (e.g. @UseGuards(JwtAuthGuard, SystemAdminGuard)).
 */
@Injectable()
export class SystemAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: MeDto }>();
    const user = request.user;

    if (!user?.systemAdmin) {
      throw new ForbiddenException('System admin access required');
    }

    return true;
  }
}
