"use client";

import styles from "@/components/admin/admin.module.css";
import { useAdminAnalytics } from "@/contexts/AdminAnalyticsContext";

export default function AdminDataGate({ children }) {
  const { data, loading, error } = useAdminAnalytics();
  if (loading && !data) {
    return <p className={styles.sub}>Loading metrics…</p>;
  }
  if (error && !data) {
    return <p className={styles.error}>{error}</p>;
  }
  if (!data) {
    return <p className={styles.sub}>No data yet. Adjust the time window and refresh.</p>;
  }

  return children;
}
