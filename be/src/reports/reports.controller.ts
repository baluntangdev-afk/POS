import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiOkResponse } from '@nestjs/swagger';
import { PaginatedResponse } from '../utils/pagination/dto';
import { PaginatedQueryDto } from '../utils/pagination/paginated-query.dto';
import type { PaginatedResult } from '../utils/pagination/interfaces';
import { TotalReportService } from './services/total-report.service';
import { HourlySalesReportService } from './services/hourly-sales-report.service';
import { DailySalesReportService } from './services/daily-sales-report.service';
import { MonthlySalesReportService } from './services/monthly-sales-report.service';
import { ProductGroupSalesReportService } from './services/product-group-sales-report.service';
import { ProductSalesReportService } from './services/product-sales-report.service';
import { UserSalesReportService } from './services/user-sales-report.service';
import { PaymentSalesReportService } from './services/payment-sales-report.service';
import { ExportableReportService } from './services/exportable-report.service';
import { ExportableDateQueryDto } from './dto/exportable-date-query.dto';
import { MarkExportedBodyDto } from './dto/mark-exported-body.dto';
import { ExportableReportResponseDto } from './dto/exportable-report-response.dto';
import { SalesQueryDto } from './dto/sales-query.dto';
import { SalesResponseDto } from './dto/sales-response.dto';
import { HourlySalesQueryDto } from './dto/hourly-sales-query.dto';
import { HourlySalesDataItemDto } from './dto/hourly-sales-response.dto';
import { DailySalesDataItemDto } from './dto/daily-sales-response.dto';
import { MonthlySalesQueryDto } from './dto/monthly-sales-query.dto';
import { MonthlySalesDataItemDto } from './dto/monthly-sales-response.dto';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { ProductGroupSalesDataItemDto } from './dto/product-group-sales-response.dto';
import { ProductSalesDataItemDto } from './dto/product-sales-response.dto';
import { UserSalesDataItemDto } from './dto/user-sales-response.dto';
import { PaymentMethodSalesDataItemDto } from './dto/payment-sales-response.dto';
import { User } from '../users/entities/user.entity';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { CashierXReadingReportService } from './services/cashier-x-reading-report.service';
import { CashierXReadingResponseDto } from './dto/cashier-x-reading-response.dto';
import { CashierDailyReportService } from './services/cashier-daily-report.service';
import {
  CashierDailyReportHistoryItemDto,
  CashierDailyReportResponseDto,
} from './dto/cashier-daily-report-response.dto';
import { CashierXReadingHistoryItemDto } from './dto/cashier-x-reading-response.dto';
import { ZReadingReportService } from './services/z-reading-report.service';
import { ZReadingHistoryItemDto, ZReadingResponseDto } from './dto/z-reading-response.dto';
import { CloseZReadingDto } from './dto/close-z-reading.dto';

@ApiTags('Reports')
@Controller('reports')
export class ReportsController {
  constructor(
    private readonly totalReportService: TotalReportService,
    private readonly hourlySalesReportService: HourlySalesReportService,
    private readonly dailySalesReportService: DailySalesReportService,
    private readonly monthlySalesReportService: MonthlySalesReportService,
    private readonly productGroupSalesReportService: ProductGroupSalesReportService,
    private readonly productSalesReportService: ProductSalesReportService,
    private readonly userSalesReportService: UserSalesReportService,
    private readonly paymentSalesReportService: PaymentSalesReportService,
    private readonly exportableReportService: ExportableReportService,
    private readonly cashierXReadingReportService: CashierXReadingReportService,
    private readonly cashierDailyReportService: CashierDailyReportService,
    private readonly zReadingReportService: ZReadingReportService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Get sales report' })
  @ApiOkResponse({
    description: 'Sales report.',
    type: SalesResponseDto,
  })
  getSales(@Query() query: SalesQueryDto): Promise<SalesResponseDto> {
    return this.totalReportService.getReport(query);
  }

  @Get('type/hourly')
  @ApiOperation({ summary: 'Get hourly sales report' })
  @ApiOkResponse({
    description: 'Hourly sales report (one row per hour).',
    type: HourlySalesDataItemDto,
    isArray: true,
  })
  getHourlySales(@Query() query: HourlySalesQueryDto): Promise<HourlySalesDataItemDto[]> {
    return this.hourlySalesReportService.getReport(query);
  }

  @Get('type/daily')
  @ApiOperation({ summary: 'Get daily sales report' })
  @ApiOkResponse({
    description: 'Daily sales report (one row per day).',
    type: DailySalesDataItemDto,
    isArray: true,
  })
  getDailySales(@Query() query: HourlySalesQueryDto): Promise<DailySalesDataItemDto[]> {
    return this.dailySalesReportService.getReport(query);
  }

  @Get('type/monthly')
  @ApiOperation({ summary: 'Get monthly sales report' })
  @ApiOkResponse({
    description: 'Monthly sales report (one row per month, sorted by year and month).',
    type: MonthlySalesDataItemDto,
    isArray: true,
  })
  getMonthlySales(@Query() query: MonthlySalesQueryDto): Promise<MonthlySalesDataItemDto[]> {
    return this.monthlySalesReportService.getReport(query);
  }

  @Get('product-group')
  @ApiOperation({ summary: 'Get product group sales report' })
  @ApiOkResponse({
    description: 'Sales per product group (id, name, totalSales).',
    type: ProductGroupSalesDataItemDto,
    isArray: true,
  })
  getProductGroupSales(
    @Query() query: SalesReportQueryDto,
  ): Promise<ProductGroupSalesDataItemDto[]> {
    return this.productGroupSalesReportService.getReport(query);
  }

  @Get('product')
  @ApiOperation({ summary: 'Get product sales report' })
  @ApiOkResponse({
    description: 'Sales per product (id, name, totalSales).',
    type: ProductSalesDataItemDto,
    isArray: true,
  })
  getProductSales(@Query() query: SalesReportQueryDto): Promise<ProductSalesDataItemDto[]> {
    return this.productSalesReportService.getReport(query);
  }

  @Get('user')
  @ApiOperation({ summary: 'Get user sales report' })
  @ApiOkResponse({
    description: 'Sales per user (id, name, totalSales).',
    type: UserSalesDataItemDto,
    isArray: true,
  })
  getUserSales(@Query() query: SalesReportQueryDto): Promise<UserSalesDataItemDto[]> {
    return this.userSalesReportService.getReport(query);
  }

  @Get('payment')
  @ApiOperation({ summary: 'Get payment method sales report' })
  @ApiOkResponse({
    description: 'Sales per payment method (id, name, totalSales).',
    type: PaymentMethodSalesDataItemDto,
    isArray: true,
  })
  getPaymentSales(@Query() query: SalesReportQueryDto): Promise<PaymentMethodSalesDataItemDto[]> {
    return this.paymentSalesReportService.getReport(query);
  }

  @Get('exportable')
  @ApiOperation({ summary: 'Get aggregated report for unexported transactions on a date' })
  @ApiOkResponse({ type: ExportableReportResponseDto })
  getExportable(@Query() query: ExportableDateQueryDto): Promise<ExportableReportResponseDto> {
    return this.exportableReportService.getExportable(query.date);
  }

  @Patch('mark-exported')
  @ApiOperation({ summary: 'Mark all unexported transactions on a date as exported' })
  @ApiOkResponse({ schema: { example: { updatedCount: 45 } } })
  markExported(@Body() body: MarkExportedBodyDto): Promise<{ updatedCount: number }> {
    return this.exportableReportService.markExported(body.date);
  }

  @Get('cashier-x-reading')
  @ApiOperation({ summary: "Get the current cashier's X Reading (today, self, own terminal)" })
  @ApiOkResponse({ description: 'Cashier X Reading snapshot.', type: CashierXReadingResponseDto })
  getCashierXReading(@CurrentUser() causer: User): Promise<CashierXReadingResponseDto> {
    return this.cashierXReadingReportService.getReport(causer);
  }

  @Post('cashier-x-reading/close')
  @ApiOperation({
    summary:
      'Close the current X Reading window: persists a snapshot and marks the covered ' +
      'transactions as reported',
  })
  @ApiOkResponse({ description: 'Closed X Reading snapshot.', type: CashierXReadingResponseDto })
  closeCashierXReading(@CurrentUser() causer: User): Promise<CashierXReadingResponseDto> {
    return this.cashierXReadingReportService.closeReport(causer);
  }

  @Get('cashier-x-reading/history')
  @ApiOperation({ summary: "List the current cashier's past closed X Readings" })
  @ApiOkResponse({ type: PaginatedResponse(CashierXReadingHistoryItemDto) })
  getCashierXReadingHistory(
    @CurrentUser() causer: User,
    @Query() query: PaginatedQueryDto,
  ): Promise<PaginatedResult<CashierXReadingHistoryItemDto>> {
    return this.cashierXReadingReportService.getHistory(causer, query);
  }

  @Get('cashier-x-reading/history/:id')
  @ApiOperation({ summary: 'Get a past closed X Reading by id' })
  @ApiOkResponse({ description: 'Closed X Reading snapshot.', type: CashierXReadingResponseDto })
  getCashierXReadingHistoryDetail(
    @CurrentUser() causer: User,
    @Param('id') id: string,
  ): Promise<CashierXReadingResponseDto> {
    return this.cashierXReadingReportService.getHistoryDetail(causer, id);
  }

  @Get('cashier-daily-report')
  @ApiOperation({
    summary: "Get the current cashier's daily report (today, self, itemized by product)",
  })
  @ApiOkResponse({ description: 'Cashier daily report.', type: CashierDailyReportResponseDto })
  getCashierDailyReport(@CurrentUser() causer: User): Promise<CashierDailyReportResponseDto> {
    return this.cashierDailyReportService.getReport(causer);
  }

  @Post('cashier-daily-report/close')
  @ApiOperation({
    summary:
      'Close the current daily report window: persists a snapshot and marks the covered ' +
      'transactions as reported',
  })
  @ApiOkResponse({
    description: 'Closed cashier daily report.',
    type: CashierDailyReportResponseDto,
  })
  closeCashierDailyReport(@CurrentUser() causer: User): Promise<CashierDailyReportResponseDto> {
    return this.cashierDailyReportService.closeReport(causer);
  }

  @Get('cashier-daily-report/history')
  @ApiOperation({ summary: "List the current cashier's past closed daily reports" })
  @ApiOkResponse({ type: PaginatedResponse(CashierDailyReportHistoryItemDto) })
  getCashierDailyReportHistory(
    @CurrentUser() causer: User,
    @Query() query: PaginatedQueryDto,
  ): Promise<PaginatedResult<CashierDailyReportHistoryItemDto>> {
    return this.cashierDailyReportService.getHistory(causer, query);
  }

  @Get('cashier-daily-report/history/:id')
  @ApiOperation({ summary: 'Get a past closed cashier daily report by id' })
  @ApiOkResponse({
    description: 'Closed cashier daily report.',
    type: CashierDailyReportResponseDto,
  })
  getCashierDailyReportHistoryDetail(
    @CurrentUser() causer: User,
    @Param('id') id: string,
  ): Promise<CashierDailyReportResponseDto> {
    return this.cashierDailyReportService.getHistoryDetail(causer, id);
  }

  @Get('z-reading')
  @ApiOperation({
    summary: 'Get the store-wide Z-Reading preview (all cashiers, since last Z-Reading close)',
  })
  @ApiOkResponse({ description: 'Z-Reading snapshot.', type: ZReadingResponseDto })
  getZReading(@CurrentUser() causer: User): Promise<ZReadingResponseDto> {
    return this.zReadingReportService.getReport(causer);
  }

  @Post('z-reading/close')
  @ApiOperation({
    summary:
      'Close the store-wide Z-Reading window under supervisor/admin PIN authorization: ' +
      'persists a snapshot, allocates the next Z-counter, and marks the covered transactions ' +
      'as reported',
  })
  @ApiOkResponse({ description: 'Closed Z-Reading snapshot.', type: ZReadingResponseDto })
  closeZReading(
    @CurrentUser() causer: User,
    @Body() body: CloseZReadingDto,
  ): Promise<ZReadingResponseDto> {
    return this.zReadingReportService.closeReport(causer, body.authorizerId, body.pin);
  }

  @Get('z-reading/history')
  @ApiOperation({ summary: 'List past closed Z-Readings, store-wide' })
  @ApiOkResponse({ type: PaginatedResponse(ZReadingHistoryItemDto) })
  getZReadingHistory(
    @Query() query: PaginatedQueryDto,
  ): Promise<PaginatedResult<ZReadingHistoryItemDto>> {
    return this.zReadingReportService.getHistory(query);
  }

  @Get('z-reading/history/:id')
  @ApiOperation({ summary: 'Get a past closed Z-Reading by id' })
  @ApiOkResponse({ description: 'Closed Z-Reading snapshot.', type: ZReadingResponseDto })
  getZReadingHistoryDetail(@Param('id') id: string): Promise<ZReadingResponseDto> {
    return this.zReadingReportService.getHistoryDetail(id);
  }
}
