import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiForbiddenResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { PosTerminalsService } from './pos-terminals.service';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { MeDto } from '../auth/dto/me.dto';
import { PosTerminalDto } from './dto/pos-terminal.dto';
import { PaymentMethodEntryDto } from './dto/payment-method-entry.dto';
import { CreatePosTerminalDto } from './dto/create-pos-terminal.dto';
import { UpdatePosTerminalDto } from './dto/update-pos-terminal.dto';
import { AddPaymentMethodDto } from './dto/add-payment-method.dto';
import { UpdatePaymentMethodDto } from './dto/update-payment-method.dto';
import { SystemAdminGuard } from '../auth/guards/system-admin.guard';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';

@ApiTags('POS Terminals')
@ApiBearerAuth()
@Controller('pos-terminals')
export class PosTerminalsController {
  constructor(private readonly posTerminalsService: PosTerminalsService) {}

  @Get('my-terminal')
  @ApiOperation({ summary: 'Get the POS terminal assigned to the current user' })
  @ApiResponse({ status: 200, description: 'Returns the assigned POS terminal', type: PosTerminalDto })
  @ApiNotFoundResponse({ description: 'No POS terminal is assigned to your account' })
  async getMyTerminal(@CurrentUser() user: MeDto): Promise<PosTerminalDto> {
    const terminal = await this.posTerminalsService.findAssignedToUser(user.id);
    return PosTerminalDto.from(terminal);
  }

  @Patch('my-terminal')
  @UseGuards(SystemAdminGuard)
  @ApiOperation({ summary: 'Update the POS terminal details for the current admin user' })
  @ApiResponse({ status: 200, description: 'POS terminal updated successfully', type: PosTerminalDto })
  @ApiNotFoundResponse({ description: 'No POS terminal is assigned to your account' })
  @ApiForbiddenResponse({ description: 'System admin access required' })
  async updateMyTerminal(@CurrentUser() user: MeDto, @Body() dto: UpdatePosTerminalDto): Promise<PosTerminalDto> {
    const terminal = await this.posTerminalsService.updateForUser(user.id, dto);
    return PosTerminalDto.from(terminal);
  }

  @Post('register')
  @UseGuards(SystemAdminGuard)
  @ApiOperation({ summary: 'Register a new POS terminal for the current admin user' })
  @ApiResponse({ status: 201, description: 'POS terminal registered successfully', type: PosTerminalDto })
  @ApiConflictResponse({ description: 'A POS terminal is already assigned to your account' })
  @ApiForbiddenResponse({ description: 'System admin access required' })
  async register(@CurrentUser() user: MeDto, @Body() dto: CreatePosTerminalDto): Promise<PosTerminalDto> {
    const terminal = await this.posTerminalsService.registerForUser(user.id, dto);
    return PosTerminalDto.from(terminal);
  }

  @Post('my-terminal/payment-methods')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Add a payment method to the current admin\'s POS terminal' })
  @ApiResponse({ status: 201, description: 'Payment method added successfully', type: PaymentMethodEntryDto })
  @ApiNotFoundResponse({ description: 'No POS terminal is assigned to your account' })
  @ApiForbiddenResponse({ description: 'Admin or supervisor access required' })
  async addPaymentMethod(
    @CurrentUser() user: MeDto,
    @Body() dto: AddPaymentMethodDto,
  ): Promise<PaymentMethodEntryDto> {
    const entry = await this.posTerminalsService.addPaymentMethod(user.id, dto);
    return PaymentMethodEntryDto.from(entry);
  }

  @Patch('my-terminal/payment-methods/:id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Update a payment method on the current admin\'s POS terminal' })
  @ApiResponse({ status: 200, description: 'Payment method updated successfully', type: PaymentMethodEntryDto })
  @ApiNotFoundResponse({ description: 'Payment method not found for your terminal' })
  @ApiForbiddenResponse({ description: 'Admin or supervisor access required' })
  async updatePaymentMethod(
    @CurrentUser() user: MeDto,
    @Param('id', ParseIntPipe) methodId: number,
    @Body() dto: UpdatePaymentMethodDto,
  ): Promise<PaymentMethodEntryDto> {
    const entry = await this.posTerminalsService.updatePaymentMethod(user.id, methodId, dto);
    return PaymentMethodEntryDto.from(entry);
  }

  @Delete('my-terminal/payment-methods/:id')
  @UseGuards(AdminOrSupervisorGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remove a payment method from the current admin\'s POS terminal' })
  @ApiNoContentResponse({ description: 'Payment method removed successfully' })
  @ApiNotFoundResponse({ description: 'Payment method not found for your terminal' })
  @ApiForbiddenResponse({ description: 'Admin or supervisor access required' })
  async removePaymentMethod(
    @CurrentUser() user: MeDto,
    @Param('id', ParseIntPipe) methodId: number,
  ): Promise<void> {
    await this.posTerminalsService.removePaymentMethod(user.id, methodId);
  }
}
