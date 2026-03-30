"use client";

import Link from "next/link";
import { useMemo } from "react";

import styles from "@/components/admin/admin.module.css";
import { useAdminAnalytics } from "@/contexts/AdminAnalyticsContext";
import { formatMoney } from "@/lib/adminChartUtils";

export default function OverviewContent() {
  const { data } = useAdminAnalytics();
  const overview = data?.overview;

  const overviewItems = useMemo(() => {
    if (!overview) return [];
    return [
      { label: "Users", value: overview.users_total },
      { label: "Active users", value: overview.users_active },
      { label: "Listings", value: overview.listings_total },
      { label: "Approved listings", value: overview.listings_approved },
      { label: "Messages", value: overview.messages_total },
      { label: "Conversations", value: overview.conversations_total },
      { label: "Favorites", value: overview.favorites_total },
      { label: "Successful payments", value: overview.payments_successful_count },
      {
        label: "Revenue (successful)",
        value: formatMoney(overview.payments_successful_amount),
      },
      { label: "Pending reports", value: overview.reports_pending },
    ];
  }, [overview]);

  if (!overview) return null;

  return (
    <>
      <h2 className={styles.pageHeading}>At a glance</h2>
      <p className={styles.pageLead}>
        Snapshot of users, inventory, engagement, payments, and open moderation work. Use the
        sections below for deeper charts.
      </p>
      <nav className={styles.sectionNav} aria-label="Jump to analytics sections">
        <Link href="/?tab=trends" scroll={false}>
          Activity & trends
        </Link>
        <Link href="/?tab=listings" scroll={false}>
          Listings & catalog
        </Link>
        <Link href="/?tab=payments" scroll={false}>
          Payments
        </Link>
        <Link href="/?tab=moderation" scroll={false}>
          Reports
        </Link>
      </nav>
      <section className={styles.gridOverview} aria-label="Overview metrics">
        {overviewItems.map((item) => (
          <div key={item.label} className={styles.statCard}>
            <div className={styles.statLabel}>{item.label}</div>
            <div className={styles.statValue}>{item.value}</div>
          </div>
        ))}
      </section>
    </>
  );
}
