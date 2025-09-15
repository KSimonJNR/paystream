// Minimal client helpers to interact with Paystream
// Assumes you have a StarkNet provider/wallet (e.g., argent-x or starknet.js) wired up.

export type Address = string;

export interface Deployment {
  paystream: Address;
  mock_erc20?: Address;
}

export interface StreamParams {
  recipient: Address;
  deposit: bigint; // u256 as bigint for low-level libs
  start_time: number; // seconds
  stop_time: number;  // seconds
  token_address: Address;
}

export function loadDeployment(): Deployment {
  // In a real app, fetch this from contracts/deployment.json or env
  // Placeholder: replace with actual deployment.json fetch.
  const raw = (window as any).__DEPLOYMENT__;
  if (!raw) throw new Error('Deployment not injected');
  return raw as Deployment;
}

export function toU256(v: bigint) {
  const mask = (1n << 128n) - 1n;
  return { low: (v & mask).toString(), high: (v >> 128n).toString() };
}

// Example starknet.js style calls (pseudo-code):
// const provider = new RpcProvider({ nodeUrl: ... });
// const account = new Account(provider, accountAddress, privateKey);
// const paystream = new Contract(PaystreamAbi, deployment.paystream, account);

export async function createStream(account: any, contract: any, p: StreamParams) {
  return contract.invoke('create_stream', [
    p.recipient,
    toU256(p.deposit),
    p.start_time,
    p.stop_time,
    p.token_address,
  ]);
}

export async function balanceOf(provider: any, contract: any, id: string, user: Address) {
  return contract.call('balance_of', [id, user]);
}

export async function withdraw(account: any, contract: any, id: string, amount: bigint) {
  return contract.invoke('withdraw_from_stream', [id, toU256(amount)]);
}

export async function cancel(account: any, contract: any, id: string) {
  return contract.invoke('cancel_stream', [id]);
}
