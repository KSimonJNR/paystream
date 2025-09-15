#!/bin/bash
# Deploy Paystream and MockERC20 to StarkNet testnet
# Usage: ./deploy.sh <account-address> <account-private-key>

set -e

ACCOUNT_ADDRESS="$1"
PRIVATE_KEY="$2"

if [ -z "$ACCOUNT_ADDRESS" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Usage: $0 <account-address> <account-private-key>"
  exit 1
fi

# Build contracts
scarb build

# Find compiled Sierra artifacts
PAYSTREAM_SIERRA=target/dev/paystream_Paystream.sierra.json
MOCKERC20_SIERRA=target/dev/mock_erc20_MockERC20.sierra.json

# Deploy MockERC20
MOCKERC20_ADDR=$(starknet deploy --account $ACCOUNT_ADDRESS --class-hash $(starknet declare --account $ACCOUNT_ADDRESS --contract $MOCKERC20_SIERRA --max-fee auto | grep 'Class hash:' | awk '{print $3}') --max-fee auto | grep 'Contract address:' | awk '{print $3}')
echo "MockERC20 deployed at: $MOCKERC20_ADDR"

# Deploy Paystream
PAYSTREAM_ADDR=$(starknet deploy --account $ACCOUNT_ADDRESS --class-hash $(starknet declare --account $ACCOUNT_ADDRESS --contract $PAYSTREAM_SIERRA --max-fee auto | grep 'Class hash:' | awk '{print $3}') --max-fee auto | grep 'Contract address:' | awk '{print $3}')
echo "Paystream deployed at: $PAYSTREAM_ADDR"

# Export addresses for frontend
cat <<EOF > deployment.json
{
  "paystream": "$PAYSTREAM_ADDR",
  "mock_erc20": "$MOCKERC20_ADDR"
}
EOF

echo "Deployment complete. Addresses written to deployment.json."
