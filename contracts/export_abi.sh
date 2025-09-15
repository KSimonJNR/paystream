#!/bin/bash
set -e

# Ensure build artifacts exist
scarb build

# Create frontend abi directory
FRONTEND_ABI_DIR="./frontend/abi"
mkdir -p "$FRONTEND_ABI_DIR"

# Copy Sierra artifacts as ABIs
cp target/dev/paystream_Paystream.sierra.json "$FRONTEND_ABI_DIR"/Paystream.json
cp target/dev/mock_erc20_MockERC20.sierra.json "$FRONTEND_ABI_DIR"/MockERC20.json

echo "ABIs exported to $FRONTEND_ABI_DIR"
