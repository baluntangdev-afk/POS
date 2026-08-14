import { Injectable, Logger } from '@nestjs/common';
import axios, { AxiosError, AxiosInstance } from 'axios';
import { AppConfigService } from '../../config/config.service';

export interface ErpMenuItem {
  sku: string;
  material_id: number;
  recipe_id: number;
  name: string;
  description: string | null;
  category: string | null;
  price: number;
  available_servings: number;
  is_available: boolean;
  recipe_updated_at: string | null;
}

export interface ErpMenuResponse {
  warehouse_id: number;
  warehouse_name: string;
  generated_at: string;
  items: ErpMenuItem[];
}

export interface ErpOrderPayload {
  client_order_id: string;
  order_no?: string;
  terminal?: string;
  store_code?: string;
  order_date?: string;
  items: Array<{ sku: string; quantity: number; unit_price?: number }>;
}

export interface ErpReportPayload {
  report_type: string;
  client_report_id: string;
  store_code?: string;
  terminal_code?: string;
  snapshot: Record<string, unknown>;
}

export interface ErpOrderResult {
  ok: boolean;
  /** True when the failure will never succeed on retry (validation / auth misconfig). */
  permanent: boolean;
  status?: number;
  message?: string;
  data?: unknown;
}

/**
 * Thin authenticated HTTP client for the ERP back office.
 * Logs in with the configured service account and caches the JWT until near expiry.
 */
@Injectable()
export class ErpClientService {
  private readonly logger = new Logger(ErpClientService.name);
  private readonly http: AxiosInstance;
  private token: string | null = null;
  private tokenFetchedAt = 0;

  /** Re-login after 50 minutes (ERP tokens last longer; stay safely under). */
  private static readonly TOKEN_TTL_MS = 50 * 60 * 1000;

  constructor(private readonly config: AppConfigService) {
    this.http = axios.create({ timeout: 15000 });
  }

  get isConfigured(): boolean {
    return Boolean(this.config.erpBaseUrl && this.config.erpUsername && this.config.erpPassword);
  }

  private baseUrl(): string {
    return this.config.erpBaseUrl.replace(/\/+$/, '');
  }

  private async ensureToken(): Promise<string> {
    const fresh = this.token && Date.now() - this.tokenFetchedAt < ErpClientService.TOKEN_TTL_MS;
    if (fresh) return this.token as string;

    const loginPayload: { username?: string; email?: string; password: string } = {
      password: this.config.erpPassword,
    };

    // ERP auth accepts either username or email. Use email when ERP_USERNAME looks like an email.
    if (this.config.erpUsername.includes('@')) {
      loginPayload.email = this.config.erpUsername;
    } else {
      loginPayload.username = this.config.erpUsername;
    }

    const res = await this.http.post(`${this.baseUrl()}/api/auth/login`, loginPayload);

    const token = (res.data as { token?: string })?.token;
    if (!token) throw new Error('ERP login did not return a token');

    this.token = token;
    this.tokenFetchedAt = Date.now();
    return token;
  }

  private invalidateToken(): void {
    this.token = null;
    this.tokenFetchedAt = 0;
  }

  async getMenu(): Promise<ErpMenuResponse> {
    const token = await this.ensureToken();
    try {
      const res = await this.http.get(`${this.baseUrl()}/api/pos/menu`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return res.data as ErpMenuResponse;
    } catch (err) {
      if ((err as AxiosError).response?.status === 401) this.invalidateToken();
      throw err;
    }
  }

  /**
   * Push a confirmed order. The ERP is idempotent on client_order_id,
   * so re-sending after a timeout can never double-deduct.
   */
  async postOrder(payload: ErpOrderPayload): Promise<ErpOrderResult> {
    const token = await this.ensureToken();
    try {
      const res = await this.http.post(`${this.baseUrl()}/api/pos/orders`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return { ok: true, permanent: false, status: res.status, data: res.data };
    } catch (err) {
      const axiosErr = err as AxiosError<{ message?: string }>;
      const status = axiosErr.response?.status;
      const message =
        axiosErr.response?.data?.message ||
        (axiosErr.response?.data ? JSON.stringify(axiosErr.response.data) : axiosErr.message);

      if (status === 401) this.invalidateToken();

      // 400 = bad payload → retrying identical data cannot succeed.
      // 409 = ingredient shortage → could succeed after a restock; keep retrying.
      // Everything else (network, 5xx, 401) is transient.
      const permanent = status === 400;
      this.logger.warn(`ERP order push failed (${status ?? 'network'}): ${message}`);
      return { ok: false, permanent, status, message };
    }
  }

  /**
   * Push a closed X / Daily / Z report snapshot. ERP is idempotent on
   * report_type + client_report_id.
   */
  async postReport(payload: ErpReportPayload): Promise<ErpOrderResult> {
    let token: string;
    try {
      token = await this.ensureToken();
    } catch (err) {
      const message = (err as Error).message || 'ERP login failed';
      this.logger.warn(`ERP report push login failed: ${message}`);
      return { ok: false, permanent: false, message };
    }
    try {
      const res = await this.http.post(`${this.baseUrl()}/api/pos/reports`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return { ok: true, permanent: false, status: res.status, data: res.data };
    } catch (err) {
      const axiosErr = err as AxiosError<{ message?: string }>;
      const status = axiosErr.response?.status;
      const message =
        axiosErr.response?.data?.message ||
        (axiosErr.response?.data ? JSON.stringify(axiosErr.response.data) : axiosErr.message);

      if (status === 401) this.invalidateToken();

      const permanent = status === 400;
      this.logger.warn(`ERP report push failed (${status ?? 'network'}): ${message}`);
      return { ok: false, permanent, status, message };
    }
  }
}
