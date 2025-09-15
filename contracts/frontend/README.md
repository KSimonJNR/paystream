# Frontend wiring (quick)

After deploying contracts and exporting ABIs:
- Addresses: `../deployment.json`
- ABIs: `./abi/Paystream.json` and `./abi/MockERC20.json`

Use `src/paystreamClient.ts` helpers with starknet.js to call:
- `create_stream(recipient, deposit, start, stop, token)`
- `balance_of(stream_id, user)`
- `withdraw_from_stream(stream_id, amount)`
- `cancel_stream(stream_id)`

Tip: ensure the sender has approved the Paystream contract on the ERC-20 before `create_stream`.

## CLI demo (Node.js, starknet.js)

Set env vars for your account:
```bash
export ACCOUNT_ADDRESS=<your-account-address>
export PRIVATE_KEY=<your-private-key>
```

Run commands:
```bash
# Mint tokens to user
node src/cli.js mint <to> <amount>
# Approve Paystream contract
node src/cli.js approve <paystream-address> <amount>
# Create a stream
node src/cli.js create <recipient> <amount> <start_time> <stop_time> <token_address>
# Withdraw from stream
node src/cli.js withdraw <stream_id> <amount>
# Check balance
node src/cli.js balance <stream_id> <user>
```
