"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { apiService } from "@/lib/apiService";

const AdminAnalyticsContext = createContext(null);

export function AdminAnalyticsProvider({ children }) {
  const [days, setDays] = useState(30);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const loadDashboard = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const d = await apiService.admin.getAnalyticsDashboard(days);
      setData(d);
    } catch (e) {
      setData(null);
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [days]);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  const value = useMemo(
    () => ({
      days,
      setDays,
      data,
      loading,
      error,
      refresh: loadDashboard,
    }),
    [days, data, loading, error, loadDashboard],
  );

  return (
    <AdminAnalyticsContext.Provider value={value}>{children}</AdminAnalyticsContext.Provider>
  );
}

export function useAdminAnalytics() {
  const ctx = useContext(AdminAnalyticsContext);
  if (!ctx) {
    throw new Error("useAdminAnalytics must be used within AdminAnalyticsProvider");
  }
  return ctx;
}
