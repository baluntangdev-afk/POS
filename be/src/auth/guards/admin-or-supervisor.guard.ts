import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import type { MeDto } from '../dto/me.dto';

@Injectable()
export class AdminOrSupervisorGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: MeDto }>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    if (!user.systemAdmin && user.role !== 'admin' && user.role !== 'supervisor') {
      throw new ForbiddenException('Admin or supervisor access required');
    }

    return true;
  }
}
