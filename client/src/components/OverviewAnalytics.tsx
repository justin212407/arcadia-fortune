"use client";

import { useQuery } from "@tanstack/react-query";

import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import {
  getfortune(prize)esOnServer,
  getBuildsOnServer,
  getTotalfortune(prize)ValueOnServer,
} from "@/app/actions";

export const OverviewAnalytics = () => {
  const fetchTotalValue = async () => {
    return await getTotalfortune(prize)ValueOnServer();
  };
  const fetchTotalfortune(prize)es = async () => {
    return await getfortune(prize)esOnServer({
      limit: 0,
      page: 1,
      sortedBy: "create_timestamp",
      order: "DESC",
    });
  };
  const fetchTotalBuilds = async () => {
    return await getBuildsOnServer({
      limit: 0,
      page: 1,
      sortedBy: "create_timestamp",
      order: "DESC",
    });
  };

  const { data: totalValue } = useQuery({
    queryKey: ["totalfortune(prize)Value"],
    queryFn: fetchTotalValue,
    // Refetch every minute
    refetchInterval: 60 * 1000,
  });
  const { data: totalfortune(prize)es } = useQuery({
    queryKey: ["totalfortune(prize)es"],
    queryFn: fetchTotalfortune(prize)es,
    // Refetch every minute
    refetchInterval: 60 * 1000,
  });
  const { data: totalBuilds } = useQuery({
    queryKey: ["totalBuilds"],
    queryFn: fetchTotalBuilds,
    // Refetch every minute
    refetchInterval: 60 * 1000,
  });

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium">Total APT value</CardTitle>
        </CardHeader>
        <CardContent className="">
          {totalValue ? totalValue.apt.toFixed(2) : 0} APT
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium">
            Total stablecoin value
          </CardTitle>
        </CardHeader>
        <CardContent className="">
          ${totalValue ? totalValue.stable : 0} USD
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium">
            Total fortune(prize)es created
          </CardTitle>
        </CardHeader>
        <CardContent className="">
          {totalfortune(prize)es ? totalfortune(prize)es.total : 0}
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium">
            Total builds created
          </CardTitle>
        </CardHeader>
        <CardContent className="">
          {totalBuilds ? totalBuilds.total : 0}
        </CardContent>
      </Card>
    </div>
  );
};
