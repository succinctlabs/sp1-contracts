/**
 * Transfer ownership of SP1 Verifier Gateway contracts on Tron to the office ledger.
 *
 * Usage:
 *   PRIVATE_KEY=<hex> NEW_OWNER=<address> node script/tron/transfer-ownership.js
 *
 * NEW_OWNER can be EVM hex (0x...), Tron hex (41...), or Tron base58 (T...).
 * Defaults to office ledger: 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126
 */

const { TronWeb } = require("tronweb");
const fs = require("fs");
const path = require("path");

const PRIVATE_KEY = (process.env.PRIVATE_KEY || "").replace(/^0x/i, "");
if (!PRIVATE_KEY) {
  console.error("Error: PRIVATE_KEY env var is required");
  process.exit(1);
}

const TRON_API_URL = process.env.TRON_API_URL || "https://api.trongrid.io";
const TRON_API_KEY = process.env.TRON_API_KEY || "";
const FEE_LIMIT = parseInt(process.env.FEE_LIMIT || "1000000000", 10); // 1,000 TRX (ownership transfer is cheap)
const DEPLOYMENTS_DIR = process.env.DEPLOYMENTS_DIR || path.join(__dirname, "../../deployments");
const CHAIN_ID = "728126428";

const OFFICE_LEDGER = "0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126";

const headers = TRON_API_KEY ? { "TRON-PRO-API-KEY": TRON_API_KEY } : {};
const tronWeb = new TronWeb({ fullHost: TRON_API_URL, headers, privateKey: PRIVATE_KEY });

const deployerBase58 = tronWeb.address.fromPrivateKey(PRIVATE_KEY);
const deployerHex = tronWeb.address.toHex(deployerBase58);

// Resolve NEW_OWNER to 41-prefixed hex
function resolveOwner(input) {
  if (input.startsWith("T")) return tronWeb.address.toHex(input);
  if (input.startsWith("0x")) return "41" + input.slice(2);
  if (input.startsWith("41") && input.length === 42) return input;
  throw new Error(`Invalid address: ${input}`);
}

const newOwnerHex = resolveOwner(process.env.NEW_OWNER || OFFICE_LEDGER);
const newOwnerBase58 = tronWeb.address.fromHex(newOwnerHex);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

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

async function transferOwnership(name, contractAddr) {
  console.log(`\nTransferring ownership of ${name} (${contractAddr})...`);
  console.log(`  new owner: ${newOwnerBase58} (${newOwnerHex})`);

  const tx = await tronWeb.transactionBuilder.triggerSmartContract(
    contractAddr,
    "transferOwnership(address)",
    { feeLimit: FEE_LIMIT, callValue: 0 },
    [{ type: "address", value: newOwnerHex }],
    deployerHex
  );

  if (!tx.result || !tx.result.result) {
    console.error(`Failed to build tx for ${name}:`, tx);
    process.exit(1);
  }

  const signedTx = await tronWeb.trx.sign(tx.transaction, PRIVATE_KEY);
  const result = await tronWeb.trx.sendRawTransaction(signedTx);

  if (!result.result) {
    console.error(`Failed to broadcast ${name}:`, result);
    process.exit(1);
  }

  console.log(`  tx: ${result.txid}`);
  await waitForConfirmation(result.txid);
  console.log(`  confirmed`);
}

async function checkOwner(name, contractAddr) {
  const result = await tronWeb.transactionBuilder.triggerConstantContract(
    contractAddr,
    "owner()",
    {},
    [],
    deployerHex
  );
  const ownerHex = "41" + result.constant_result[0].slice(24);
  const ownerBase58 = tronWeb.address.fromHex(ownerHex);
  return { ownerHex, ownerBase58 };
}

async function main() {
  console.log("=== SP1 Gateway Ownership Transfer (Tron) ===");
  console.log(`Current owner: ${deployerBase58}`);
  console.log(`New owner:     ${newOwnerBase58}`);

  // Load deployments
  const filePath = path.join(DEPLOYMENTS_DIR, `${CHAIN_ID}.json`);
  if (!fs.existsSync(filePath)) {
    console.error(`No deployments found at ${filePath}`);
    process.exit(1);
  }
  const deployments = JSON.parse(fs.readFileSync(filePath, "utf8"));

  // Only transfer gateways specified by GATEWAYS env (default: groth16 only)
  const which = (process.env.GATEWAYS || "groth16").toLowerCase().split(",");
  const allGateways = {
    groth16: ["Groth16 Gateway", deployments["SP1_VERIFIER_GATEWAY_GROTH16"]],
    plonk: ["Plonk Gateway", deployments["SP1_VERIFIER_GATEWAY_PLONK"]],
  };
  const gateways = which.map((k) => allGateways[k.trim()]).filter(([, addr]) => addr);

  if (gateways.length === 0) {
    console.error("No gateway addresses found in deployments");
    process.exit(1);
  }

  // Verify current ownership before transfer
  for (const [name, addr] of gateways) {
    const { ownerBase58 } = await checkOwner(name, addr);
    console.log(`\n${name} (${addr}): current owner = ${ownerBase58}`);
    if (ownerBase58 === newOwnerBase58) {
      console.log(`  already owned by new owner — skipping`);
      continue;
    }
    if (ownerBase58 !== deployerBase58) {
      console.error(`  ERROR: current owner is not the deployer. Cannot transfer.`);
      process.exit(1);
    }
    await transferOwnership(name, addr);
  }

  // Verify after transfer
  console.log("\n--- Verification ---");
  for (const [name, addr] of gateways) {
    const { ownerBase58 } = await checkOwner(name, addr);
    const status = ownerBase58 === newOwnerBase58 ? "OK" : "MISMATCH";
    console.log(`${name}: owner = ${ownerBase58} [${status}]`);
  }

  console.log("\n=== Ownership transfer complete ===");
}

main().catch((err) => {
  console.error("Failed:", err);
  process.exit(1);
});
