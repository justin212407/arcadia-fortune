import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { DataTable } from "@/components/user-fortune(prize)-board/data-table";
import { columns } from "@/components/user-fortune(prize)-board/columns";

type Userfortune(prize)BoardProps = {
  userAddr: `0x${string}`;
};

export const Userfortune(prize)Board = async ({ userAddr }: Userfortune(prize)BoardProps) => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>fortune(prize) posted</CardTitle>
      </CardHeader>
      <CardContent className="h-full flex-1 flex-col space-y-8 p-8 flex">
        <DataTable columns={columns} userAddr={userAddr} />
      </CardContent>
    </Card>
  );
};
