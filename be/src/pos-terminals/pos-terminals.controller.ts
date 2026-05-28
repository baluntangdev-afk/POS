import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiConflictResponse, ApiForbiddenResponse, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PosTerminalsService } from './pos-terminals.service';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { MeDto } from '../auth/dto/me.dto';
import { PosTerminalDto } from './dto/pos-terminal.dto';
import { CreatePosTerminalDto } from './dto/create-pos-terminal.dto';
import { SystemAdminGuard } from '../auth/guards/system-admin.guard';

@ApiTags('POS Terminals')
@ApiBearerAuth()
@Controller('pos-terminals')
export class PosTerminalsController {
  constructor(private readonly posTerminalsService: PosTerminalsService) {}

  @Get('my-terminal')
  @ApiOperation({ summary: 'Get the POS terminal assigned to the current user' })
  @ApiResponse({ status: 200, description: 'Returns the assigned POS terminal', type: PosTerminalDto })
  @ApiResponse({ status: 404, description: 'No POS terminal is assigned to your account' })
  async getMyTerminal(@CurrentUser() user: MeDto): Promise<PosTerminalDto> {
    const terminal = await this.posTerminalsService.findAssignedToUser(user.id);
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
}
