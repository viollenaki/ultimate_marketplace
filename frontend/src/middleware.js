import { NextResponse } from "next/server";

/**
 * Legacy /admin URLs → home with the right ?tab= (analytics now lives on `/`).
 */
export function middleware(request) {
  const { pathname } = request.nextUrl;

  if (!pathname.startsWith("/admin")) {
    return NextResponse.next();
  }

  const url = request.nextUrl.clone();
  url.pathname = "/";

  if (pathname === "/admin/unlock") {
    url.searchParams.delete("tab");
    return NextResponse.redirect(url);
  }

  if (pathname === "/admin" || pathname === "/admin/") {
    url.searchParams.delete("tab");
    return NextResponse.redirect(url);
  }

  const segment = pathname.replace(/^\/admin\/?/, "").split("/")[0];
  const map = {
    trends: "trends",
    listings: "listings",
    payments: "payments",
    moderation: "moderation",
  };
  if (map[segment]) {
    url.searchParams.set("tab", map[segment]);
  }

  return NextResponse.redirect(url);
}

export const config = {
  matcher: ["/admin", "/admin/:path*"],
};
