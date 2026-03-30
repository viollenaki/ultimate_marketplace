"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import styles from "@/components/admin/admin.module.css";
import { useAdminAnalytics } from "@/contexts/AdminAnalyticsContext";
import {
  formatDateLabel,
  formatMoney,
  formatTickDate,
  tooltipContentStyle,
} from "@/lib/adminChartUtils";

export default function TrendsContent() {
  const { data } = useAdminAnalytics();
  const ts = data?.timeseries;
  if (!ts) return null;

  return (
    <>
      <h2 className={styles.pageHeading}>Activity & trends</h2>
      <p className={styles.pageLead}>
        Daily new listings and users, message volume, and successful payment amounts over the
        selected window.
      </p>
      <section className={styles.chartsGrid} aria-label="Trend charts">
        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>New listings per day</div>
          <div className={styles.chartWrap}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={ts.listings_per_day} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#30363d" />
                <XAxis dataKey="date" tick={{ fill: "#8b949e", fontSize: 11 }} tickFormatter={formatTickDate} />
                <YAxis tick={{ fill: "#8b949e", fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={tooltipContentStyle}
                  labelFormatter={(v) => formatDateLabel(v)}
                />
                <Line type="monotone" dataKey="count" stroke="#6366f1" strokeWidth={2} dot={false} name="Listings" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>New users per day</div>
          <div className={styles.chartWrap}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={ts.users_per_day} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#30363d" />
                <XAxis dataKey="date" tick={{ fill: "#8b949e", fontSize: 11 }} tickFormatter={formatTickDate} />
                <YAxis tick={{ fill: "#8b949e", fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={tooltipContentStyle}
                  labelFormatter={(v) => formatDateLabel(v)}
                />
                <Line type="monotone" dataKey="count" stroke="#14b8a6" strokeWidth={2} dot={false} name="Users" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className={styles.chartCard}>
          <div className={styles.chartTitle}>Messages per day</div>
          <div className={styles.chartWrap}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={ts.messages_per_day} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#30363d" />
                <XAxis dataKey="date" tick={{ fill: "#8b949e", fontSize: 11 }} tickFormatter={formatTickDate} />
                <YAxis tick={{ fill: "#8b949e", fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  contentStyle={tooltipContentStyle}
                  labelFormatter={(v) => formatDateLabel(v)}
                />
                <Line type="monotone" dataKey="count" stroke="#f59e0b" strokeWidth={2} dot={false} name="Messages" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

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
      </section>
    </>
  );
}
