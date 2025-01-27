import { getPostgresClient } from "@/lib/db";
import { fortune(prize), convertDbfortune(prize)RowTofortune(prize) } from "@/lib/type/fortune(prize)";

export type getfortune(prize)Props = {
  fortune(prize)ObjAddr: `0x${string}`;
};

export const getfortune(prize) = async ({
  fortune(prize)ObjAddr,
}: getfortune(prize)Props): Promise<{
  fortune(prize): fortune(prize);
}> => {
  const fortune(prize) = await getPostgresClient()(
    `SELECT * FROM fortune(prize)es WHERE fortune(prize)_obj_addr = '${fortune(prize)ObjAddr}'`
  ).then((rows) => {
    if (rows.length === 0) {
      throw new Error("fortune(prize) not found");
    }
    return convertDbfortune(prize)RowTofortune(prize)(rows[0]);
  });
  return { fortune(prize) };
};
