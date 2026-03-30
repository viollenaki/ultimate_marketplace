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
import {
  CHART_COLORS,
  formatDateLabel,
  formatMoney,
  formatTickDate,
  tooltipContentStyle,
} from "@/lib/adminChartUtils";

export default function PaymentsContent() {
  const { data } = useAdminAnalytics();
  const ts = data?.timeseries;
  const br = data?.breakdowns;
  if (!ts || !br) return null;

  return (
    <>
      <h2 className={styles.pageHeading}>Payments</h2>
      <p className={styles.pageLead}>
        Successful payment totals over time and the distribution of payment records by status.
      </p>
      <section className={styles.chartsGrid} aria-label="Payment charts">
        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Successful payment volume per day</div>
          <div className={styles.chartWrap}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={ts.payment_volume_per_day} margin={{ top: 8, right: 8, left: 8, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#30363d" />
                <XAxis dataKey="date" tick={{ fill: "#8b949e", fontSize: 11 }} tickFormatter={formatTickDate} />
                <YAxis tick={{ fill: "#8b949e", fontSize: 11 }} />
                <Tooltip
                  contentStyle={tooltipContentStyle}
                  formatter={(value) => [formatMoney(value), "Amount"]}
                  labelFormatter={(v) => formatDateLabel(v)}
                />
                <Bar dataKey="amount" fill="#a855f7" radius={[4, 4, 0, 0]} name="Amount" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Payments by status</div>
          <div className={`${styles.chartWrap} ${styles.chartWrapTall}`}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={br.payments_by_status}
                  dataKey="count"
                  nameKey="status"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                >
                  {br.payments_by_status.map((_, i) => (
                    <Cell key={i} fill={CHART_COLORS[(i + 2) % CHART_COLORS.length]} />
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
