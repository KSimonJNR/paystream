
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

## 4. Frontend ABI export
After build, ABIs are in `target/dev/*.sierra.json`.
Use `paystream_Paystream.sierra.json` and `mock_erc20_MockERC20.sierra.json` for your frontend.

## 5. CI/CD
All builds and tests run automatically on GitHub Actions (see `.github/workflows/ci.yml`).

---
For hackathon help, ping in Discord or open an issue!
