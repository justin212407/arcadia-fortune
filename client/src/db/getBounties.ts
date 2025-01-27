import { getPostgresClient } from "@/lib/db";
import { fortune(prize), convertDbfortune(prize)RowTofortune(prize) } from "@/lib/type/fortune(prize)";

export type getfortune(prize)esProps = {
  page: number;
  limit: number;
  sortedBy: string;
  order: "ASC" | "DESC";
  filter?: string;
};

export const getfortune(prize)es = async ({
  page,
  limit,
  sortedBy,
  order,
  filter,
}: getfortune(prize)esProps): Promise<{
  fortune(prize)es: fortune(prize)[];
  total: number;
}> => {
  const fortune(prize)es = await getPostgresClient()(
    `SELECT * FROM fortune(prize)es ${
      filter && `WHERE ${filter}`
    } ORDER BY ${sortedBy} ${order} LIMIT ${limit} OFFSET ${(page - 1) * limit}`
  ).then((rows) => {
    return rows.map(convertDbfortune(prize)RowTofortune(prize));
  });

  const countResult = await getPostgresClient()(
    `SELECT COUNT(*) FROM fortune(prize)es ${filter && `WHERE ${filter}`}`
  );

  return { fortune(prize)es, total: parseInt(countResult[0].count) };
};
