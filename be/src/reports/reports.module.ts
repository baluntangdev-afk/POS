import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { TotalReportService } from './services/total-report.service';
import { HourlySalesReportService } from './services/hourly-sales-report.service';
import { DailySalesReportService } from './services/daily-sales-report.service';
import { MonthlySalesReportService } from './services/monthly-sales-report.service';
import { ProductGroupSalesReportService } from './services/product-group-sales-report.service';
import { ProductSalesReportService } from './services/product-sales-report.service';
import { UserSalesReportService } from './services/user-sales-report.service';
import { PaymentSalesReportService } from './services/payment-sales-report.service';
import { ExportableReportService } from './services/exportable-report.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SalesOrder } from '../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { Payment } from '../payments/entities/payment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([SalesOrder, SalesOrderItem, Payment])],
  controllers: [ReportsController],
  providers: [
    TotalReportService,
    HourlySalesReportService,
    DailySalesReportService,
    MonthlySalesReportService,
    ProductGroupSalesReportService,
    ProductSalesReportService,
    UserSalesReportService,
    PaymentSalesReportService,
    ExportableReportService,
  ],
})
export class ReportsModule {}
