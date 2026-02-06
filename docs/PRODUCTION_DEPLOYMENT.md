# Canonical Verifier Gateway Management

This guide covers how the canonical SP1 verifier gateways are deployed and managed by Succinct Labs. These are the gateways that SP1 users integrate with to verify proofs on-chain.

For the full list of deployed gateway addresses, see: https://docs.succinct.xyz/docs/sp1/verification/contract-addresses

## How It Works

- Canonical gateways are deployed across all supported chains (Ethereum, Arbitrum, Base, Optimism, Scroll, etc.) with identical addresses via CREATE2.
- Gateways are owned by a multisig. Only the multisig can add or freeze routes.
- When a new SP1 version is released, new verifier contracts are deployed by an EOA, then registered as routes on the gateways via a multisig transaction.
- Problematic versions can be permanently frozen via `freezeRoute()`.
- **Release policy**: only official releases are deployed to mainnets. Testnets may include release candidates.

## Prerequisites

### Access

| Item | Description |
|------|-------------|
| Deployer EOA | EOA with ETH on all target chains (deploys verifier contracts) |
| Multisig signer | Signer on the gateway owner multisig (registers routes) |
| Etherscan API keys | One per target chain for contract verification |

### Software

```bash
node --version    # 18+
forge --version   # Foundry
git --version
```

### Setup

```bash
git clone https://github.com/succinctlabs/sp1-contracts.git
cd sp1-contracts/contracts
forge install
```

Configure `.env` with all target chains (see [`.env.example`](../contracts/.env.example)):

```bash
cp .env.example .env
# Fill in: PRIVATE_KEY, CREATE2_SALT, all RPC_* and ETHERSCAN_API_KEY_* entries
source .env
```

## Phase 1: Deploy Verifiers

Deploy verifier contracts to all target chains. `REGISTER_ROUTE` defaults to `false` because the deployer EOA is not the gateway owner — route registration happens separately via multisig in Phase 2.

```bash
# Groth16
CHAINS=MAINNET,OPTIMISM,ARBITRUM,BASE,SCROLL \
FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/<version>/SP1VerifierGroth16.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast

# Plonk
CHAINS=MAINNET,OPTIMISM,ARBITRUM,BASE,SCROLL \
FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/<version>/SP1VerifierPlonk.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

> Replace `<version>` with the target version (e.g. `v6.0.0-beta.1`). Available versions are in `script/deploy/`.

Verify that addresses were written:

```bash
cat deployments/1.json | jq . | grep <VERSION_KEY>
# e.g. grep V6_0_0_BETA_1
```

Commit and push the deployment files:

```bash
git add deployments/
git commit -m "deploy: <version> verifiers"
git push
```

## Phase 2: Register Routes via Multisig

### Generate Safe Transaction Builder JSON

```bash
node script/utils/generate-safe-batch.js --chain=all --version=<version>
```

This reads verifier addresses from `deployments/*.json` and generates Safe Transaction Builder JSON files. For example, with `--version=v6.0.0-beta.1`:

```
safe-batches/1_v6_0_0_beta_1.json      # Ethereum
safe-batches/10_v6_0_0_beta_1.json     # Optimism
safe-batches/42161_v6_0_0_beta_1.json  # Arbitrum
safe-batches/8453_v6_0_0_beta_1.json   # Base
safe-batches/534352_v6_0_0_beta_1.json # Scroll
```

Each file contains `addRoute()` transactions for both Groth16 and Plonk verifiers on that chain.

To generate for a specific chain:

```bash
node script/utils/generate-safe-batch.js --chain=1 --version=<version>
```

### First Signer

1. Open [Safe UI](https://app.safe.global) for the gateway owner multisig on the target chain.
2. Connect your wallet.
3. Go to **Apps → Transaction Builder**.
4. Upload the generated JSON file for that chain.
5. Verify: correct number of transactions (2 per chain — one Groth16, one Plonk), correct verifier and gateway addresses.
6. **Simulate** — verify `RouteAdded` events appear in the simulation.
7. **Sign** the transaction.

### Second Signer

1. Open Safe UI, connect wallet.
2. Find the pending transaction (shows "1 of 2 confirmations").
3. **Simulate** again to double-check.
4. **Sign & Execute**.
5. Verify `RouteAdded` events in the transaction receipt.

Repeat for each target chain.

## Phase 3: Verify

Check that routes are registered on each chain:

```bash
GATEWAY=$(cat deployments/1.json | jq -r '.SP1_VERIFIER_GATEWAY_GROTH16')
VERIFIER=$(cat deployments/1.json | jq -r '.V6_0_0_BETA_1_SP1_VERIFIER_GROTH16')

SELECTOR=$(cast call $VERIFIER "VERIFIER_HASH()" --rpc-url $RPC_MAINNET | cut -c1-10)
cast call $GATEWAY "routes(bytes4)" $SELECTOR --rpc-url $RPC_MAINNET
# Should return the verifier address (non-zero = route registered)
```

Repeat for Plonk and for each target chain.

After verification, ensure the [contract addresses docs page](https://docs.succinct.xyz/docs/sp1/verification/contract-addresses) is updated if new chains were added.

## Troubleshooting

| Error | Solution |
|-------|----------|
| `insufficient funds` | Fund the deployer EOA on the target chain |
| `contract already deployed` | Expected with CREATE2 — same salt produces same address. This is fine. |
| Etherscan verification failed | Add `--delay 30` flag to the forge command, or verify manually on Etherscan later |
| Safe simulation failed | Check that the verifier address is correct and the gateway is not frozen |
| `No verifiers for <version>` | Run Phase 1 first — verifier addresses must exist in `deployments/*.json` |
| `generate-safe-batch.js` not found | Make sure you're running from the `contracts/` directory |

## Quick Reference

```bash
# Generate Safe batch for all mainnet chains
node script/utils/generate-safe-batch.js --chain=all --version=<version>

# Generate for a specific chain
node script/utils/generate-safe-batch.js --chain=1 --version=<version>

# Check deployment addresses
cat deployments/1.json | jq .

# Check gateway owner
cast call $(cat deployments/1.json | jq -r '.SP1_VERIFIER_GATEWAY_GROTH16') "owner()" --rpc-url $RPC_MAINNET

# Check if a route exists
SELECTOR=$(cast call $VERIFIER "VERIFIER_HASH()" --rpc-url $RPC_MAINNET | cut -c1-10)
cast call $GATEWAY "routes(bytes4)" $SELECTOR --rpc-url $RPC_MAINNET
```
