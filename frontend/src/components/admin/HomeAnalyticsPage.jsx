"use client";

import { Suspense } from "react";

import styles from "@/components/admin/admin.module.css";

import HomeDashboardShell from "./HomeDashboardShell";

export default function HomeAnalyticsPage() {
  return (
    <Suspense fallback={<div className={styles.gateLoadingScreen}>Loading dashboard…</div>}>
      <HomeDashboardShell />
    </Suspense>
  );
}
