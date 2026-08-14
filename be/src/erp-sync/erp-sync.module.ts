import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '../config/config.module';
import { Product } from '../products/entities/product.entity';
import { ProductGroup } from '../product-groups/entities/product-group.entity';
import { ProductVariant } from '../products/entities/product-variant.entity';
import { SalesOrder } from '../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { User } from '../users/entities/user.entity';
import { ErpOrderPush } from './entities/erp-order-push.entity';
import { ErpReportPush } from './entities/erp-report-push.entity';
import { ErpSyncController } from './erp-sync.controller';
import { ErpClientService } from './services/erp-client.service';
import { ErpMenuSyncService } from './services/erp-menu-sync.service';
import { ErpOrderPushService } from './services/erp-order-push.service';
import { ErpReportPushService } from './services/erp-report-push.service';
import { ErpLocalStockService } from './services/erp-local-stock.service';
import { CashierDailyReport } from '../reports/entities/cashier-daily-report.entity';
import { CashierXReading } from '../reports/entities/cashier-x-reading.entity';
import { ZReading } from '../reports/entities/z-reading.entity';

/**
 * ERP back-office integration: menu/price/availability sync (pull),
 * confirmed-order push, and closed report snapshot push with retry queues.
 */
@Module({
  imports: [
    ConfigModule,
    TypeOrmModule.forFeature([
      Product,
      ProductGroup,
      ProductVariant,
      SalesOrder,
      SalesOrderItem,
      User,
      ErpOrderPush,
      ErpReportPush,
      CashierXReading,
      CashierDailyReport,
      ZReading,
    ]),
  ],
  controllers: [ErpSyncController],
  providers: [
    ErpClientService,
    ErpMenuSyncService,
    ErpOrderPushService,
    ErpReportPushService,
    ErpLocalStockService,
  ],
  exports: [ErpClientService, ErpMenuSyncService, ErpOrderPushService, ErpReportPushService],
})
export class ErpSyncModule {}
