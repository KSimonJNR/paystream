// Minimal client helpers to interact with Paystream
// Assumes you have a StarkNet provider/wallet (e.g., starknet.js) wired up.

export type Address = string;

export interface Deployment {
  paystream: Address;
  mock_erc20?: Address;
}

export interface StreamParams {
  recipient: Address;
  deposit: bigint; // u256 as bigint
  start_time: number; // seconds
  stop_time: number;  // seconds
  token_address: Address;
}

export function toU256(v: bigint) {
  const mask = (1n << 128n) - 1n;
  return { low: (v & mask).toString(), high: (v >> 128n).toString() };
}

// Example starknet.js style calls (pseudo-code):
// const provider = new RpcProvider({ nodeUrl });
// const account = new Account(provider, accountAddress, privateKey);
// const paystream = new Contract(PaystreamAbi, deployment.paystream, account);

export async function createStream(contract: any, p: StreamParams) {
  return contract.invoke('create_stream', [
    p.recipient,
    toU256(p.deposit),
    p.start_time,
    p.stop_time,
    p.token_address,
  ]);
}

export async function balanceOf(contract: any, id: string, user: Address) {
  return contract.call('balance_of', [id, user]);
}

export async function withdraw(contract: any, id: string, amount: bigint) {
  return contract.invoke('withdraw_from_stream', [id, toU256(amount)]);
}

export async function cancel(contract: any, id: string) {
  return contract.invoke('cancel_stream', [id]);
}
