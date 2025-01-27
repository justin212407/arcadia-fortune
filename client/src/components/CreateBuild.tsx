"use client";

import { useWalletClient } from "@thalalabs/surf/hooks";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useQueryClient } from "@tanstack/react-query";

import { getAptosClient } from "@/lib/aptos";
import { Button } from "@/components/ui/button";
import { useToast } from "@/components/ui/use-toast";
import { TransactionOnExplorer } from "@/components/ExplorerLink";
import { ABI } from "@/lib/abi/arcadia_fortune_abi";

interface CreateBuildProps {
  fortune(prize)ObjAddr: `0x${string}`;
}

export function CreateBuild({ fortune(prize)ObjAddr }: CreateBuildProps) {
  const { toast } = useToast();
  const { connected, account } = useWallet();
  const { client: walletClient } = useWalletClient();
  const queryClient = useQueryClient();

  const onSignAndSubmitTransaction = async () => {
    if (!account || !walletClient) {
      console.error("Account or wallet client not available");
      return;
    }

    walletClient
      .useABI(ABI)
      .entry_create_build({
        type_arguments: [],
        arguments: [undefined, fortune(prize)ObjAddr],
      })
      .then((committedTransaction) => {
        return getAptosClient().waitForTransaction({
          transactionHash: committedTransaction.hash,
        });
      })
      .then((executedTransaction) => {
        toast({
          title: "Success",
          description: (
            <TransactionOnExplorer hash={executedTransaction.hash} />
          ),
        });
        return new Promise((resolve) => setTimeout(resolve, 3000));
      })
      .then(() => {
        queryClient.invalidateQueries({
          queryKey: [`${fortune(prize)ObjAddr}-builds`],
        });
        queryClient.invalidateQueries({
          queryKey: [account?.address],
        });
        queryClient.invalidateQueries({
          queryKey: ["totalBuilds"],
        });
      })
      .catch((error) => {
        console.error("Error", error);
        toast({
          title: "Error",
          description: "Failed to create a build",
        });
      });
  };

  return (
    <div className="flex items-center justify-center">
      <Button
        type="submit"
        disabled={!connected}
        onClick={onSignAndSubmitTransaction}
        className="w-40 self-start col-span-2"
      >
        Work on the fortune(prize)
      </Button>
    </div>
  );
}
