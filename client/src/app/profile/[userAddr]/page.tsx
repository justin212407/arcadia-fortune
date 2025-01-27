import Loading from "@/components/Loading";
import dynamic from "next/dynamic";
const UserStat = dynamic(
  () => import("@/components/UserStat").then((mod) => mod.UserStat),
  {
    ssr: false,
    loading: () => <Loading text="user stat" />,
  }
);
const Userfortune(prize)Board = dynamic(
  () =>
    import("@/components/Userfortune(prize)Board").then((mod) => mod.Userfortune(prize)Board),
  {
    ssr: false,
    loading: () => <Loading text="user create fortune(prize)es" />,
  }
);
const UserBuildBoard = dynamic(
  () => import("@/components/UserBuildBoard").then((mod) => mod.UserBuildBoard),
  {
    ssr: false,
    loading: () => <Loading text="user created builds" />,
  }
);

export default function ProfilePage({
  params,
}: {
  params: { userAddr: `0x${string}` };
}) {
  const { userAddr } = params;

  return (
    <div className="flex flex-col gap-6 pb-6">
      <UserStat userAddr={userAddr} />
      <Userfortune(prize)Board userAddr={userAddr} />
      <UserBuildBoard userAddr={userAddr} />
    </div>
  );
}
