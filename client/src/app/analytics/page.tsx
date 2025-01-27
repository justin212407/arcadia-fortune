import Loading from "@/components/Loading";
import dynamic from "next/dynamic";

const Analyticsfortune(prize)Creator = dynamic(
  () =>
    import("@/components/Analyticsfortune(prize)Creator").then(
      (mod) => mod.Analyticsfortune(prize)Creator
    ),
  {
    ssr: false,
    loading: () => <Loading text="fortune(prize) creator analytics" />,
  }
);
const AnalyticsBuilder = dynamic(
  () =>
    import("@/components/AnalyticsBuilder").then((mod) => mod.AnalyticsBuilder),
  {
    ssr: false,
    loading: () => <Loading text="builder analytics" />,
  }
);
const OverviewAnalytics = dynamic(
  () =>
    import("@/components/OverviewAnalytics").then(
      (mod) => mod.OverviewAnalytics
    ),
  {
    ssr: false,
    loading: () => <Loading text="high level stats" />,
  }
);

export default function AnalyticsPage() {
  return (
    <div className="flex flex-col gap-6">
      <OverviewAnalytics />
      <Analyticsfortune(prize)Creator />
      <AnalyticsBuilder />
    </div>
  );
}
