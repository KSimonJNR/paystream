// Minimal Paystream frontend for Argent X
// Assumes deployment.json and ABIs are in the same folder or adjust paths as needed

let provider, account, paystream, paystreamAbi, deployment;

function notify(msg, color = '#333') {
  const n = document.getElementById('notification');
  n.innerText = msg;
  n.style.background = color;
  n.style.display = 'block';
  setTimeout(() => { n.style.display = 'none'; }, 4000);
}

async function loadDeployment() {
  const res = await fetch('deployment.json');
  return await res.json();
}
async function loadAbi(name) {
  const res = await fetch(`abi/${name}.json`);
  return await res.json();
}

function toU256(val) {
  const bn = BigInt(val);
  const mask = (1n << 128n) - 1n;
  return { low: (bn & mask).toString(), high: (bn >> 128n).toString() };
}

window.addEventListener('DOMContentLoaded', async () => {
  document.getElementById('connect').onclick = async () => {
    if (!window.starknet) {
      notify('Argent X not found!', 'crimson');
      return;
    }
    await window.starknet.enable();
    provider = window.starknet;
    account = window.starknet.account;
    document.getElementById('account').innerText = 'Connected: ' + window.starknet.selectedAddress;
    deployment = await loadDeployment();
    paystreamAbi = await loadAbi('Paystream');
    if (!window.starknetjs || !window.starknetjs.Contract) {
      notify('starknet.js not loaded. Check script include.', 'crimson');
      return;
    }
    paystream = new window.starknetjs.Contract(paystreamAbi.abi, deployment.paystream, provider);
    notify('Wallet connected!', 'green');
  };

  document.getElementById('create').onclick = async () => {
    document.getElementById('createLoading').style.display = 'inline';
    document.getElementById('createResult').innerText = '';
    try {
      const recipient = document.getElementById('recipient').value;
      const deposit = document.getElementById('deposit').value;
      const start = document.getElementById('start').value;
      const stop = document.getElementById('stop').value;
      const token = document.getElementById('token').value;
      if (!recipient || !deposit || !start || !stop || !token) {
        notify('Fill all fields for create stream', 'crimson');
        return;
      }
      const calldata = [recipient, toU256(deposit), start, stop, token];
      const tx = await paystream.invoke('create_stream', calldata);
      document.getElementById('createResult').innerText = 'Tx: ' + tx.transaction_hash;
      notify('Stream created! Tx: ' + tx.transaction_hash, 'green');
    } catch (e) {
      document.getElementById('createResult').innerText = 'Error: ' + (e.message || e);
      notify('Error: ' + (e.message || e), 'crimson');
    } finally {
      document.getElementById('createLoading').style.display = 'none';
    }
  };

  document.getElementById('withdraw').onclick = async () => {
    document.getElementById('withdrawLoading').style.display = 'inline';
    document.getElementById('withdrawResult').innerText = '';
    try {
      const streamId = document.getElementById('streamIdW').value;
      const amount = document.getElementById('amountW').value;
      if (!streamId || !amount) {
        notify('Fill all fields for withdraw', 'crimson');
        return;
      }
      const calldata = [streamId, toU256(amount)];
      const tx = await paystream.invoke('withdraw_from_stream', calldata);
      document.getElementById('withdrawResult').innerText = 'Tx: ' + tx.transaction_hash;
      notify('Withdraw successful! Tx: ' + tx.transaction_hash, 'green');
    } catch (e) {
      document.getElementById('withdrawResult').innerText = 'Error: ' + (e.message || e);
      notify('Error: ' + (e.message || e), 'crimson');
    } finally {
      document.getElementById('withdrawLoading').style.display = 'none';
    }
  };

  document.getElementById('balance').onclick = async () => {
    document.getElementById('balanceLoading').style.display = 'inline';
    document.getElementById('balanceResult').innerText = '';
    try {
      const streamId = document.getElementById('streamIdB').value;
      const user = document.getElementById('userB').value;
      if (!streamId || !user) {
        notify('Fill all fields for balance check', 'crimson');
        return;
      }
      const res = await paystream.call('balance_of', [streamId, user]);
      document.getElementById('balanceResult').innerText = JSON.stringify(res);
      notify('Balance checked!', 'green');
    } catch (e) {
      document.getElementById('balanceResult').innerText = 'Error: ' + (e.message || e);
      notify('Error: ' + (e.message || e), 'crimson');
    } finally {
      document.getElementById('balanceLoading').style.display = 'none';
    }
  };
});
