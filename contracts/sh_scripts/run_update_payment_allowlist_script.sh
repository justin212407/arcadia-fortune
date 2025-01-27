#!/bin/sh

set -e

echo "##### Running move script to do multiple contract calls in 1 tx #####"

CONTRACT_ADDRESS=$(cat contract_address.txt)

# Need to compile the package first
aptos move compile \
  --skip-fetch-latest-git-deps --named-addresses arcadia_fortune_addr=$CONTRACT_ADDRESS

# Profile is the account you used to execute transaction
# Run "aptos init" to create the profile, then get the profile name from .aptos/config.yaml
SENDER_PROFILE=testnet-profile-1

# Run the script
aptos move run-script \
	--assume-yes --skip-fetch-latest-git-deps \
  --profile $SENDER_PROFILE \
  --compiled-script-path build/fortune(prize)App/bytecode_scripts/update_payment_allowlist.mv
