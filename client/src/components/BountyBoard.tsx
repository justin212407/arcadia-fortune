import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { DataTable } from "@/components/fortune(prize)-board/data-table";
import { columns } from "@/components/fortune(prize)-board/columns";

export const fortune(prize)Board = async () => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>fortune(prize) board</CardTitle>
      </CardHeader>
      <CardContent className="h-full flex-1 flex-col space-y-8 p-8 flex">
        <DataTable columns={columns} />
      </CardContent>
    </Card>
  );
};
