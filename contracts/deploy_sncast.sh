#!/bin/bash
# Deploy Paystream and MockERC20 using sncast (Starknet Foundry)
# Usage: ./deploy_sncast.sh <account-name> <accounts-file> <keystore> <rpc-url>
# Example: ./deploy_sncast.sh myaccount accounts.json keystore.json https://rpc.sepolia.starknet.org
set -e

ACCOUNT_NAME="$1"
ACCOUNTS_FILE="$2"
KEYSTORE="$3"
RPC_URL="$4"

if [ -z "$ACCOUNT_NAME" ] || [ -z "$ACCOUNTS_FILE" ] || [ -z "$KEYSTORE" ] || [ -z "$RPC_URL" ]; then
  echo "Usage: $0 <account-name> <accounts-file> <keystore> <rpc-url>"
  exit 1
fi

cd "$(dirname "$0")"
scarb build

# Declare contracts
MOCK_DECLARE=$(sncast --url "$RPC_URL" --accounts-file "$ACCOUNTS_FILE" --keystore "$KEYSTORE" --account "$ACCOUNT_NAME" declare --contract target/dev/mock_erc20_MockERC20.sierra.json)
MOCK_CLASS_HASH=$(echo "$MOCK_DECLARE" | grep 'Class hash:' | awk '{print $3}')

PAYSTREAM_DECLARE=$(sncast --url "$RPC_URL" --accounts-file "$ACCOUNTS_FILE" --keystore "$KEYSTORE" --account "$ACCOUNT_NAME" declare --contract target/dev/paystream_Paystream.sierra.json)
PAYSTREAM_CLASS_HASH=$(echo "$PAYSTREAM_DECLARE" | grep 'Class hash:' | awk '{print $3}')

# Deploy contracts
MOCK_DEPLOY=$(sncast --url "$RPC_URL" --accounts-file "$ACCOUNTS_FILE" --keystore "$KEYSTORE" --account "$ACCOUNT_NAME" deploy --class-hash "$MOCK_CLASS_HASH" --unique)
MOCK_ADDR=$(echo "$MOCK_DEPLOY" | grep 'Contract address:' | awk '{print $3}')

PAYSTREAM_DEPLOY=$(sncast --url "$RPC_URL" --accounts-file "$ACCOUNTS_FILE" --keystore "$KEYSTORE" --account "$ACCOUNT_NAME" deploy --class-hash "$PAYSTREAM_CLASS_HASH" --unique)
PAYSTREAM_ADDR=$(echo "$PAYSTREAM_DEPLOY" | grep 'Contract address:' | awk '{print $3}')

cat <<EOF > deployment.json
{
  "paystream": "$PAYSTREAM_ADDR",
  "mock_erc20": "$MOCK_ADDR"
}
EOF

echo "Deployment complete. Addresses written to deployment.json."
