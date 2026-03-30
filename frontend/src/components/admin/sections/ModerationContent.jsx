"use client";

import Link from "next/link";
import { Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";

import styles from "@/components/admin/admin.module.css";
import { useAdminAnalytics } from "@/contexts/AdminAnalyticsContext";
import { CHART_COLORS, tooltipContentStyle } from "@/lib/adminChartUtils";

export default function ModerationContent() {
  const { data } = useAdminAnalytics();
  const overview = data?.overview;
  const br = data?.breakdowns;
  if (!br) return null;

  return (
    <>
      <h2 className={styles.pageHeading}>Reports & moderation</h2>
      <p className={styles.pageLead}>
        User reports by workflow status. Pending count is also shown on the overview dashboard. Open the{" "}
        <Link href="/?tab=reported" scroll={false} style={{ color: "#79c0ff" }}>
          reported listings
        </Link>{" "}
        table for inventory with active report counts.
      </p>
      {overview ? (
        <p className={styles.sub} style={{ marginBottom: "1rem" }}>
          Currently <strong style={{ color: "#e8eaed" }}>{overview.reports_pending}</strong> report
          {overview.reports_pending === 1 ? "" : "s"} in <code style={{ color: "#79c0ff" }}>pending</code>{" "}
          status.
        </p>
      ) : null}
      <section className={styles.chartsGrid} aria-label="Report status chart">
        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Reports by status</div>
          <div className={`${styles.chartWrap} ${styles.chartWrapTall}`}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={br.reports_by_status}
                  dataKey="count"
                  nameKey="status"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                >
                  {br.reports_by_status.map((_, i) => (
                    <Cell key={i} fill={CHART_COLORS[(i + 4) % CHART_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={tooltipContentStyle} />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>
    </>
  );
}
