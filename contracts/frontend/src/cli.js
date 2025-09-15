// Minimal CLI for Paystream demo using starknet.js
// Usage: node src/cli.js <cmd> [...args]
// Example: node src/cli.js mint <to> <amount>

const fs = require('fs');
const { Provider, Account, Contract, json } = require('starknet');
const deployment = require('../deployment.json');
const paystreamAbi = require('../abi/Paystream.json');
const erc20Abi = require('../abi/MockERC20.json');

const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });

// Set these for your demo account
const ACCOUNT_ADDRESS = process.env.ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const account = new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY);

const paystream = new Contract(paystreamAbi, deployment.paystream, account);
const erc20 = new Contract(erc20Abi, deployment.mock_erc20, account);

function toU256(v) {
  const bn = BigInt(v);
  const mask = (1n << 128n) - 1n;
  return { low: (bn & mask).toString(), high: (bn >> 128n).toString() };
}

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  if (cmd === 'mint') {
    const [to, amount] = args;
    const res = await erc20.invoke('mint', { to, amount: toU256(amount) });
    console.log('Mint tx:', res.transaction_hash);
  } else if (cmd === 'approve') {
    const [spender, amount] = args;
    const res = await erc20.invoke('approve', { spender, amount: toU256(amount) });
    console.log('Approve tx:', res.transaction_hash);
  } else if (cmd === 'create') {
    const [recipient, amount, start, stop, token] = args;
    const res = await paystream.invoke('create_stream', {
      recipient,
      deposit: toU256(amount),
      start_time: Number(start),
      stop_time: Number(stop),
      token_address: token,
    });
    console.log('Create stream tx:', res.transaction_hash);
  } else if (cmd === 'withdraw') {
    const [stream_id, amount] = args;
    const res = await paystream.invoke('withdraw_from_stream', {
      stream_id,
      amount: toU256(amount),
    });
    console.log('Withdraw tx:', res.transaction_hash);
  } else if (cmd === 'balance') {
    const [stream_id, user] = args;
    const res = await paystream.call('balance_of', { stream_id, user });
    console.log('Balance:', res);
  } else {
    console.log('Usage: node src/cli.js <mint|approve|create|withdraw|balance> ...args');
  }
}

main().catch(console.error);
