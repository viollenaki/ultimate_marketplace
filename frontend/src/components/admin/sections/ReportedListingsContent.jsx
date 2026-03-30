"use client";

import { useCallback, useEffect, useState } from "react";

import styles from "@/components/admin/admin.module.css";
import { apiService } from "@/lib/apiService";

const PAGE_SIZE = 25;

function formatMoney(price, currency) {
  try {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: currency || "KGS",
      maximumFractionDigits: 0,
    }).format(price);
  } catch {
    return `${price} ${currency || ""}`;
  }
}

function formatDate(iso) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString();
  } catch {
    return iso;
  }
}

export default function ReportedListingsContent() {
  const [skip, setSkip] = useState(0);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await apiService.admin.getListingsWithReports(skip, PAGE_SIZE);
      setData(res);
    } catch (e) {
      setData(null);
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [skip]);

  useEffect(() => {
    load();
  }, [load]);

  const total = data?.total ?? 0;
  const items = data?.items ?? [];
  const page = Math.floor(skip / PAGE_SIZE) + 1;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <>
      <h2 className={styles.pageHeading}>Listings with reports</h2>
      <p className={styles.pageLead}>
        Inventory that has at least one user report, sorted by report count. Use this with the raw
        report log under <strong style={{ color: "#c9d1d9" }}>Reports</strong> charts.
      </p>

      {error ? <p className={styles.error}>{error}</p> : null}
      {loading ? <p className={styles.sub}>Loading…</p> : null}

      {!loading && !error && data ? (
        <>
          <p className={styles.tableMeta}>
            Showing {items.length} of {total} listing{total === 1 ? "" : "s"} with reports
            (page {page} / {totalPages}).
          </p>
          <div className={styles.tableWrap}>
            <table className={styles.dataTable}>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Title</th>
                  <th>City</th>
                  <th>Status</th>
                  <th>Price</th>
                  <th>Owner</th>
                  <th>Reports</th>
                  <th>Pending</th>
                  <th>Last report</th>
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={9} style={{ color: "#8b949e" }}>
                      No listings with reports.
                    </td>
                  </tr>
                ) : (
                  items.map((row) => (
                    <tr key={row.listing_id}>
                      <td>{row.listing_id}</td>
                      <td>{row.title}</td>
                      <td>{row.city}</td>
                      <td>{row.status}</td>
                      <td>{formatMoney(row.price, row.currency)}</td>
                      <td>{row.owner_id}</td>
                      <td>{row.report_count}</td>
                      <td>{row.pending_report_count}</td>
                      <td>{formatDate(row.last_report_at)}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <div className={styles.pager}>
            <button
              type="button"
              disabled={skip <= 0 || loading}
              onClick={() => setSkip((s) => Math.max(0, s - PAGE_SIZE))}
            >
              Previous
            </button>
            <button
              type="button"
              disabled={skip + PAGE_SIZE >= total || loading}
              onClick={() => setSkip((s) => s + PAGE_SIZE)}
            >
              Next
            </button>
          </div>
        </>
      ) : null}
    </>
  );
}
