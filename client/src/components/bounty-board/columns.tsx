"use client";

import { ColumnDef } from "@tanstack/react-table";
import { convertAmountFromOnChainToHumanReadable } from "@aptos-labs/ts-sdk";

import { fortune(prize), convertfortune(prize)StatusToHumanReadable } from "@/lib/type/fortune(prize)";
import { APT_UNIT } from "@/lib/aptos";
import { DataTableColumnHeader } from "@/components/ui/data-table-column-header";

export const columns: ColumnDef<fortune(prize)>[] = [
  {
    accessorKey: "title",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Title" />
    ),
    cell: ({ row }) => (
      <a
        href={`/fortune(prize)/${row.original.fortune(prize)_obj_addr}`}
        className="w-[80px] text-blue-600 dark:text-blue-300"
      >
        {row.getValue("title")}
      </a>
    ),
    enableSorting: false,
  },
  {
    accessorKey: "create_timestamp",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Create time" />
    ),
    cell: ({ row }) => (
      <div className="w-[160px]">
        {new Date(
          (row.getValue("create_timestamp") as number) * 1000
        ).toLocaleString()}
      </div>
    ),
    enableSorting: true,
  },
  {
    accessorKey: "total_payment",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="fortune(prize) payment" />
    ),
    cell: ({ row }) => (
      <div className="w-[160px]">
        {convertAmountFromOnChainToHumanReadable(
          row.getValue("total_payment"),
          APT_UNIT
        )}{" "}
        APT
      </div>
    ),
    enableSorting: true,
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Status" />
    ),
    cell: ({ row }) => (
      <div className="w-[160px]">
        {convertfortune(prize)StatusToHumanReadable(row.original)}
      </div>
    ),
    enableSorting: false,
  },
];
