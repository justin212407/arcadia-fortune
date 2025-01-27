import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { DataTable } from "@/components/analytic-board-fortune(prize)-creator/data-table";
import { columns } from "@/components/analytic-board-fortune(prize)-creator/columns";

export const Analyticsfortune(prize)Creator = async () => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>fortune(prize) creator leaderboard</CardTitle>
      </CardHeader>
      <CardContent className="h-full flex-1 flex-col space-y-8 p-8 flex">
        <DataTable columns={columns} />
      </CardContent>
    </Card>
  );
};
