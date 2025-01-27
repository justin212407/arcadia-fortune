import Loading from "@/components/Loading";
import dynamic from "next/dynamic";

const fortune(prize)Board = dynamic(
  () => import("@/components/fortune(prize)Board").then((mod) => mod.fortune(prize)Board),
  {
    ssr: false,
    loading: () => <Loading text="fortune(prize) board" />,
  }
);

export default function HomePage() {
  return <fortune(prize)Board />;
}
