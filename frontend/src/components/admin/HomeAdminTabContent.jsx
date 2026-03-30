"use client";

import { useSearchParams } from "next/navigation";
import { useMemo } from "react";

import AdminDataGate from "@/components/admin/AdminDataGate";
import ListingsContent from "@/components/admin/sections/ListingsContent";
import ModerationContent from "@/components/admin/sections/ModerationContent";
import OverviewContent from "@/components/admin/sections/OverviewContent";
import PaymentsContent from "@/components/admin/sections/PaymentsContent";
import ReportedListingsContent from "@/components/admin/sections/ReportedListingsContent";
import TrendsContent from "@/components/admin/sections/TrendsContent";

const VALID_TABS = new Set([
  "overview",
  "trends",
  "listings",
  "payments",
  "moderation",
  "reported",
]);

export default function HomeAdminTabContent() {
  const searchParams = useSearchParams();
  const raw = searchParams.get("tab") || "overview";
  const tab = VALID_TABS.has(raw) ? raw : "overview";

  const panel = useMemo(() => {
    switch (tab) {
      case "trends":
        return <TrendsContent />;
      case "listings":
        return <ListingsContent />;
      case "payments":
        return <PaymentsContent />;
      case "moderation":
        return <ModerationContent />;
      case "reported":
        return <ReportedListingsContent />;
      default:
        return <OverviewContent />;
    }
  }, [tab]);

  return <AdminDataGate>{panel}</AdminDataGate>;
}
