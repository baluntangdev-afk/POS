import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';
import { AppConfigService } from '../../config/config.service';
import type { JwtPayloadDto } from '../dto/jwt-payload.dto';
import { MeDto } from '../dto/me.dto';

/**
 * JWT strategy for access token validation.
 * Protects routes that require authentication.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(private readonly appConfig: AppConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: appConfig.jwtSecret,
    });
  }

  validate(payload: JwtPayloadDto): MeDto {
    return {
      id: payload.sub,
      email: payload.email,
      systemAdmin: payload.systemAdmin,
      isPinChanged: payload.isPinChanged,
    };
  }
}
