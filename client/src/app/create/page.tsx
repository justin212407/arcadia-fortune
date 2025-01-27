import Loading from "@/components/Loading";
import dynamic from "next/dynamic";

const Createfortune(prize) = dynamic(
  () => import("@/components/Createfortune(prize)").then((mod) => mod.Createfortune(prize)),
  {
    ssr: false,
    loading: () => <Loading text="create fortune(prize) form" />,
  }
);

export default function Createfortune(prize)Page() {
  return <Createfortune(prize) />;
}
