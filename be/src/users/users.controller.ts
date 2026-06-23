import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { PaginatedQueryDto } from '../utils/pagination';
import { RequireAdminOrSupervisor } from '../auth/decorators/require-admin-or-supervisor.decorator';
import { RequireAdminOrSupervisorOrSelf } from '../auth/decorators/require-admin-or-supervisor-or-self.decorator';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from './entities/user.entity';
import { PaginatedResponse } from '../utils/pagination/dto';
import { UserListItemDto } from './dto/user-list-item.dto';
import { ApiOkResponse } from '@nestjs/swagger';
import { InsertUpdateFailedException } from './exceptions/insert-update.filter';
import { VerifyPinDto } from './dto/verify-pin.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @RequireAdminOrSupervisor()
  @InsertUpdateFailedException()
  create(@Body() createUserDto: CreateUserDto, @CurrentUser() causer: User) {
    return this.usersService.create(createUserDto, causer);
  }

  @Get()
  @RequireAdminOrSupervisor()
  @ApiOkResponse({ type: PaginatedResponse(UserListItemDto) })
  findAll(@Query() query: PaginatedQueryDto) {
    return this.usersService.findAll(query);
  }

  @Get('authorizers')
  @ApiOkResponse({ type: [UserListItemDto] })
  findAuthorizers() {
    return this.usersService.findAuthorizers();
  }

  @Post('verify-pin')
  @HttpCode(HttpStatus.OK)
  verifyPin(@Body() dto: VerifyPinDto) {
    return this.usersService.verifyPin(dto.userId, dto.pin);
  }

  @Get(':id')
  @ApiOkResponse({ type: UserListItemDto })
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(+id);
  }

  @Patch(':id')
  @RequireAdminOrSupervisorOrSelf('id')
  @ApiOkResponse({ type: UserListItemDto })
  @InsertUpdateFailedException()
  update(
    @Param('id') id: string,
    @Body() updateUserDto: UpdateUserDto,
    @CurrentUser() causer: User,
  ) {
    updateUserDto.updatedBy = causer;
    return this.usersService.update(+id, updateUserDto);
  }

  @Delete(':id')
  @RequireAdminOrSupervisor()
  remove(@Param('id') id: string) {
    return this.usersService.remove(+id);
  }
}
