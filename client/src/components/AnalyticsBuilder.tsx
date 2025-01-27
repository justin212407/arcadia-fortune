import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { DataTable } from "@/components/analytic-board-builder/data-table";
import { columns } from "@/components/analytic-board-builder/columns";

export const AnalyticsBuilder = async () => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Builder leaderboard</CardTitle>
      </CardHeader>
      <CardContent className="h-full flex-1 flex-col space-y-8 p-8 flex">
        <DataTable columns={columns} />
      </CardContent>
    </Card>
  );
};
