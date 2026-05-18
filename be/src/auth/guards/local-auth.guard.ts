import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Guard for local (email/password) strategy.
 * Use on POST /auth/login.
 */
@Injectable()
export class LocalAuthGuard extends AuthGuard('local') {}
