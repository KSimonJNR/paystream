
# Paystream (Cairo 1 / StarkNet) — Hackathon Quickstart

Streaming payments contract for ERC-20 tokens on StarkNet, with full test and deploy flow.

## Layout
- `Scarb.toml`: package config (Scarb)
- `src/lib.cairo`: exposes modules
- `src/paystream.cairo`: Paystream contract
- `src/mock_erc20.cairo`: Mock ERC-20 for tests
- `tests/integration.cairo`: End-to-end test
- `deploy.sh`: Deploy both contracts to StarkNet testnet

## 1. Build
```bash
scarb build
```

## 2. Test
```bash
scarb test
```

## 3. Deploy to StarkNet testnet
You need a funded StarkNet account and the `starknet` CLI:

```bash
# Usage: ./deploy.sh <account-address> <account-private-key>
chmod +x deploy.sh
./deploy.sh <account-address> <private-key>
```
This will deploy both contracts and write their addresses to `deployment.json`.

## 3. Deploy to StarkNet Sepolia (sncast, recommended)
You need a funded StarkNet account created with sncast (Starknet Foundry):

```bash
# 1. Install sncast (if not already)
curl -L https://foundry-rs.github.io/starknet-foundry/install | bash
export PATH="$HOME/.starknet-foundry/bin:$PATH"

# 2. Create a keystore and account
sncast keystore new keystore.json
sncast --url https://rpc.sepolia.starknet.org --accounts-file accounts.json --keystore keystore.json account create --name myaccount
# Fund the printed address using a Sepolia faucet, then:
sncast --url https://rpc.sepolia.starknet.org --accounts-file accounts.json --keystore keystore.json account deploy --name myaccount

# 3. Deploy contracts (from contracts/ directory)
chmod +x deploy_sncast.sh
./deploy_sncast.sh myaccount accounts.json keystore.json https://rpc.sepolia.starknet.org
```
This will deploy both contracts and write their addresses to `deployment.json`.

## 4. Frontend ABI export
After build, ABIs are in `target/dev/*.sierra.json`.
Use `paystream_Paystream.sierra.json` and `mock_erc20_MockERC20.sierra.json` for your frontend.

## 5. CI/CD
All builds and tests run automatically on GitHub Actions (see `.github/workflows/ci.yml`).

---
For hackathon help, ping in Discord or open an issue!
