"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";

import styles from "@/components/admin/admin.module.css";
import { useAdminAnalytics } from "@/contexts/AdminAnalyticsContext";

const TABS = [
  { id: "overview", label: "Overview", href: "/" },
  { id: "trends", label: "Activity & trends", href: "/?tab=trends" },
  { id: "listings", label: "Listings & catalog", href: "/?tab=listings" },
  { id: "payments", label: "Payments", href: "/?tab=payments" },
  { id: "moderation", label: "Reports", href: "/?tab=moderation" },
  { id: "reported", label: "Reported listings", href: "/?tab=reported" },
];

const VALID = new Set(TABS.map((t) => t.id));

export default function AdminChrome({ children }) {
  const searchParams = useSearchParams();
  const raw = searchParams.get("tab") || "overview";
  const active = VALID.has(raw) ? raw : "overview";
  const { days, setDays, loading, refresh, error } = useAdminAnalytics();

  return (
    <div className={styles.layoutShell}>
      <aside className={styles.sidebar} aria-label="Admin navigation">
        <div className={styles.sidebarBrand}>Analytics</div>
        <ul className={styles.navList}>
          {TABS.map(({ id, label, href }) => (
            <li key={id}>
              <Link
                href={href}
                scroll={false}
                className={`${styles.navLink} ${active === id ? styles.navLinkActive : ""}`}
              >
                {label}
              </Link>
            </li>
          ))}
        </ul>
        <div className={styles.sidebarFooter}>Ultimate marketplace</div>
      </aside>
      <div className={styles.mainColumn}>
        <header className={styles.topBar}>
          <div>
            <h1 className={styles.title}>Marketplace analytics</h1>
            <p className={styles.sub}>Read-only aggregates for review and planning</p>
          </div>
          <div className={styles.actions}>
            <label className={styles.sub} htmlFor="adm-days">
              Window
            </label>
            <select
              id="adm-days"
              className={styles.daysSelect}
              value={days}
              onChange={(ev) => setDays(Number(ev.target.value))}
            >
              <option value={7}>7 days</option>
              <option value={14}>14 days</option>
              <option value={30}>30 days</option>
              <option value={90}>90 days</option>
              <option value={180}>180 days</option>
              <option value={366}>1 year</option>
            </select>
            <button type="button" className={styles.button} onClick={refresh} disabled={loading}>
              {loading ? "Loading…" : "Refresh"}
            </button>
          </div>
        </header>
        {error ? <p className={styles.error}>{error}</p> : null}
        {children}
      </div>
    </div>
  );
}
