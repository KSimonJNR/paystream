// Minimal-but-polished Paystream frontend for Argent X
// Uses starknet.js from CDN and deployment/ABIs shipped in this folder

let provider, account, paystream, paystreamAbi, erc20Abi, deployment;

function notify(msg, type = 'info') {
  const n = document.getElementById('notification');
  n.innerText = msg;
  n.classList.remove('note-success', 'note-error', 'note-info');
  if (type === 'success') n.classList.add('note-success');
  else if (type === 'error') n.classList.add('note-error');
  else n.classList.add('note-info');
  n.style.display = 'block';
  setTimeout(() => { n.style.display = 'none'; }, 4200);
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

function parseAmount(input, decimals = 18) {
  const trimmed = (input || '').trim();
  if (!trimmed) throw new Error('Amount required');
  if (!/^\d*(\.\d+)?$/.test(trimmed)) throw new Error('Amount must be a number');
  const [ints, fraction = ''] = trimmed.split('.');
  if (fraction.length > decimals) throw new Error(`Max ${decimals} decimal places`);
  const paddedFraction = (fraction + '0'.repeat(decimals)).slice(0, decimals);
  return BigInt(ints || '0') * 10n ** BigInt(decimals) + BigInt(paddedFraction);
}

function short(addr) {
  if (!addr) return '—';
  return addr.length > 12 ? `${addr.slice(0, 6)}...${addr.slice(-4)}` : addr;
}

function setLoading(buttonId, spinnerId, isLoading) {
  const btn = document.getElementById(buttonId);
  const sp = document.getElementById(spinnerId);
  if (btn) btn.disabled = isLoading;
  if (sp) sp.style.display = isLoading ? 'inline' : 'none';
}

function setDefaultTimes() {
  const now = Math.floor(Date.now() / 1000);
  const start = now + 60;
  const stop = start + 3600;
  document.getElementById('start').value = start;
  document.getElementById('stop').value = stop;
}

function txLink(hash) {
  const chainId = window.starknet?.chainId;
  const base = chainId === '0x534e5f4d41494e' ? 'https://voyager.online/tx/' : 'https://sepolia.voyager.online/tx/';
  return `${base}${hash}`;
}

window.addEventListener('DOMContentLoaded', async () => {
  const accountBadge = document.getElementById('account');
  const contractBadge = document.getElementById('contract');
  const networkBadge = document.getElementById('network');
  setDefaultTimes();

  try {
    deployment = await loadDeployment();
    contractBadge.innerText = `Contract: ${short(deployment.paystream)}`;
    if (deployment.mock_erc20) {
      document.getElementById('fillMock').title = deployment.mock_erc20;
      const approveFill = document.getElementById('approveFillMock');
      if (approveFill) approveFill.title = deployment.mock_erc20;
    }
    erc20Abi = await loadAbi('MockERC20');
  } catch (e) {
    notify('Could not load deployment.json', 'error');
  }

  document.getElementById('connect').onclick = async () => {
    if (!window.starknet) {
      notify('Argent X not found!', 'error');
      return;
    }
    await window.starknet.enable();
    provider = window.starknet;
    account = window.starknet.account;
    accountBadge.innerText = `Connected: ${short(window.starknet.selectedAddress)}`;
    networkBadge.innerText = `Network: ${window.starknet.chainId || 'auto'}`;
    contractBadge.innerText = `Contract: ${short(deployment?.paystream)}`;
    if (!deployment?.paystream) {
      notify('Deployment missing paystream address', 'error');
      return;
    }
    paystreamAbi = await loadAbi('Paystream');
    if (!window.starknetjs || !window.starknetjs.Contract) {
      notify('starknet.js not loaded. Check script include.', 'error');
      return;
    }
    paystream = new window.starknetjs.Contract(paystreamAbi.abi, deployment.paystream, provider);
    notify('Wallet connected', 'success');
  };

  document.getElementById('fillMock').onclick = () => {
    if (deployment?.mock_erc20) {
      document.getElementById('token').value = deployment.mock_erc20;
      notify('Mock token address filled', 'info');
    } else {
      notify('mock_erc20 missing in deployment.json', 'error');
    }
  };

  const approveFillMock = document.getElementById('approveFillMock');
  if (approveFillMock) {
    approveFillMock.onclick = () => {
      if (deployment?.mock_erc20) {
        document.getElementById('approveToken').value = deployment.mock_erc20;
        notify('Mock token address filled', 'info');
      } else {
        notify('mock_erc20 missing in deployment.json', 'error');
      }
    };
  }

  document.getElementById('create').onclick = async () => {
    setLoading('create', 'createLoading', true);
    document.getElementById('createResult').innerText = '';
    try {
      if (!paystream || !account) {
        notify('Connect wallet first', 'error');
        return;
      }
      const recipient = document.getElementById('recipient').value;
      const deposit = parseAmount(document.getElementById('deposit').value);
      const start = document.getElementById('start').value;
      const stop = document.getElementById('stop').value;
      const token = document.getElementById('token').value;
      if (!recipient || !deposit || !start || !stop || !token) {
        notify('Fill all fields for create stream', 'error');
        return;
      }
      const calldata = [recipient, toU256(deposit), start, stop, token];
      const tx = await paystream.invoke('create_stream', calldata);
      document.getElementById('createResult').innerHTML = `Tx: <a href="${txLink(tx.transaction_hash)}" target="_blank" rel="noreferrer">${tx.transaction_hash}</a>`;
      notify('Stream created', 'success');
    } catch (e) {
      document.getElementById('createResult').innerText = 'Error: ' + (e.message || e);
      notify('Error: ' + (e.message || e), 'error');
    } finally {
      setLoading('create', 'createLoading', false);
    }
  };

  document.getElementById('withdraw').onclick = async () => {
    setLoading('withdraw', 'withdrawLoading', true);
    document.getElementById('withdrawResult').innerText = '';
    try {
      if (!paystream || !account) {
        notify('Connect wallet first', 'error');
        return;
      }
      const streamId = document.getElementById('streamIdW').value;
      const amount = parseAmount(document.getElementById('amountW').value);
      if (!streamId || !amount) {
        notify('Fill all fields for withdraw', 'error');
        return;
      }
      const calldata = [streamId, toU256(amount)];
      const tx = await paystream.invoke('withdraw_from_stream', calldata);
      document.getElementById('withdrawResult').innerHTML = `Tx: <a href="${txLink(tx.transaction_hash)}" target="_blank" rel="noreferrer">${tx.transaction_hash}</a>`;
      notify('Withdraw successful', 'success');
    } catch (e) {
      document.getElementById('withdrawResult').innerText = 'Error: ' + (e.message || e);
      notify('Error: ' + (e.message || e), 'error');
    } finally {
      setLoading('withdraw', 'withdrawLoading', false);
    }
  };

  const approveBtn = document.getElementById('approve');
  if (approveBtn) {
    approveBtn.onclick = async () => {
      setLoading('approve', 'approveLoading', true);
      document.getElementById('approveResult').innerText = '';
      try {
        if (!paystream || !account) {
          notify('Connect wallet first', 'error');
          return;
        }
        if (!erc20Abi) erc20Abi = await loadAbi('MockERC20');
        const tokenAddr = document.getElementById('approveToken').value || document.getElementById('token').value;
        if (!tokenAddr) {
          notify('Provide token address', 'error');
          return;
        }
        if (!deployment?.paystream) {
          notify('Deployment missing paystream address', 'error');
          return;
        }
        const amount = parseAmount(document.getElementById('approveAmount').value);
        const erc20 = new window.starknetjs.Contract(erc20Abi.abi, tokenAddr, provider);
        const tx = await erc20.invoke('approve', [deployment.paystream, toU256(amount)]);
        document.getElementById('approveResult').innerHTML = `Tx: <a href="${txLink(tx.transaction_hash)}" target="_blank" rel="noreferrer">${tx.transaction_hash}</a>`;
        notify('Approve submitted', 'success');
      } catch (e) {
        document.getElementById('approveResult').innerText = 'Error: ' + (e.message || e);
        notify('Error: ' + (e.message || e), 'error');
      } finally {
        setLoading('approve', 'approveLoading', false);
      }
    };
  }

  const cancelBtn = document.getElementById('cancel');
  if (cancelBtn) {
    cancelBtn.onclick = async () => {
      setLoading('cancel', 'cancelLoading', true);
      document.getElementById('cancelResult').innerText = '';
      try {
        if (!paystream || !account) {
          notify('Connect wallet first', 'error');
          return;
        }
        const streamId = document.getElementById('streamIdC').value;
        if (!streamId) {
          notify('Provide stream ID', 'error');
          return;
        }
        const tx = await paystream.invoke('cancel_stream', [streamId]);
        document.getElementById('cancelResult').innerHTML = `Tx: <a href="${txLink(tx.transaction_hash)}" target="_blank" rel="noreferrer">${tx.transaction_hash}</a>`;
        notify('Cancel submitted', 'success');
      } catch (e) {
        document.getElementById('cancelResult').innerText = 'Error: ' + (e.message || e);
        notify('Error: ' + (e.message || e), 'error');
      } finally {
        setLoading('cancel', 'cancelLoading', false);
      }
    };
  }

  document.getElementById('balance').onclick = async () => {
    setLoading('balance', 'balanceLoading', true);
    document.getElementById('balanceResult').innerText = '';
    try {
      if (!paystream) {
        notify('Connect wallet first', 'error');
        return;
      }
      const streamId = document.getElementById('streamIdB').value;
      const user = document.getElementById('userB').value;
      if (!streamId || !user) {
        notify('Fill all fields for balance check', 'error');
        return;
      }
      const res = await paystream.call('balance_of', [streamId, user]);
      document.getElementById('balanceResult').innerText = JSON.stringify(res);
      notify('Balance checked', 'success');
    } catch (e) {
      document.getElementById('balanceResult').innerText = 'Error: ' + (e.message || e);
      notify('Error: ' + (e.message || e), 'error');
    } finally {
      setLoading('balance', 'balanceLoading', false);
    }
  };
});
