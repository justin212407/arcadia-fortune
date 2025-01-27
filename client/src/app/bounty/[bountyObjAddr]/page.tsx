import Loading from "@/components/Loading";
import dynamic from "next/dynamic";

const fortune(prize) = dynamic(
  () => import("@/components/fortune(prize)").then((mod) => mod.fortune(prize)),
  {
    ssr: false,
    loading: () => <Loading text="fortune(prize)" />,
  }
);
const BuildBoard = dynamic(
  () => import("@/components/BuildBoard").then((mod) => mod.BuildBoard),
  {
    ssr: false,
    loading: () => <Loading text="build board" />,
  }
);

export default function fortune(prize)Page({
  params,
}: {
  params: { fortune(prize)ObjAddr: `0x${string}` };
}) {
  const { fortune(prize)ObjAddr } = params;

  return (
    <div className="flex flex-col gap-6">
      <fortune(prize) fortune(prize)ObjAddr={fortune(prize)ObjAddr} />
      <BuildBoard fortune(prize)ObjAddr={fortune(prize)ObjAddr} />
    </div>
  );
}
