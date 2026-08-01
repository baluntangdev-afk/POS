import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service';
import { User } from '../users/entities/user.entity';
import { AppConfigService } from '../config/config.service';
import type { AuthTokensDto } from './dto/auth-tokens.dto';
import type { JwtPayloadDto } from './dto/jwt-payload.dto';
import { LoginByEmailDto } from './dto/login-by-email.dto';
import { LoginByUserIdDto } from './dto/login-by-user-id.dto';
import { LoginByDevicePinDto } from './dto/login-by-device-pin.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly appConfig: AppConfigService,
  ) {}

  async validateUser(email: string, password: string): Promise<User | null> {
    const user = await this.usersService.findByEmail(email, true);

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return null;
    }

    return user;
  }

  async loginByEmail(loginByEmailDto: LoginByEmailDto): Promise<AuthTokensDto> {
    const user = await this.usersService.findByEmail(loginByEmailDto.email, true);

    if (!user || !(await bcrypt.compare(loginByEmailDto.password, user.password))) {
      throw new UnauthorizedException('Invalid email or password');
    }

    await this.usersService.update(user.id, {
      lastLogin: new Date(),
      updatedBy: user,
    });

    return this.buildTokens(user);
  }

  async loginByUserId(loginByUserIdDto: LoginByUserIdDto): Promise<AuthTokensDto> {
    const user = await this.usersService.findByUserId(loginByUserIdDto.userId, true);

    if (!user || !(await bcrypt.compare(loginByUserIdDto.password, user.password))) {
      throw new UnauthorizedException('Invalid user ID or password');
    }

    await this.usersService.update(user.id, {
      lastLogin: new Date(),
    });

    return this.buildTokens(user);
  }

  async loginByDevicePin(loginByDevicePinDto: LoginByDevicePinDto): Promise<AuthTokensDto> {
    const user = await this.usersService.findByUserId(loginByDevicePinDto.userId, true);

    if (!user || !(await bcrypt.compare(loginByDevicePinDto.devicePin, user.devicePin))) {
      throw new UnauthorizedException('Invalid pin');
    }

    await this.usersService.update(user.id, {
      lastLogin: new Date(),
    });

    return this.buildTokens(user);
  }

  async me(userId: number): Promise<User> {
    return this.usersService.findOne(userId);
  }

  async refresh(refreshToken: string): Promise<AuthTokensDto> {
    let payload: JwtPayloadDto;

    try {
      payload = this.jwtService.verify<JwtPayloadDto>(refreshToken, {
        secret: this.appConfig.jwtRefreshSecret,
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.usersService.findByEmail(payload.email);

    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    return this.buildTokens(user);
  }

  private buildTokens(user: User): AuthTokensDto {
    const accessPayload: JwtPayloadDto = {
      sub: user.id,
      email: user.email,
      type: 'access',
      systemAdmin: user.systemAdmin,
      isPinChanged: user.isPinChanged,
      role: user.role,
    };
    const refreshPayload: JwtPayloadDto = {
      sub: user.id,
      email: user.email,
      type: 'refresh',
      systemAdmin: user.systemAdmin,
      isPinChanged: user.isPinChanged,
      role: user.role,
    };

    const accessToken = this.jwtService.sign(accessPayload, {
      secret: this.appConfig.jwtSecret,
      expiresIn: this.appConfig.jwtExpiresIn,
    });

    const refreshToken = this.jwtService.sign(refreshPayload, {
      secret: this.appConfig.jwtRefreshSecret,
      expiresIn: this.appConfig.jwtRefreshExpiresIn,
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: this.appConfig.jwtExpiresIn,
      isPinChanged: user.isPinChanged,
      id: user.id,
    };
  }
}
