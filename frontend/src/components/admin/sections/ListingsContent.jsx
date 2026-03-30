"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import styles from "@/components/admin/admin.module.css";
import { useAdminAnalytics } from "@/contexts/AdminAnalyticsContext";
import { CHART_COLORS, tooltipContentStyle } from "@/lib/adminChartUtils";

export default function ListingsContent() {
  const { data } = useAdminAnalytics();
  const br = data?.breakdowns;
  if (!br) return null;

  return (
    <>
      <h2 className={styles.pageHeading}>Listings & catalog</h2>
      <p className={styles.pageLead}>
        Moderation status mix and where inventory concentrates by city and brand.
      </p>
      <section className={styles.chartsGrid} aria-label="Listing breakdown charts">
        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Listings by status</div>
          <div className={`${styles.chartWrap} ${styles.chartWrapTall}`}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={br.listings_by_status}
                  dataKey="count"
                  nameKey="status"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                >
                  {br.listings_by_status.map((_, i) => (
                    <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={tooltipContentStyle} />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Top cities (listings)</div>
          <div className={`${styles.chartWrap} ${styles.chartWrapTall}`}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart layout="vertical" data={br.listings_by_city} margin={{ left: 8, right: 16 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#30363d" />
                <XAxis type="number" tick={{ fill: "#8b949e", fontSize: 11 }} allowDecimals={false} />
                <YAxis type="category" dataKey="city" width={100} tick={{ fill: "#8b949e", fontSize: 11 }} />
                <Tooltip contentStyle={tooltipContentStyle} />
                <Bar dataKey="count" fill="#3b82f6" radius={[0, 4, 4, 0]} name="Listings" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Top brands (listings)</div>
          <div className={`${styles.chartWrap} ${styles.chartWrapTall}`}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart layout="vertical" data={br.listings_by_brand} margin={{ left: 8, right: 16 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#30363d" />
                <XAxis type="number" tick={{ fill: "#8b949e", fontSize: 11 }} allowDecimals={false} />
                <YAxis type="category" dataKey="brand" width={100} tick={{ fill: "#8b949e", fontSize: 11 }} />
                <Tooltip contentStyle={tooltipContentStyle} />
                <Bar dataKey="count" fill="#22c55e" radius={[0, 4, 4, 0]} name="Listings" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>
    </>
  );
}
