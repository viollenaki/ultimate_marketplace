import { proxyAdminGet } from "@/lib/adminBackendProxy";

export async function GET(request) {
  return proxyAdminGet(request, "/admin/analytics/dashboard");
}
