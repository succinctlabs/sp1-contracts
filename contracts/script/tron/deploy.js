/**
 * TronWeb deployment script for SP1 Verifier contracts.
 *
 * Deploys:
 *   1. SP1VerifierGateway (Groth16) — owned by deployer
 *   2. SP1VerifierGateway (Plonk)   — owned by deployer
 *   3. SP1Verifier (Groth16 v6.0.0) — registered on gateway #1
 *   4. SP1Verifier (Plonk v6.0.0)   — registered on gateway #2
 *
 * Usage:
 *   PRIVATE_KEY=<hex> TRON_API_URL=https://api.trongrid.io \
 *     node script/tron/deploy.js
 *
 * Optional env:
 *   TRON_API_KEY     — TronGrid Pro API key (for rate limits)
 *   OWNER            — Gateway owner address (hex, defaults to deployer)
 *   FEE_LIMIT        — Max TRX fee per tx in sun (default: 15_000_000_000 = 15,000 TRX)
 *   DEPLOYMENTS_DIR  — Path to deployments dir (default: ./deployments)
 *   DRY_RUN          — Set to "true" to estimate costs without deploying
 */

const { TronWeb } = require("tronweb");
const fs = require("fs");
const path = require("path");

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const PRIVATE_KEY = (process.env.PRIVATE_KEY || "").replace(/^0x/i, "");
if (!PRIVATE_KEY) {
  console.error("Error: PRIVATE_KEY env var is required");
  process.exit(1);
}

const TRON_API_URL = process.env.TRON_API_URL || "https://api.trongrid.io";
const TRON_API_KEY = process.env.TRON_API_KEY || "";
const FEE_LIMIT = parseInt(process.env.FEE_LIMIT || "15000000000", 10); // 15,000 TRX in sun
const DEPLOYMENTS_DIR = process.env.DEPLOYMENTS_DIR || path.join(__dirname, "../../deployments");
const CHAIN_ID = "728126428";
const DRY_RUN = (process.env.DRY_RUN || "").toLowerCase() === "true";
const ENERGY_SUN_PRICE = 100; // sun per energy unit (calibrated from actual Gateway deploy: 166,840 energy = 16.684 TRX)

// ---------------------------------------------------------------------------
// TronWeb setup
// ---------------------------------------------------------------------------

const headers = TRON_API_KEY ? { "TRON-PRO-API-KEY": TRON_API_KEY } : {};

const tronWeb = new TronWeb({
  fullHost: TRON_API_URL,
  headers,
  privateKey: PRIVATE_KEY,
});

const deployerBase58 = tronWeb.address.fromPrivateKey(PRIVATE_KEY);
const deployerHex = tronWeb.address.toHex(deployerBase58);
// OWNER must be 41-prefixed Tron hex (21 bytes). TronWeb uses this format natively.
const OWNER = (() => {
  if (!process.env.OWNER) return deployerHex;
  const hex = tronWeb.address.toHex(process.env.OWNER);
  // toHex may return 0x-prefixed on some TronWeb versions; normalize to 41-prefix
  if (hex.startsWith("0x")) return "41" + hex.slice(2);
  return hex;
})();
if (!OWNER.startsWith("41") || OWNER.length !== 42) {
  console.error(`Invalid OWNER address (expected 41-prefixed hex): ${OWNER}`);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Artifact loading
// ---------------------------------------------------------------------------

function loadArtifact(artifactPath) {
  const fullPath = path.resolve(__dirname, "../../out", artifactPath);
  const raw = JSON.parse(fs.readFileSync(fullPath, "utf8"));
  return {
    abi: raw.abi,
    bytecode: raw.bytecode.object,
  };
}

const ARTIFACTS = {
  gateway: loadArtifact("SP1VerifierGateway.sol/SP1VerifierGateway.json"),
  groth16Verifier: loadArtifact("v6.0.0/SP1VerifierGroth16.sol/SP1Verifier.json"),
  plonkVerifier: loadArtifact("v6.0.0/SP1VerifierPlonk.sol/SP1Verifier.json"),
};

// ---------------------------------------------------------------------------
// Deployment helpers
// ---------------------------------------------------------------------------

/**
 * Estimate the energy required for a contract deployment and return cost in TRX.
 * Pure calculation — no API calls, so no rate limit risk.
 */
function estimateDeployEnergy(artifact) {
  const bytecodeBytes = artifact.bytecode.replace(/^0x/, "").length / 2;

  // Bandwidth: ~bytecodeBytes + overhead for tx envelope (~300 bytes)
  const txSizeBytes = bytecodeBytes + 300;
  const bandwidthCostSun = txSizeBytes * 1000;

  // Energy: ~77 energy per byte (calibrated from Gateway: 166,840 energy / 2,177 bytes)
  const estimatedEnergy = 32000 + bytecodeBytes * 80;
  const energyCostSun = estimatedEnergy * ENERGY_SUN_PRICE;

  const totalSun = energyCostSun + bandwidthCostSun;
  return {
    energy: estimatedEnergy,
    energyCostTRX: energyCostSun / 1_000_000,
    bandwidthCostTRX: bandwidthCostSun / 1_000_000,
    totalTRX: totalSun / 1_000_000,
  };
}

/**
 * Deploy a contract and wait for confirmation.
 * Returns the deployed contract's hex address (41-prefixed).
 */
async function deployContract(name, artifact, constructorParams) {
  console.log(`\nDeploying ${name}...`);

  // Pre-flight cost estimate (no API calls)
  const estimate = estimateDeployEnergy(artifact);
  console.log(`  estimated energy: ~${estimate.energy} (~${estimate.totalTRX.toFixed(1)} TRX)`);

  const balance = await tronWeb.trx.getBalance(deployerHex);
  const balanceTRX = balance / 1_000_000;
  if (balanceTRX < estimate.totalTRX) {
    console.error(
      `  INSUFFICIENT BALANCE: have ${balanceTRX} TRX, need ~${estimate.totalTRX.toFixed(1)} TRX for this deployment`
    );
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log(`  [DRY RUN] skipping actual deployment`);
    return null;
  }

  const tx = await tronWeb.transactionBuilder.createSmartContract(
    {
      abi: artifact.abi,
      bytecode: artifact.bytecode,
      feeLimit: FEE_LIMIT,
      callValue: 0,
      parameters: constructorParams || [],
      name: name,
    },
    deployerHex
  );

  const signedTx = await tronWeb.trx.sign(tx, PRIVATE_KEY);
  const result = await tronWeb.trx.sendRawTransaction(signedTx);

  if (!result.result) {
    console.error(`Failed to broadcast ${name}:`, result);
    process.exit(1);
  }

  const txId = result.txid;
  console.log(`  tx: ${txId}`);

  // Wait for confirmation
  const receipt = await waitForConfirmation(txId);
  const contractAddress = receipt.contract_address;
  if (!contractAddress) {
    console.error(`No contract address in receipt for ${name}. Deployment may have run out of energy:`, receipt);
    process.exit(1);
  }

  // Verify the deployment actually succeeded (not OUT_OF_ENERGY)
  if (receipt.receipt && receipt.receipt.result && receipt.receipt.result !== "SUCCESS") {
    console.error(`  Deployment ${name} failed with: ${receipt.receipt.result}`);
    console.error(`  Energy used: ${receipt.receipt.energy_usage_total || 0}`);
    console.error(`  Energy fee: ${(receipt.receipt.energy_fee || 0) / 1_000_000} TRX`);
    process.exit(1);
  }

  console.log(`  address (hex): ${contractAddress}`);
  console.log(`  address (base58): ${tronWeb.address.fromHex(contractAddress)}`);
  console.log(`  actual energy: ${receipt.receipt.energy_usage_total || "N/A"}`);

  return contractAddress;
}

/**
 * Check if a route is already registered on a gateway by calling routes(bytes4).
 * Returns true if a non-zero verifier address is registered for the selector.
 */
async function isRouteRegistered(gatewayAddr, verifierAddr) {
  // Get the verifier's VERIFIER_HASH to derive the selector (first 4 bytes)
  const hashResult = await tronWeb.transactionBuilder.triggerConstantContract(
    verifierAddr,
    "VERIFIER_HASH()",
    {},
    [],
    deployerHex
  );
  const verifierHash = hashResult.constant_result[0];
  const selector = "0x" + verifierHash.slice(0, 8);

  // Query gateway.routes(bytes4) — returns (address verifier, bool frozen)
  const routeResult = await tronWeb.transactionBuilder.triggerConstantContract(
    gatewayAddr,
    "routes(bytes4)",
    {},
    [{ type: "bytes4", value: selector }],
    deployerHex
  );
  const routeAddr = routeResult.constant_result[0].slice(24, 64);
  return routeAddr !== "0000000000000000000000000000000000000000";
}

/**
 * Call a write function on a deployed contract.
 */
async function callContract(name, contractAddress, functionSelector, params, paramTypes) {
  console.log(`\nCalling ${name}...`);

  const tx = await tronWeb.transactionBuilder.triggerSmartContract(
    contractAddress,
    functionSelector,
    { feeLimit: FEE_LIMIT, callValue: 0 },
    paramTypes.map((type, i) => ({ type, value: params[i] })),
    deployerHex
  );

  if (!tx.result || !tx.result.result) {
    console.error(`Failed to build tx for ${name}:`, tx);
    process.exit(1);
  }

  await sleep(API_DELAY_MS);
  const signedTx = await tronWeb.trx.sign(tx.transaction, PRIVATE_KEY);
  await sleep(API_DELAY_MS);
  const result = await tronWeb.trx.sendRawTransaction(signedTx);

  if (!result.result) {
    console.error(`Failed to broadcast ${name}:`, result);
    process.exit(1);
  }

  console.log(`  tx: ${result.txid}`);
  await waitForConfirmation(result.txid);
  console.log(`  confirmed`);
}

/**
 * Wait for a transaction to be confirmed on-chain.
 */
async function waitForConfirmation(txId, maxAttempts = 30, intervalMs = 3000) {
  for (let i = 0; i < maxAttempts; i++) {
    await sleep(intervalMs);
    const info = await tronWeb.trx.getTransactionInfo(txId);
    if (info && info.id) {
      if (info.receipt && info.receipt.result === "FAILED") {
        console.error(`Transaction ${txId} failed:`, info);
        process.exit(1);
      }
      return info;
    }
  }
  console.error(`Transaction ${txId} not confirmed after ${maxAttempts} attempts`);
  process.exit(1);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// TronGrid free tier: 3 req/s. Add delay between sequential API-heavy operations.
const API_DELAY_MS = 2000;

// ---------------------------------------------------------------------------
// Deployment record
// ---------------------------------------------------------------------------

function loadDeployments() {
  const filePath = path.join(DEPLOYMENTS_DIR, `${CHAIN_ID}.json`);
  if (fs.existsSync(filePath)) {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  }
  return {};
}

function saveDeployments(data) {
  if (!fs.existsSync(DEPLOYMENTS_DIR)) {
    fs.mkdirSync(DEPLOYMENTS_DIR, { recursive: true });
  }
  const filePath = path.join(DEPLOYMENTS_DIR, `${CHAIN_ID}.json`);
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + "\n");
  console.log(`\nDeployments saved to ${filePath}`);
}

/**
 * Convert a Tron hex address (41-prefixed) to base58 for the JSON record.
 * Tron ecosystem uses base58 as the standard address format.
 */
function toBase58(hexAddr) {
  if (hexAddr.startsWith("0x")) {
    hexAddr = "41" + hexAddr.slice(2);
  }
  return tronWeb.address.fromHex(hexAddr);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  console.log("=== SP1 Verifier Tron Deployment ===");
  console.log(`API: ${TRON_API_URL}`);
  console.log(`Deployer (hex): ${deployerHex}`);
  console.log(`Deployer (base58): ${deployerBase58}`);
  console.log(`Owner: ${OWNER} (${tronWeb.address.fromHex(OWNER)})`);
  console.log(`Fee limit: ${FEE_LIMIT} sun (${FEE_LIMIT / 1_000_000} TRX)`);
  if (DRY_RUN) console.log(`Mode: DRY RUN (estimate only, no transactions)`);

  // Check balance
  const balance = await tronWeb.trx.getBalance(deployerHex);
  console.log(`Balance: ${balance / 1_000_000} TRX`);

  if (balance < FEE_LIMIT * 6) {
    console.warn(
      `WARNING: Balance may be insufficient for 4 deployments + 2 route registrations.` +
        ` Recommended: ${(FEE_LIMIT * 6) / 1_000_000} TRX`
    );
  }

  const deployments = loadDeployments();

  /**
   * Resume-aware deploy: if a key already exists in deployments JSON AND the contract
   * has bytecode on-chain, skip re-deployment. Otherwise deploy fresh.
   */
  async function resumableDeploy(key, name, artifact, constructorParams) {
    const existing = deployments[key];
    if (existing) {
      // existing is base58 (T...) — getContract accepts base58 directly
      const hexAddr = tronWeb.address.toHex(existing);
      const contract = await tronWeb.trx.getContract(existing);
      if (contract.bytecode && contract.bytecode.length > 0) {
        console.log(`\nSkipping ${name} — already deployed at ${existing}`);
        return hexAddr;
      }
      console.log(`\n${name} recorded at ${existing} but has no bytecode on-chain. Re-deploying...`);
    }
    const addr = await deployContract(name, artifact, constructorParams);
    if (addr) {
      deployments[key] = toBase58(addr);
      saveDeployments(deployments);
    }
    return addr;
  }

  // --- Groth16 first (Across only uses Groth16) ---

  // 1. Deploy Groth16 Gateway
  const groth16GatewayAddr = await resumableDeploy(
    "SP1_VERIFIER_GATEWAY_GROTH16",
    "SP1VerifierGateway (Groth16)",
    ARTIFACTS.gateway,
    [OWNER]
  );
  await sleep(API_DELAY_MS);

  // 2. Deploy Groth16 Verifier (v6.0.0)
  const groth16VerifierAddr = await resumableDeploy(
    "V6_0_0_SP1_VERIFIER_GROTH16",
    "SP1Verifier (Groth16 v6.0.0)",
    ARTIFACTS.groth16Verifier
  );

  if (DRY_RUN) {
    console.log("\n--- Groth16 estimate complete (~88 TRX total with route) ---");
  }

  await sleep(API_DELAY_MS);

  // 3. Register Groth16 route (skip if already registered)
  if (!DRY_RUN && groth16GatewayAddr && groth16VerifierAddr) {
    if (await isRouteRegistered(groth16GatewayAddr, groth16VerifierAddr)) {
      console.log("\nGroth16 route already registered — skipping");
    } else {
      console.log("\nRegistering Groth16 route...");
      await callContract(
        "addRoute (Groth16)",
        groth16GatewayAddr,
        "addRoute(address)",
        [groth16VerifierAddr],
        ["address"]
      );
    }
    console.log("\n=== Groth16 deployment complete — Across can use this now ===");
  }

  // --- Plonk (lower priority, deploy if balance allows) ---
  await sleep(API_DELAY_MS);

  // 4. Deploy Plonk Gateway
  const plonkGatewayAddr = await resumableDeploy(
    "SP1_VERIFIER_GATEWAY_PLONK",
    "SP1VerifierGateway (Plonk)",
    ARTIFACTS.gateway,
    [OWNER]
  );

  await sleep(API_DELAY_MS);

  // 5. Deploy Plonk Verifier (v6.0.0)
  const plonkVerifierAddr = await resumableDeploy(
    "V6_0_0_SP1_VERIFIER_PLONK",
    "SP1Verifier (Plonk v6.0.0)",
    ARTIFACTS.plonkVerifier
  );

  if (DRY_RUN) {
    console.log("\n=== DRY RUN COMPLETE ===");
    console.log("Route registration: ~2 TRX (minimal energy)");
    return;
  }

  await sleep(API_DELAY_MS);

  // 6. Register Plonk route (skip if already registered)
  if (plonkGatewayAddr && plonkVerifierAddr) {
    if (await isRouteRegistered(plonkGatewayAddr, plonkVerifierAddr)) {
      console.log("\nPlonk route already registered — skipping");
    } else {
      console.log("\nRegistering Plonk route...");
      await callContract(
        "addRoute (Plonk)",
        plonkGatewayAddr,
        "addRoute(address)",
        [plonkVerifierAddr],
        ["address"]
      );
    }
  }

  // Final save
  saveDeployments(deployments);

  // Summary
  console.log("\n=== Deployment Complete ===");
  console.log("Groth16 Gateway:", deployments["SP1_VERIFIER_GATEWAY_GROTH16"]);
  console.log("Plonk Gateway:  ", deployments["SP1_VERIFIER_GATEWAY_PLONK"]);
  console.log("Groth16 v6.0.0: ", deployments["V6_0_0_SP1_VERIFIER_GROTH16"]);
  console.log("Plonk v6.0.0:   ", deployments["V6_0_0_SP1_VERIFIER_PLONK"]);

  const addrs = [
    ["Gateway (Groth16)", groth16GatewayAddr],
    ["Gateway (Plonk)", plonkGatewayAddr],
    ["Verifier (Groth16)", groth16VerifierAddr],
    ["Verifier (Plonk)", plonkVerifierAddr],
  ];
  console.log("\nTronScan links:");
  for (const [label, addr] of addrs) {
    console.log(`  ${label}: https://tronscan.org/#/contract/${tronWeb.address.fromHex(addr)}`);
  }
}

main().catch((err) => {
  console.error("Deployment failed:", err);
  process.exit(1);
});
