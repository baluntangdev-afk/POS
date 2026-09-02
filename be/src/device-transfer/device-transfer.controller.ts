import {
  BadRequestException,
  Body,
  Controller,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { File } from 'multer';
import type { Response } from 'express';
import { ApiTags, ApiOperation, ApiConsumes, ApiOkResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
import { MAX_ARCHIVE_BYTES } from './device-transfer.constants';
import { ExportDeviceDto } from './dto/export-device.dto';
import { ImportDeviceDto } from './dto/import-device.dto';
import { DeviceImportSummaryDto } from './dto/device-transfer-result.dto';
import { DeviceExportService } from './services/device-export.service';
import { DeviceImportService } from './services/device-import.service';

@ApiTags('Device Transfer')
@ApiBearerAuth()
@Controller('device-transfer')
@UseGuards(AdminOrSupervisorGuard)
export class DeviceTransferController {
  constructor(
    private readonly exportService: DeviceExportService,
    private readonly importService: DeviceImportService,
  ) {}

  @Post('export')
  @ApiOperation({
    summary: 'Export the full device dataset as an encrypted .posbackup archive',
  })
  async export(
    @Body() dto: ExportDeviceDto,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const { buffer, manifest } = await this.exportService.export(dto.passphrase);
    const stamp = manifest.createdAt.slice(0, 19).replace(/[:T]/g, '-');
    res.set({
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="pos-kiosk-backup-${stamp}.posbackup"`,
      'X-Backup-Row-Counts': Buffer.from(JSON.stringify(manifest.tableRowCounts)).toString(
        'base64',
      ),
    });
    return new StreamableFile(buffer);
  }

  @Post('import')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_ARCHIVE_BYTES } }))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Replace the full device dataset from an encrypted .posbackup archive (destructive)',
  })
  @ApiOkResponse({ type: DeviceImportSummaryDto })
  async import(
    @UploadedFile() file: File | undefined,
    @Body() dto: ImportDeviceDto,
  ): Promise<DeviceImportSummaryDto> {
    if (!file?.buffer?.length) {
      throw new BadRequestException('No backup file was uploaded.');
    }
    return this.importService.import(
      file.buffer,
      dto.passphrase,
      dto.partialRestore === 'true',
    );
  }
}
