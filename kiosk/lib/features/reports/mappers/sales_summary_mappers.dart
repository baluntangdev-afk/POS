import '../../../data/backend_api/schemas/sales_summary_dto.dart';
import '../entities/sales_summary.dart';

extension DTOMapper on SalesSummaryDto {
  SalesSummary get toEntity => SalesSummary(
    totalSales: totalSales,
    totalDiscount: totalDiscount,
    totalRefunds: totalRefunds,
    totalItems: totalItems,
    totalTransactions: totalTransactions,
  );
}

extension EntityMapper on SalesSummary {
  SalesSummaryDto get toModel => SalesSummaryDto(
    totalSales: totalSales,
    totalDiscount: totalDiscount,
    totalRefunds: totalRefunds,
    totalItems: totalItems,
    totalTransactions: totalTransactions,
  );
}
