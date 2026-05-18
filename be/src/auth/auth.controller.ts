import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { Public } from './decorators/public.decorator';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { AuthTokensDto } from './dto/auth-tokens.dto';
import { LoginByEmailDto } from './dto/login-by-email.dto';
import { LoginByUserIdDto } from './dto/login-by-user-id.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { MeDto } from './dto/me.dto';
import { LoginByDevicePinDto } from './dto/login-by-device-pin.dto';
import { UserListItemDto } from '../users/dto/user-list-item.dto';

/**
 * Auth controller: login (email/password) and refresh token.
 */
@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login/email')
  @UseGuards(LocalAuthGuard)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiResponse({
    status: 200,
    description: 'Returns access and refresh tokens',
    type: AuthTokensDto,
  })
  @ApiResponse({ status: 401, description: 'Invalid email or password' })
  loginByEmail(@Body() loginByEmailDto: LoginByEmailDto): Promise<AuthTokensDto> {
    return this.authService.loginByEmail(loginByEmailDto);
  }

  @Public()
  @Post('login/user-id')
  @ApiOperation({ summary: 'Login with user ID and password' })
  @ApiResponse({
    status: 200,
    description: 'Returns access and refresh tokens',
    type: AuthTokensDto,
  })
  @ApiResponse({ status: 401, description: 'Invalid user ID or password' })
  loginByUserId(@Body() loginByUserIdDto: LoginByUserIdDto): Promise<AuthTokensDto> {
    return this.authService.loginByUserId(loginByUserIdDto);
  }

  @Public()
  @Post('login/pin')
  @ApiOperation({ summary: 'Login with pin' })
  @ApiResponse({
    status: 200,
    description: 'Returns access and refresh tokens',
    type: AuthTokensDto,
  })
  @ApiResponse({ status: 401, description: 'Invalid pin' })
  loginByDevicePin(@Body() loginByDevicePinDto: LoginByDevicePinDto): Promise<AuthTokensDto> {
    return this.authService.loginByDevicePin(loginByDevicePinDto);
  }

  @Public()
  @Post('refresh')
  @ApiOperation({ summary: 'Get new tokens using refresh token' })
  @ApiResponse({
    status: 200,
    description: 'Returns new access and refresh tokens',
    type: AuthTokensDto,
  })
  @ApiResponse({ status: 401, description: 'Invalid or expired refresh token' })
  async refresh(@Body() dto: RefreshTokenDto): Promise<AuthTokensDto> {
    return this.authService.refresh(dto.refreshToken);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user from JWT' })
  @ApiResponse({
    status: 200,
    description: 'Returns the payload from the access token',
    type: UserListItemDto,
  })
  @ApiResponse({ status: 401, description: 'Missing or invalid token' })
  getProfile(@CurrentUser() user: MeDto) {
    return this.authService.me(user.id);
  }
}
