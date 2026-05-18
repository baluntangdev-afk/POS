/**
 * Abstract base for report services. Ensures every report exposes getReport(query) -> response.
 */
export abstract class BaseReportService<TQuery = unknown, TResponse = unknown> {
  /**
   * Builds and returns the report for the given query.
   */
  abstract getReport(query: TQuery): Promise<TResponse>;
}
