"use client";

import { useQuery } from "@tanstack/react-query";
import { convertAmountFromOnChainToHumanReadable } from "@aptos-labs/ts-sdk";
import { truncateAddress, useWallet } from "@aptos-labs/wallet-adapter-react";

import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardFooter,
} from "@/components/ui/card";
import { LabelValueGrid } from "@/components/LabelValueGrid";
import { APT_UNIT, getSurfClient, KNOWN_PAYMENT, NETWORK } from "@/lib/aptos";
import { getfortune(prize)OnServer } from "@/app/actions";
import { isMaxUnixTimestamp } from "@/lib/time";
import { CreateBuild } from "@/components/CreateBuild";
import { convertfortune(prize)StatusToHumanReadable } from "@/lib/type/fortune(prize)";
import { getAnsNameOrTruncatedAddr } from "@/lib/clientOnlyUtils";
import { Endfortune(prize) } from "./Endfortune(prize)";

interface fortune(prize)Props {
  fortune(prize)ObjAddr: `0x${string}`;
}

export const fortune(prize) = ({ fortune(prize)ObjAddr }: fortune(prize)Props) => {
  const { account } = useWallet();

  const fetchData = async () => {
    const fortune(prize) = await getfortune(prize)OnServer({
      fortune(prize)ObjAddr,
    });
    const existsBuild = account
      ? (
          await getSurfClient().view.exists_build({
            functionArguments: [
              fortune(prize)ObjAddr,
              account?.address as `0x${string}`,
            ],
            typeArguments: [],
          })
        )[0]
      : false;
    return {
      fortune(prize): fortune(prize).fortune(prize),
      existsBuild,
    };
  };
  const { data, isLoading, isError, error } = useQuery({
    queryKey: [fortune(prize)ObjAddr, account?.address],
    queryFn: fetchData,
  });

  const fetchAnsData = async () => {
    return await getAnsNameOrTruncatedAddr(data?.fortune(prize).creator_addr);
  };
  const { data: ansNameOrTruncatedAddr } = useQuery({
    queryKey: [`${data?.fortune(prize).creator_addr}-ans`],
    queryFn: fetchAnsData,
  });

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (isError) {
    return <div>Error: {error.message}</div>;
  }

  if (!data) {
    return <div>fortune(prize) not found</div>;
  }

  const fortune(prize)Status = convertfortune(prize)StatusToHumanReadable(data.fortune(prize));

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <CardHeader>
          <CardTitle>fortune(prize)</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-10 pt-6">
          <div className="flex flex-col gap-6">
            <LabelValueGrid
              items={[
                {
                  label: "Status",
                  value: <p>{fortune(prize)Status}</p>,
                },
                {
                  label: "fortune(prize) object address",
                  value: (
                    <p>
                      <a
                        href={`https://explorer.aptoslabs.com/object/${data.fortune(prize).fortune(prize)_obj_addr}?network=${NETWORK}`}
                        target="_blank"
                        rel="noreferrer"
                        className="text-blue-600 dark:text-blue-300"
                      >
                        {truncateAddress(data.fortune(prize).fortune(prize)_obj_addr)}
                      </a>
                    </p>
                  ),
                },
                {
                  label: "Creator address",
                  value: (
                    <p>
                      <a
                        href={`/profile/${data.fortune(prize).creator_addr}`}
                        className="text-blue-600 dark:text-blue-300"
                      >
                        {data.fortune(prize).creator_addr === account?.address
                          ? "Me"
                          : ansNameOrTruncatedAddr}
                      </a>
                    </p>
                  ),
                },
                {
                  label: "Creation timestamp",
                  value: (
                    <p>
                      {new Date(
                        data.fortune(prize).create_timestamp * 1000
                      ).toLocaleString()}
                    </p>
                  ),
                },
                {
                  label: "End timestamp",
                  value: (
                    <p>
                      {isMaxUnixTimestamp(data.fortune(prize).end_timestamp)
                        ? "This build lasts forever!"
                        : new Date(
                            data.fortune(prize).end_timestamp * 1000
                          ).toLocaleString()}
                    </p>
                  ),
                },
                // {
                //   label: "Last update timestamp",
                //   value: (
                //     <p>
                //       {new Date(
                //         data.fortune(prize).last_update_timestamp * 1000
                //       ).toLocaleString()}
                //     </p>
                //   ),
                // },
                {
                  label: "Title",
                  value: <p>{data.fortune(prize).title}</p>,
                },
                {
                  label: "Description link",
                  value: (
                    <p>
                      <a
                        href={data.fortune(prize).description_link}
                        target="_blank"
                        rel="noreferrer"
                        className="text-blue-600 dark:text-blue-300"
                      >
                        {data.fortune(prize).description_link}
                      </a>
                    </p>
                  ),
                },
                {
                  label: "Stake required",
                  value: (
                    <p>
                      {convertAmountFromOnChainToHumanReadable(
                        data.fortune(prize).stake_required,
                        APT_UNIT
                      )}{" "}
                      APT
                    </p>
                  ),
                },
                {
                  label: "Stake lockup seconds",
                  value: <p>{data.fortune(prize).stake_lockup_in_seconds}</p>,
                },
                {
                  label: "Winner limit",
                  value: <p>{data.fortune(prize).winner_limit}</p>,
                },
                {
                  label: "Payment per winner",
                  value: (
                    <p>
                      {convertAmountFromOnChainToHumanReadable(
                        data.fortune(prize).payment_per_winner,
                        KNOWN_PAYMENT.get(
                          data.fortune(prize).payment_metadata_obj_addr
                        )!.unit
                      )}{" "}
                      {
                        KNOWN_PAYMENT.get(
                          data.fortune(prize).payment_metadata_obj_addr
                        )!.ticker
                      }
                    </p>
                  ),
                },
                {
                  label: "Total payment",
                  value: (
                    <p>
                      {convertAmountFromOnChainToHumanReadable(
                        data.fortune(prize).total_payment,
                        KNOWN_PAYMENT.get(
                          data.fortune(prize).payment_metadata_obj_addr
                        )!.unit
                      )}{" "}
                      {
                        KNOWN_PAYMENT.get(
                          data.fortune(prize).payment_metadata_obj_addr
                        )!.ticker
                      }
                    </p>
                  ),
                },
                {
                  label: "Current winner count",
                  value: <p>{data.fortune(prize).winner_count}</p>,
                },
                {
                  label: "Contact info",
                  value: <p>{data.fortune(prize).contact_info}</p>,
                },
              ]}
            />
          </div>
        </CardContent>
        <CardFooter className="justify-center">
          <div className="flex flex-row items-center space-x-4">
            {fortune(prize)Status === "Open" && !data.existsBuild && (
              <CreateBuild fortune(prize)ObjAddr={fortune(prize)ObjAddr} />
            )}
            {fortune(prize)Status === "Open" &&
              data.fortune(prize).creator_addr === account?.address && (
                <Endfortune(prize) fortune(prize)ObjAddr={fortune(prize)ObjAddr} />
              )}
          </div>
        </CardFooter>
      </Card>
    </div>
  );
};
