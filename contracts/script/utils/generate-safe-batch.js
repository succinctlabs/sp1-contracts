#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const DEPLOY_DIR = path.join(__dirname, '../../deployments');
const MAINNET_CHAINS = [1, 10, 42161, 8453, 534352];
const TESTNET_CHAINS = [11155111, 421614, 84532, 11155420, 534351];
const MULTISIG_CHAINS = [...MAINNET_CHAINS, ...TESTNET_CHAINS];
const CHAIN_NAMES = {
  1: 'Ethereum', 10: 'Optimism', 42161: 'Arbitrum', 8453: 'Base', 534352: 'Scroll',
  11155111: 'Sepolia', 421614: 'Arbitrum Sepolia',
  84532: 'Base Sepolia', 11155420: 'Optimism Sepolia', 534351: 'Scroll Sepolia'
};
const ADD_ROUTE_SELECTOR = '0x8c95ff1e'; // keccak256("addRoute(address)")[:4]
const FREEZE_ROUTE_SELECTOR = '0x191ffb1e'; // keccak256("freezeRoute(bytes4)")[:4]

// VERIFIER_HASH first 4 bytes per version (for freeze)
const VERIFIER_SELECTORS = {
  'V5_0_0': { groth16: '0xa4594c59', plonk: '0xd4e8ecd2' },
  'V6_0_0': { groth16: '0x0e78f4db', plonk: '0xbb1a6f29' },
};

function versionToKey(v) { return v.toUpperCase().replace(/[.-]/g, '_'); }

function createAddRouteTransaction(gateway, verifier) {
  return {
    to: gateway,
    value: '0',
    data: ADD_ROUTE_SELECTOR + verifier.slice(2).toLowerCase().padStart(64, '0'),
    operation: 0,
    contractMethod: {
      inputs: [{ internalType: 'address', name: 'verifier', type: 'address' }],
      name: 'addRoute',
      payable: false
    },
    contractInputsValues: { verifier }
  };
}

function createFreezeRouteTransaction(gateway, selector) {
  return {
    to: gateway,
    value: '0',
    data: FREEZE_ROUTE_SELECTOR + selector.slice(2).padEnd(64, '0'),
    operation: 0,
    contractMethod: {
      inputs: [{ internalType: 'bytes4', name: 'selector', type: 'bytes4' }],
      name: 'freezeRoute',
      payable: false
    },
    contractInputsValues: { selector }
  };
}

function generateBatch(chainId, version, action) {
  const file = path.join(DEPLOY_DIR, `${chainId}.json`);
  if (!fs.existsSync(file)) { console.error(`  No deployment file`); return null; }

  let d;
  try { d = JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch (e) { console.error(`  Bad JSON: ${e.message}`); return null; }

  const g16 = d['SP1_VERIFIER_GATEWAY_GROTH16'], plonk = d['SP1_VERIFIER_GATEWAY_PLONK'];
  if (!g16 || !plonk) { console.error(`  Missing gateway addresses`); return null; }

  const k = versionToKey(version);
  const txs = [];

  if (action === 'freeze') {
    const selectors = VERIFIER_SELECTORS[k];
    if (!selectors) { console.error(`  No known selectors for ${version}`); return null; }

    txs.push(createFreezeRouteTransaction(g16, selectors.groth16));
    console.log(`  Freeze Groth16: selector ${selectors.groth16} on ${g16}`);
    txs.push(createFreezeRouteTransaction(plonk, selectors.plonk));
    console.log(`  Freeze Plonk: selector ${selectors.plonk} on ${plonk}`);
  } else {
    if (d[`${k}_SP1_VERIFIER_GROTH16`]) {
      txs.push(createAddRouteTransaction(g16, d[`${k}_SP1_VERIFIER_GROTH16`]));
      console.log(`  Groth16: ${d[`${k}_SP1_VERIFIER_GROTH16`]} -> ${g16}`);
    }
    if (d[`${k}_SP1_VERIFIER_PLONK`]) {
      txs.push(createAddRouteTransaction(plonk, d[`${k}_SP1_VERIFIER_PLONK`]));
      console.log(`  Plonk: ${d[`${k}_SP1_VERIFIER_PLONK`]} -> ${plonk}`);
    }
  }

  if (!txs.length) {
    console.error(`  No transactions generated for ${version}`);
    return null;
  }

  const actionLabel = action === 'freeze' ? 'Freeze' : 'Add';
  return {
    version: '1.0',
    chainId: String(chainId),
    createdAt: Date.now(),
    meta: {
      name: `${actionLabel} SP1 ${version} Routes`,
      description: `${actionLabel} ${version} verifiers on ${CHAIN_NAMES[chainId] || chainId}`
    },
    transactions: txs
  };
}

function printUsage() {
  const available = fs.readdirSync(DEPLOY_DIR).filter(f => f.endsWith('.json')).map(f => f.slice(0, -5));
  console.log(`
Usage: node generate-safe-batch.js [--chain=<id|all|mainnet|testnet>] [--version=<v>] [--action=<add|freeze>]

Chain groups:
  --chain=all       All multisig chains (mainnet + testnet)
  --chain=mainnet   Mainnet chains: ${MAINNET_CHAINS.join(', ')}
  --chain=testnet   Testnet chains: ${TESTNET_CHAINS.join(', ')}
  --chain=<id>      Single chain by ID

Available chains: ${available.join(', ')}
Defaults: --chain=all --version=v6.0.0 --action=add
`);
}

// Parse args
const args = { chain: 'all', version: 'v6.0.0', action: 'add' };
for (const a of process.argv.slice(2)) {
  if (a === '-h' || a === '--help') { printUsage(); process.exit(0); }
  if (a.startsWith('--chain=')) args.chain = a.slice(8);
  if (a.startsWith('--version=')) args.version = a.slice(10);
  if (a.startsWith('--action=')) args.action = a.slice(9);
}

if (!['add', 'freeze'].includes(args.action)) {
  console.error(`Bad action: ${args.action} (use 'add' or 'freeze')`);
  process.exit(1);
}

// Resolve chains
let chains;
if (args.chain === 'all') chains = MULTISIG_CHAINS;
else if (args.chain === 'mainnet') chains = MAINNET_CHAINS;
else if (args.chain === 'testnet') chains = TESTNET_CHAINS;
else chains = [parseInt(args.chain) || (console.error(`Bad chain: ${args.chain}`), process.exit(1))];

const actionLabel = args.action === 'freeze' ? 'freeze' : 'add-route';
console.log(`\nGenerating ${actionLabel} batches for ${args.version} on ${args.chain}\n`);

const outDir = path.join(__dirname, '../../safe-batches');
fs.mkdirSync(outDir, { recursive: true });

let ok = 0;
for (const id of chains) {
  console.log(`${CHAIN_NAMES[id] || id} (${id})...`);
  const batch = generateBatch(id, args.version, args.action);
  if (batch) {
    const out = path.join(outDir, `${id}_${actionLabel}_${versionToKey(args.version).toLowerCase()}.json`);
    fs.writeFileSync(out, JSON.stringify(batch, null, 2));
    console.log(`  -> ${out}\n`);
    ok++;
  } else console.log('');
}

console.log(`Done: ${ok}/${chains.length} generated`);
if (ok) console.log(`Upload to Safe UI -> Transaction Builder`);
