#!/usr/bin/env node
/**
 * Generates Safe Transaction Builder JSON for adding verifier routes
 *
 * Usage:
 *   node generate-safe-batch.js --chain=1 --version=v6.0.0-beta.1
 *   node generate-safe-batch.js --chain=all --version=v6.0.0-beta.1
 */

const fs = require('fs');
const path = require('path');

// Supported mainnet chains for Phase 2 multisig deployment
const CHAINS = {
  1: 'Ethereum Mainnet',
  10: 'Optimism',
  42161: 'Arbitrum One',
  8453: 'Base',
  534352: 'Scroll'
};

// addRoute(address) function selector = keccak256("addRoute(address)")[:4]
const ADD_ROUTE_SELECTOR = '0x8c95ff1e';

// Encodes addRoute(address) calldata: selector + padded address
function encodeAddRoute(verifierAddress) {
  return ADD_ROUTE_SELECTOR + verifierAddress.slice(2).toLowerCase().padStart(64, '0');
}

// Converts version string to key format: v6.0.0-beta.1 -> V6_0_0_BETA_1
function versionToKey(version) {
  return version.toUpperCase().replace(/[.-]/g, '_');
}

// Creates a Safe Transaction Builder transaction object
function createTransaction(gatewayAddress, verifierAddress) {
  return {
    to: gatewayAddress,
    value: '0',
    data: encodeAddRoute(verifierAddress),
    operation: 0,
    contractMethod: {
      inputs: [{ internalType: 'address', name: 'verifier', type: 'address' }],
      name: 'addRoute',
      payable: false
    },
    contractInputsValues: { verifier: verifierAddress }
  };
}

// Generates a Safe Transaction Builder batch for a specific chain
function generateBatch(chainId, version) {
  const deploymentPath = path.join(__dirname, '../../deployments', `${chainId}.json`);

  if (!fs.existsSync(deploymentPath)) {
    console.error(`  No deployment file found`);
    return null;
  }

  let deployments;
  try {
    deployments = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'));
  } catch (e) {
    console.error(`  Failed to parse deployment file: ${e.message}`);
    return null;
  }

  const groth16Gateway = deployments['SP1_VERIFIER_GATEWAY_GROTH16'];
  const plonkGateway = deployments['SP1_VERIFIER_GATEWAY_PLONK'];

  if (!groth16Gateway || !plonkGateway) {
    console.error(`  Missing gateway addresses in deployment file`);
    return null;
  }

  const versionKey = versionToKey(version);
  const verifiers = [
    { type: 'Groth16', gateway: groth16Gateway, key: `${versionKey}_SP1_VERIFIER_GROTH16` },
    { type: 'Plonk', gateway: plonkGateway, key: `${versionKey}_SP1_VERIFIER_PLONK` }
  ];

  const transactions = [];
  for (const { type, gateway, key } of verifiers) {
    if (deployments[key]) {
      transactions.push(createTransaction(gateway, deployments[key]));
      console.log(`  ${type}: ${deployments[key]} -> ${gateway}`);
    }
  }

  if (transactions.length === 0) {
    console.error(`  No verifiers found for ${version}`);
    console.error(`  Expected keys: ${verifiers.map(v => v.key).join(', ')}`);
    return null;
  }

  return {
    version: '1.0',
    chainId: chainId.toString(),
    createdAt: Date.now(),
    meta: {
      name: `Add SP1 ${version} Verifier Routes`,
      description: `Batch transaction to add ${version} Groth16 and Plonk verifiers to their respective gateways on ${CHAINS[chainId] || `Chain ${chainId}`}`
    },
    transactions
  };
}

// Parses command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const result = { chain: 'all', version: 'v6.0.0-beta.1', help: false };

  for (const arg of args) {
    if (arg === '--help' || arg === '-h') result.help = true;
    else if (arg.startsWith('--chain=')) result.chain = arg.split('=')[1];
    else if (arg.startsWith('--version=')) result.version = arg.split('=')[1];
  }

  return result;
}

function printUsage() {
  const chainList = Object.entries(CHAINS).map(([id, name]) => `  ${id}: ${name}`).join('\n');
  console.log(`
Safe Transaction Builder JSON Generator

Usage: node generate-safe-batch.js [options]

Options:
  --chain=<id|all>     Chain ID or 'all' (default: all)
  --version=<version>  Version string (default: v6.0.0-beta.1)
  --help, -h           Show this help message

Supported Chains:
${chainList}

Examples:
  node generate-safe-batch.js --chain=1 --version=v6.0.0-beta.1
  node generate-safe-batch.js --chain=all --version=v5.0.0
`);
}

function main() {
  const args = parseArgs();

  if (args.help) {
    printUsage();
    process.exit(0);
  }

  // Validate chain argument
  let chainsToProcess;
  if (args.chain === 'all') {
    chainsToProcess = Object.keys(CHAINS).map(Number);
  } else {
    const chainId = parseInt(args.chain);
    if (isNaN(chainId)) {
      console.error(`Invalid chain ID: ${args.chain}`);
      process.exit(1);
    }
    chainsToProcess = [chainId];
  }

  console.log(`\nGenerating Safe Transaction Builder batches`);
  console.log(`  Version: ${args.version}`);
  console.log(`  Chains:  ${args.chain === 'all' ? 'all supported chains' : args.chain}\n`);

  const outputDir = path.join(__dirname, '../../safe-batches');
  fs.mkdirSync(outputDir, { recursive: true });

  const versionKey = versionToKey(args.version).toLowerCase();
  let successCount = 0;

  for (const chainId of chainsToProcess) {
    const chainName = CHAINS[chainId] || `Chain ${chainId}`;
    console.log(`Processing ${chainName} (${chainId})...`);

    const batch = generateBatch(chainId, args.version);

    if (batch) {
      const outputPath = path.join(outputDir, `${chainId}_${versionKey}.json`);
      fs.writeFileSync(outputPath, JSON.stringify(batch, null, 2));
      console.log(`  -> ${outputPath}\n`);
      successCount++;
    } else {
      console.log('');
    }
  }

  console.log(`Summary: ${successCount}/${chainsToProcess.length} generated`);

  if (successCount > 0) {
    console.log(`\nNext steps:`);
    console.log(`  1. Open Safe UI -> Apps -> Transaction Builder`);
    console.log(`  2. Upload the generated JSON file`);
    console.log(`  3. Review and execute the batch`);
  }
}

main();
