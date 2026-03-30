import { format, parseISO } from "date-fns";

export const CHART_COLORS = [
  "#6366f1",
  "#14b8a6",
  "#f59e0b",
  "#ef4444",
  "#a855f7",
  "#22c55e",
  "#3b82f6",
  "#ec4899",
];

export const tooltipContentStyle = {
  background: "#161b22",
  border: "1px solid #30363d",
};

export function formatTickDate(v) {
  try {
    return format(parseISO(v), "MMM d");
  } catch {
    return v;
  }
}

export function formatDateLabel(v) {
  try {
    return format(parseISO(v), "PP");
  } catch {
    return v;
  }
}

export function formatMoney(n) {
  if (n == null || Number.isNaN(n)) return "—";
  return new Intl.NumberFormat(undefined, {
    maximumFractionDigits: 0,
  }).format(n);
}
