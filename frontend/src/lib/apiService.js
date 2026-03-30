function normalizeBase(raw) {
  if (raw == null || typeof raw !== "string") return null;
  const t = raw.trim().replace(/\/$/, "");
  return t || null;
}

/**
 * Reads backend origin from env. In the browser this is only available for
 * `NEXT_PUBLIC_*` keys; `frontend/.env` should define `BASE_URL` (mapped in
 * `next.config.mjs`) or `NEXT_PUBLIC_BASE_URL` / `NEXT_PUBLIC_API_URL`.
 */
function readBaseUrlFromEnv() {
  if (typeof process === "undefined") return null;
  return (
    normalizeBase(process.env.NEXT_PUBLIC_BASE_URL) ||
    normalizeBase(process.env.NEXT_PUBLIC_API_URL) ||
    null
  );
}

function extractErrorMessage(body, response) {
  if (!body || typeof body !== "object") {
    return response.statusText || "Request failed";
  }
  if (typeof body.error === "string") return body.error;
  if (body.detail && typeof body.detail === "object" && typeof body.detail.error === "string") {
    return body.detail.error;
  }
  if (typeof body.detail === "string") return body.detail;
  if (typeof body.message === "string") return body.message;
  return response.statusText || "Request failed";
}

/**
 * Single place for HTTP calls to the backend. Paths are relative to {@link ApiService#getBaseUrl}.
 */
export class ApiService {
  /**
   * API origin from `frontend/.env` only (no default). Set `BASE_URL` or
   * `NEXT_PUBLIC_BASE_URL` / `NEXT_PUBLIC_API_URL`.
   */
  getBaseUrl() {
    const url = readBaseUrlFromEnv();
    if (!url) {
      throw new Error(
        "API base URL is missing. Set BASE_URL in frontend/.env (or NEXT_PUBLIC_BASE_URL / NEXT_PUBLIC_API_URL).",
      );
    }
    return url;
  }

  /**
   * @param {string} path - Absolute URL or path starting with `/`
   * @param {object} [options]
   * @param {string} [options.method]
   * @param {Record<string, string>} [options.headers]
   * @param {unknown} [options.body] - Plain object is sent as JSON
   * @param {string} [options.accessToken] - Sets `Authorization: Bearer …`
   * @param {RequestCredentials} [options.credentials] - e.g. `"include"` for cookie auth
   * @param {RequestCache} [options.cache]
   * @returns {Promise<unknown>}
   */
  async request(path, options = {}) {
    const {
      method = "GET",
      headers: extraHeaders = {},
      body,
      accessToken,
      credentials,
      cache = "no-store",
      /** Use current site origin (Next.js), not {@link ApiService#getBaseUrl} — for BFF routes under `/api/`. */
      sameOrigin = false,
    } = options;

    let url;
    if (sameOrigin) {
      if (typeof window === "undefined") {
        throw new Error("sameOrigin requests only run in the browser");
      }
      url = path.startsWith("/") ? path : `/${path}`;
    } else {
      const base = this.getBaseUrl();
      url = path.startsWith("http") ? path : `${base}${path.startsWith("/") ? path : `/${path}`}`;
    }

    /** @type {Record<string, string>} */
    const headers = { Accept: "application/json", ...extraHeaders };

    if (accessToken) {
      headers.Authorization = `Bearer ${accessToken}`;
    }

    /** @type {RequestInit} */
    const init = { method, headers, cache };
    if (credentials !== undefined) {
      init.credentials = credentials;
    }

    if (body !== undefined && body !== null) {
      if (typeof body === "object" && !(body instanceof FormData) && !(body instanceof Blob)) {
        headers["Content-Type"] = headers["Content-Type"] || "application/json";
        init.body = JSON.stringify(body);
      } else {
        init.body = body;
      }
    }

    const res = await fetch(url, init);
    const text = await res.text();
    let parsed = null;
    if (text) {
      try {
        parsed = JSON.parse(text);
      } catch {
        parsed = { raw: text };
      }
    }

    if (!res.ok) {
      const msg = extractErrorMessage(parsed, res);
      const err = new Error(msg);
      err.status = res.status;
      err.body = parsed;
      throw err;
    }

    return parsed;
  }

  /**
   * BFF: GET `/api/admin/go/{path}` → backend `/admin/{path}` with optional query.
   * @param {string} adminPath - e.g. `analytics/overview` (no leading slash)
   * @param {Record<string, string | number | undefined>} [query]
   */
  async adminGo(adminPath, query = {}) {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries(query)) {
      if (v !== undefined && v !== null && v !== "") {
        q.set(k, String(v));
      }
    }
    const qs = q.toString();
    const suffix = qs ? `?${qs}` : "";
    const path = adminPath.replace(/^\//, "");
    return this.request(`/api/admin/go/${path}${suffix}`, { sameOrigin: true });
  }

  admin = {
    getAnalyticsDashboard: (days = 30) =>
      this.request(
        `/api/admin/analytics/dashboard?days=${encodeURIComponent(String(days))}`,
        { sameOrigin: true },
      ),

    getAnalyticsOverview: () => this.adminGo("analytics/overview"),
    getAnalyticsTimeseries: (days = 30) => this.adminGo("analytics/timeseries", { days }),
    getAnalyticsListingsBreakdown: () => this.adminGo("analytics/listings"),
    getAnalyticsPayments: (days = 30) => this.adminGo("analytics/payments", { days }),
    getAnalyticsReports: () => this.adminGo("analytics/reports"),
    getAnalyticsEngagement: () => this.adminGo("analytics/engagement"),

    /** Paginated listings that have at least one report */
    getListingsWithReports: (skip = 0, limit = 50) =>
      this.adminGo("listings/with-reports", { skip, limit }),

    /** Raw report rows (optional filter by listing_id) */
    getReportRows: (params = {}) => this.adminGo("reports/listings", params),

    /** Top listings by report count */
    getReportAggregates: (limit = 50) =>
      this.adminGo("reports/listings/aggregates", { limit }),
  };
}

export const apiService = new ApiService();

/** Same as `apiService.getBaseUrl()` — throws if env is not set. */
export function getApiBase() {
  return apiService.getBaseUrl();
}

/** For UI labels when the URL may be unset (does not throw). */
export function getApiBaseDisplay() {
  return readBaseUrlFromEnv() ?? "not configured — set BASE_URL in frontend/.env";
}
