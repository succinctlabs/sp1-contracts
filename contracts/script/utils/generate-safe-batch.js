#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const CHAINS = { 1: 'Ethereum', 10: 'Optimism', 42161: 'Arbitrum', 8453: 'Base', 534352: 'Scroll' };
const ADD_ROUTE_SELECTOR = '0x8c95ff1e'; // keccak256("addRoute(address)")[:4]

function versionToKey(v) { return v.toUpperCase().replace(/[.-]/g, '_'); }

function createTransaction(gateway, verifier) {
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

function generateBatch(chainId, version) {
  const file = path.join(__dirname, '../../deployments', `${chainId}.json`);
  if (!fs.existsSync(file)) { console.error(`  No deployment file`); return null; }

  let d;
  try { d = JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch (e) { console.error(`  Bad JSON: ${e.message}`); return null; }

  const g16 = d['SP1_VERIFIER_GATEWAY_GROTH16'], plonk = d['SP1_VERIFIER_GATEWAY_PLONK'];
  if (!g16 || !plonk) { console.error(`  Missing gateway addresses`); return null; }

  const k = versionToKey(version);
  const txs = [];

  if (d[`${k}_SP1_VERIFIER_GROTH16`]) {
    txs.push(createTransaction(g16, d[`${k}_SP1_VERIFIER_GROTH16`]));
    console.log(`  Groth16: ${d[`${k}_SP1_VERIFIER_GROTH16`]} -> ${g16}`);
  }
  if (d[`${k}_SP1_VERIFIER_PLONK`]) {
    txs.push(createTransaction(plonk, d[`${k}_SP1_VERIFIER_PLONK`]));
    console.log(`  Plonk: ${d[`${k}_SP1_VERIFIER_PLONK`]} -> ${plonk}`);
  }

  if (!txs.length) {
    console.error(`  No verifiers for ${version} (need ${k}_SP1_VERIFIER_GROTH16/PLONK)`);
    return null;
  }

  return {
    version: '1.0',
    chainId: String(chainId),
    createdAt: Date.now(),
    meta: { name: `Add SP1 ${version} Routes`, description: `Add ${version} verifiers on ${CHAINS[chainId] || chainId}` },
    transactions: txs
  };
}

function printUsage() {
  console.log(`
Usage: node generate-safe-batch.js [--chain=<id|all>] [--version=<v>]

Chains: ${Object.entries(CHAINS).map(([id, name]) => `${id}=${name}`).join(', ')}
Defaults: --chain=all --version=v6.0.0-beta.1
`);
}

// Parse args
const args = { chain: 'all', version: 'v6.0.0-beta.1' };
for (const a of process.argv.slice(2)) {
  if (a === '-h' || a === '--help') { printUsage(); process.exit(0); }
  if (a.startsWith('--chain=')) args.chain = a.slice(8);
  if (a.startsWith('--version=')) args.version = a.slice(10);
}

// Validate chain
const chains = args.chain === 'all'
  ? Object.keys(CHAINS).map(Number)
  : [parseInt(args.chain) || (console.error(`Bad chain: ${args.chain}`), process.exit(1))];

console.log(`\nGenerating batches for ${args.version} on ${args.chain === 'all' ? 'all chains' : args.chain}\n`);

const outDir = path.join(__dirname, '../../safe-batches');
fs.mkdirSync(outDir, { recursive: true });

let ok = 0;
for (const id of chains) {
  console.log(`${CHAINS[id] || id} (${id})...`);
  const batch = generateBatch(id, args.version);
  if (batch) {
    const out = path.join(outDir, `${id}_${versionToKey(args.version).toLowerCase()}.json`);
    fs.writeFileSync(out, JSON.stringify(batch, null, 2));
    console.log(`  -> ${out}\n`);
    ok++;
  } else console.log('');
}

console.log(`Done: ${ok}/${chains.length} generated`);
if (ok) console.log(`Upload to Safe UI -> Transaction Builder`);
