"use client";

import { useQuery } from "@tanstack/react-query";

import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { LabelValueGrid } from "@/components/LabelValueGrid";
import { NETWORK } from "@/lib/aptos";
import { getBuildOnServer } from "@/app/actions";
import { convertBuildStatusToHumanReadable } from "@/lib/type/build";
import { SubmitBuildForReview } from "@/components/SubmitBuildForReview";
import { truncateAddress, useWallet } from "@aptos-labs/wallet-adapter-react";
import { getAnsNameOrTruncatedAddr } from "@/lib/clientOnlyUtils";

interface BuildProps {
  buildObjAddr: `0x${string}`;
}

export const Build = ({ buildObjAddr }: BuildProps) => {
  const { connected, account } = useWallet();
  const fetchData = async () => {
    return await getBuildOnServer({
      buildObjAddr,
    });
  };

  const { data, isLoading, isError, error } = useQuery({
    queryKey: [buildObjAddr],
    queryFn: fetchData,
  });

  const fetchAnsData = async () => {
    return await getAnsNameOrTruncatedAddr(data?.build.creator_addr);
  };
  const { data: ansNameOrTruncatedAddr } = useQuery({
    queryKey: [`${data?.build.creator_addr}-ans`],
    queryFn: fetchAnsData,
  });

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (isError) {
    return <div>Error: {error.message}</div>;
  }

  if (!data) {
    return <div>Build not found</div>;
  }

  const buildStatus = convertBuildStatusToHumanReadable(data.build);

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Build</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-10 pt-6">
          <div className="flex flex-col gap-6">
            <LabelValueGrid
              items={[
                {
                  label: "Status",
                  value: <p>{buildStatus}</p>,
                },
                {
                  label: "Build object address",
                  value: (
                    <p>
                      <a
                        href={`https://explorer.aptoslabs.com/object/${data.build.build_obj_addr}?network=${NETWORK}`}
                        target="_blank"
                        rel="noreferrer"
                        className="text-blue-600 dark:text-blue-300"
                      >
                        {truncateAddress(data.build.build_obj_addr)}
                      </a>
                    </p>
                  ),
                },
                {
                  label: "fortune(prize)",
                  value: (
                    <p>
                      <a
                        href={`/fortune(prize)/${data.build.fortune(prize)_obj_addr}`}
                        target="_blank"
                        rel="noreferrer"
                        className="text-blue-600 dark:text-blue-300"
                      >
                        View detail
                      </a>
                    </p>
                  ),
                },
                {
                  label: "Creator address",
                  value: (
                    <p>
                      <a
                        href={`/profile/${data.build.creator_addr}`}
                        className="text-blue-600 dark:text-blue-300"
                      >
                        {data.build.creator_addr == account?.address
                          ? "Me"
                          : ansNameOrTruncatedAddr}
                      </a>
                    </p>
                  ),
                },
                {
                  label: "Payment recipient address",
                  value: (
                    <p>
                      {data.build.payment_recipient_addr ===
                      data.build.creator_addr ? (
                        "Same as creator"
                      ) : (
                        <a
                          href={`/profile/${data.build.payment_recipient_addr}?network=${NETWORK}`}
                          target="_blank"
                          rel="noreferrer"
                          className="text-blue-600 dark:text-blue-300"
                        >
                          {data.build.payment_recipient_addr}
                        </a>
                      )}
                    </p>
                  ),
                },
                {
                  label: "Creation timestamp",
                  value: (
                    <p>
                      {new Date(
                        data.build.create_timestamp * 1000
                      ).toLocaleString()}
                    </p>
                  ),
                },
                {
                  label: "Last update timestamp",
                  value: (
                    <p>
                      {new Date(
                        data.build.last_update_timestamp * 1000
                      ).toLocaleString()}
                    </p>
                  ),
                },

                {
                  label: "Proof link",
                  value: (
                    <p>
                      {data.build.proof_link === "" ? (
                        "Unavailable"
                      ) : (
                        <a
                          href={data.build.proof_link}
                          target="_blank"
                          rel="noreferrer"
                          className="text-blue-600 dark:text-blue-300"
                        >
                          {data.build.proof_link}
                        </a>
                      )}
                    </p>
                  ),
                },
              ]}
            />
          </div>
        </CardContent>
      </Card>
      {connected &&
        buildStatus === "In progress" &&
        data.build.creator_addr === account?.address && (
          <SubmitBuildForReview build={data.build} />
        )}
    </div>
  );
};
