# SP1 Contracts

This repository contains the smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs.

## Installation

To install the latest release version:

```bash
forge install succinctlabs/sp1-contracts
```

Add `@sp1-contracts/=lib/sp1-contracts/contracts/src/` in `remappings.txt`.

## Usage

Once installed, you can import the `ISP1Verifier` interface and use it in your contract:

```solidity
pragma solidity ^0.8.20;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

contract MyContract {
    /// @dev Use the gateway address for your chain from the deployments/ folder.
    address public SP1_VERIFIER;

    bytes32 public constant PROGRAM_VKEY = ...;

    function myFunction(..., bytes calldata publicValues, bytes calldata proofBytes) external {
        ISP1Verifier(SP1_VERIFIER).verifyProof(PROGRAM_VKEY, publicValues, proofBytes);
    }
}
```

You can obtain the correct `SP1_VERIFIER` address for your chain by looking in the [deployments](./contracts/deployments) directory. Use the `SP1_VERIFIER_GATEWAY` address which automatically routes proofs to the correct verifier based on their version.

You can obtain the correct `PROGRAM_VKEY` for your program by calling the `setup` function for your ELF:

```rs
let client = ProverClient::new();
let (_, vk) = client.setup(ELF);
println!("PROGRAM_VKEY = {}", vk.bytes32());
```

## Deploy Your Own Verifiers

This section walks through deploying your own SP1 verifier gateway and verifiers. This is useful for testing on testnets or deploying to a chain not yet supported by the canonical deployments.

> For canonical Succinct-managed deployments, see [Deployed Addresses](#deployed-addresses).

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js 18+
- Git

### Setup

```bash
git clone https://github.com/succinctlabs/sp1-contracts.git
cd sp1-contracts/contracts
forge install
```

Copy and configure the environment file:

```bash
cp .env.example .env
```

Fill in the following values in `.env`:

| Variable | Description |
|----------|-------------|
| `PRIVATE_KEY` | Deployer EOA private key |
| `CREATE2_SALT` | Salt for deterministic deployment (e.g. `0x0000000000000000000000000000000000000000000000000000000000000001`) |
| `OWNER` | Address that will own the gateway (your deployer address for testing) |
| `CHAINS` | Target chains, comma-separated (e.g. `SEPOLIA`) |
| `RPC_<CHAIN>` | RPC endpoint for each chain (e.g. `RPC_SEPOLIA=https://...`) |
| `ETHERSCAN_API_KEY_<CHAIN>` | Etherscan API key for contract verification |
| `ETHERSCAN_API_URL_<CHAIN>` | Etherscan API URL for each chain |

Then load the environment:

```bash
source .env
```

> **Note**: The deploy scripts read RPC endpoints from environment variables (`RPC_<CHAIN>`), not from the `--rpc-url` CLI flag.

### Step 1: Deploy Gateways

Deploy the verifier gateways. The `OWNER` address will be the only address able to add and freeze routes.

```bash
# Groth16 gateway
FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/SP1VerifierGatewayGroth16.s.sol:SP1VerifierGatewayScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast

# Plonk gateway
FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/SP1VerifierGatewayPlonk.s.sol:SP1VerifierGatewayScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

Gateway addresses are written to `deployments/<chainId>.json`.

### Step 2: Deploy Verifiers & Register Routes

Deploy verifiers and register them with the gateway in a single step. Since you own the gateway, set `REGISTER_ROUTE=true`:

```bash
# Groth16 verifier
REGISTER_ROUTE=true FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/v6.0.0-beta.1/SP1VerifierGroth16.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast

# Plonk verifier
REGISTER_ROUTE=true FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/v6.0.0-beta.1/SP1VerifierPlonk.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --multi --broadcast
```

> Change `v6.0.0-beta.1` to the desired SP1 version. Available versions are in `script/deploy/`.

Verify the deployment:

```bash
cat deployments/<chainId>.json | jq .
```

### Step 3: Verify On-chain

Check that routes are registered on the gateway:

```bash
GATEWAY=$(cat deployments/<chainId>.json | jq -r '.SP1_VERIFIER_GATEWAY_GROTH16')
VERIFIER=$(cat deployments/<chainId>.json | jq -r '.V6_0_0_BETA_1_SP1_VERIFIER_GROTH16')

SELECTOR=$(cast call $VERIFIER "VERIFIER_HASH()" --rpc-url $RPC_SEPOLIA | cut -c1-10)
cast call $GATEWAY "routes(bytes4)" $SELECTOR --rpc-url $RPC_SEPOLIA
# Should return the verifier address (non-zero)
```

### Multi-chain Deployment

To deploy across multiple chains, set `CHAINS` to a comma-separated list:

```bash
CHAINS=SEPOLIA,HOLESKY
```

Each chain requires its own `RPC_<CHAIN>`, `ETHERSCAN_API_KEY_<CHAIN>`, and `ETHERSCAN_API_URL_<CHAIN>` entries in `.env`. See [`.env.example`](./contracts/.env.example) for all supported chains.

## Deployed Addresses

Succinct Labs maintains canonical verifier gateways across all major chains. You can find the full list of deployed addresses at:

- **Docs**: https://docs.succinct.xyz/docs/sp1/verification/contract-addresses
- **This repo**: [`contracts/deployments/`](./contracts/deployments/) (JSON files keyed by chain ID)

For production gateway management, see the [production deployment guide](./docs/PRODUCTION_DEPLOYMENT.md).

## Freezing Verifiers

> [!WARNING]
> Once frozen, a verifier cannot be unfrozen and can no longer be routed to.

```bash
FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/v6.0.0-beta.1/SP1VerifierPlonk.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --multi --broadcast --sig "freeze()"
```

## Architecture

The SP1 verification system uses a gateway pattern:

- **SP1VerifierGateway** routes proof verification calls to the correct versioned verifier. The first 4 bytes of the proof are a selector derived from the verifier's `VERIFIER_HASH`, which the gateway uses to look up the registered route.
- Each SP1 version has both **Groth16** and **Plonk** verifier variants, deployed behind separate gateways.
- The gateway owner can **add routes** (register new verifier versions) and **freeze routes** (permanently disable a verifier version).

See [`contracts/`](./contracts/README.md) for more details on the contract structure.

## For Contributors

To update the SP1 contracts with a new version, see the [update guide](./UPDATE_CONTRACTS.md).

## Security

SP1 Contracts has undergone an audit from [Veridise](https://www.veridise.com/). The audit report is available [here](./audits).
