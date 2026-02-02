#!/usr/bin/env node
/**
 * Generates Safe Transaction Builder JSON for adding verifier routes
 *
 * This script creates JSON files that can be uploaded directly to Safe UI's
 * Transaction Builder, eliminating manual copy/paste errors when registering
 * new verifiers with the gateway multisig.
 *
 * Usage:
 *   node generate-safe-batch.js --chain=1 --version=v6.0.0-beta.1
 *   node generate-safe-batch.js --chain=all --version=v6.0.0-beta.1
 *
 * Output:
 *   Creates JSON files in contracts/safe-batches/ directory
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

/**
 * Encodes the addRoute(address) calldata
 * @param {string} verifierAddress - The verifier contract address (with 0x prefix)
 * @returns {string} - The encoded calldata
 */
function encodeAddRoute(verifierAddress) {
  // Remove 0x prefix, lowercase, and pad to 32 bytes (64 hex chars)
  const paddedAddress = verifierAddress.slice(2).toLowerCase().padStart(64, '0');
  return ADD_ROUTE_SELECTOR + paddedAddress;
}

/**
 * Converts version string to deployment key format
 * Examples:
 *   v6.0.0-beta.1 -> V6_0_0_BETA_1
 *   v4.0.0-rc.3   -> V4_0_0_RC_3
 *   v5.0.0        -> V5_0_0
 * @param {string} version - Version string (e.g., "v6.0.0-beta.1")
 * @returns {string} - Deployment key format (e.g., "V6_0_0_BETA_1")
 */
function versionToKey(version) {
  return version
    .toUpperCase()
    .replace(/\./g, '_')
    .replace(/-/g, '_');
}

/**
 * Creates a Safe Transaction Builder transaction object
 * @param {string} gatewayAddress - The gateway contract address
 * @param {string} verifierAddress - The verifier contract address
 * @returns {object} - Transaction object for Safe Transaction Builder
 */
function createTransaction(gatewayAddress, verifierAddress) {
  return {
    to: gatewayAddress,
    value: '0',
    data: encodeAddRoute(verifierAddress),
    operation: 0, // Call (not delegatecall)
    contractMethod: {
      inputs: [
        {
          internalType: 'address',
          name: 'verifier',
          type: 'address'
        }
      ],
      name: 'addRoute',
      payable: false
    },
    contractInputsValues: {
      verifier: verifierAddress
    }
  };
}

/**
 * Generates a Safe Transaction Builder batch for a specific chain
 * @param {number} chainId - The chain ID
 * @param {string} version - The version string (e.g., "v6.0.0-beta.1")
 * @returns {object|null} - The batch object or null if no verifiers found
 */
function generateBatch(chainId, version) {
  const deploymentPath = path.join(__dirname, '../../deployments', `${chainId}.json`);

  if (!fs.existsSync(deploymentPath)) {
    console.error(`No deployment file for chain ${chainId}`);
    return null;
  }

  const deployments = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'));

  // Read gateway addresses from deployment file
  const groth16Gateway = deployments['SP1_VERIFIER_GATEWAY_GROTH16'];
  const plonkGateway = deployments['SP1_VERIFIER_GATEWAY_PLONK'];

  if (!groth16Gateway || !plonkGateway) {
    console.error(`Missing gateway addresses in deployment file for chain ${chainId}`);
    return null;
  }

  // Build verifier keys based on version
  const versionKey = versionToKey(version);
  const groth16Key = `${versionKey}_SP1_VERIFIER_GROTH16`;
  const plonkKey = `${versionKey}_SP1_VERIFIER_PLONK`;

  const transactions = [];

  // Add Groth16 route if verifier exists
  if (deployments[groth16Key]) {
    transactions.push(createTransaction(groth16Gateway, deployments[groth16Key]));
    console.log(`  Groth16: ${deployments[groth16Key]} -> ${groth16Gateway}`);
  }

  // Add Plonk route if verifier exists
  if (deployments[plonkKey]) {
    transactions.push(createTransaction(plonkGateway, deployments[plonkKey]));
    console.log(`  Plonk:   ${deployments[plonkKey]} -> ${plonkGateway}`);
  }

  if (transactions.length === 0) {
    console.error(`No verifiers found for ${version} on chain ${chainId}`);
    console.error(`  Looking for keys: ${groth16Key}, ${plonkKey}`);
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

/**
 * Parses command line arguments
 * @returns {object} - Parsed arguments
 */
function parseArgs() {
  const args = process.argv.slice(2);
  const result = {
    chain: 'all',
    version: 'v6.0.0-beta.1',
    help: false
  };

  for (const arg of args) {
    if (arg === '--help' || arg === '-h') {
      result.help = true;
    } else if (arg.startsWith('--chain=')) {
      result.chain = arg.split('=')[1];
    } else if (arg.startsWith('--version=')) {
      result.version = arg.split('=')[1];
    }
  }

  return result;
}

/**
 * Prints usage information
 */
function printUsage() {
  console.log(`
Safe Transaction Builder JSON Generator
=======================================

Generates JSON files for Safe UI Transaction Builder to add verifier routes.

Usage:
  node generate-safe-batch.js [options]

Options:
  --chain=<id|all>     Chain ID or 'all' for all supported chains (default: all)
  --version=<version>  Version string, e.g., v6.0.0-beta.1 (default: v6.0.0-beta.1)
  --help, -h           Show this help message

Supported Chains:
${Object.entries(CHAINS).map(([id, name]) => `  ${id}: ${name}`).join('\n')}

Examples:
  node generate-safe-batch.js --chain=1 --version=v6.0.0-beta.1
  node generate-safe-batch.js --chain=all --version=v5.0.0

Output:
  Files are written to contracts/safe-batches/<chainId>_<version>.json
  Upload these files to Safe UI -> Apps -> Transaction Builder -> Load
`);
}

// Main execution
function main() {
  const args = parseArgs();

  if (args.help) {
    printUsage();
    process.exit(0);
  }

  console.log(`\nGenerating Safe Transaction Builder batches`);
  console.log(`  Version: ${args.version}`);
  console.log(`  Chains:  ${args.chain === 'all' ? 'all supported chains' : args.chain}\n`);

  // Create output directory
  const outputDir = path.join(__dirname, '../../safe-batches');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Determine which chains to process
  const chainsToProcess = args.chain === 'all'
    ? Object.keys(CHAINS).map(Number)
    : [parseInt(args.chain)];

  let successCount = 0;
  let failCount = 0;

  for (const chainId of chainsToProcess) {
    const chainName = CHAINS[chainId] || `Chain ${chainId}`;
    console.log(`Processing ${chainName} (${chainId})...`);

    const batch = generateBatch(chainId, args.version);

    if (batch) {
      // Generate filename: 1_v6_0_0_beta_1.json
      const versionFilename = args.version.replace(/\./g, '_').replace(/-/g, '_');
      const outputPath = path.join(outputDir, `${chainId}_${versionFilename}.json`);

      fs.writeFileSync(outputPath, JSON.stringify(batch, null, 2));
      console.log(`  -> ${outputPath}\n`);
      successCount++;
    } else {
      failCount++;
      console.log('');
    }
  }

  console.log(`\nSummary: ${successCount} generated, ${failCount} skipped`);

  if (successCount > 0) {
    console.log(`\nNext steps:`);
    console.log(`  1. Open Safe UI for each chain`);
    console.log(`  2. Go to Apps -> Transaction Builder`);
    console.log(`  3. Click "Upload JSON" and select the generated file`);
    console.log(`  4. Review transactions and execute the batch`);
  }
}

main();
