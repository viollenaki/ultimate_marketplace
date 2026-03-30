import { NextResponse } from "next/server";

export function backendBaseUrl() {
  const raw =
    process.env.BASE_URL ||
    process.env.NEXT_PUBLIC_BASE_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    "";
  return raw.trim().replace(/\/$/, "");
}

/**
 * Forward GET to FastAPI `/admin/...` with the same query string.
 * @param {Request} request
 * @param {string} adminPath - e.g. `/admin/analytics/overview`
 */
export async function proxyAdminGet(request, adminPath) {
  const base = backendBaseUrl();
  if (!base) {
    return NextResponse.json(
      { error: "Backend URL missing: set BASE_URL or NEXT_PUBLIC_API_URL" },
      { status: 503 },
    );
  }

  const incoming = new URL(request.url);
  const path = adminPath.startsWith("/") ? adminPath : `/${adminPath}`;
  const url = `${base}${path}${incoming.search}`;

  const res = await fetch(url, {
    method: "GET",
    headers: { Accept: "application/json" },
    cache: "no-store",
  });

  const text = await res.text();
  let body;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = { error: "Invalid JSON from backend", raw: text };
  }

  return NextResponse.json(body, { status: res.status });
}
