"use client";

import { AdminAnalyticsProvider } from "@/contexts/AdminAnalyticsContext";

import AdminChrome from "./AdminChrome";
import HomeAdminTabContent from "./HomeAdminTabContent";

export default function HomeDashboardShell() {
  return (
    <AdminAnalyticsProvider>
      <AdminChrome>
        <HomeAdminTabContent />
      </AdminChrome>
    </AdminAnalyticsProvider>
  );
}
