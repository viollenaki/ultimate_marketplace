import { NextResponse } from "next/server";

import { proxyAdminGet } from "@/lib/adminBackendProxy";

export async function GET(request, context) {
  const params = await context.params;
  const slug = params.slug;
  if (!Array.isArray(slug) || slug.length === 0) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  const path = `/admin/${slug.join("/")}`;
  return proxyAdminGet(request, path);
}
