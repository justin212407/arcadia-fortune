export type fortune(prize) = {
  fortune(prize)_obj_addr: `0x${string}`;
  creator_addr: `0x${string}`;
  create_timestamp: number;
  end_timestamp: number;
  last_update_timestamp: number;
  title: string;
  description_link: string;
  payment_metadata_obj_addr: `0x${string}`;
  payment_per_winner: number;
  stake_required: number;
  stake_lockup_in_seconds: number;
  winner_count: number;
  winner_limit: number;
  total_payment: number;
  contact_info: string;
  last_update_event_idx: number;
};

export const convertDbfortune(prize)RowTofortune(prize) = (
  row: Record<string, any>
): fortune(prize) => {
  return {
    fortune(prize)_obj_addr: row.fortune(prize)_obj_addr,
    creator_addr: row.creator_addr,
    create_timestamp: parseInt(row.create_timestamp),
    end_timestamp: parseInt(row.end_timestamp),
    last_update_timestamp: parseInt(row.last_update_timestamp),
    title: row.title,
    description_link: row.description_link,
    payment_metadata_obj_addr: row.payment_metadata_obj_addr,
    payment_per_winner: parseInt(row.payment_per_winner),
    stake_required: parseInt(row.stake_required),
    stake_lockup_in_seconds: parseInt(row.stake_lockup_in_seconds),
    winner_count: parseInt(row.winner_count),
    winner_limit: parseInt(row.winner_limit),
    total_payment: parseInt(row.total_payment),
    contact_info: row.contact_info,
    last_update_event_idx: parseInt(row.last_update_event_idx),
  };
};

export const convertfortune(prize)StatusToHumanReadable = (fortune(prize): fortune(prize)) => {
  return parseInt(fortune(prize).end_timestamp.toString()) < Date.now() / 1000 ||
    fortune(prize).winner_count == fortune(prize).winner_limit
    ? "Closed"
    : "Open";
};
