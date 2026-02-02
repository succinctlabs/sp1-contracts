# SP1 Contracts

This repository contains the smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs.

## Installation

To install the latest release version:

```bash
forge install succinctlabs/sp1-contracts
```

Add `@sp1-contracts/=lib/sp1-contracts/contracts/src/` in `remappings.txt`.

### Usage

Once installed, you can import the `ISP1Verifier` interface and use it in your contract:

```solidity
pragma solidity ^0.8.20;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

contract MyContract {
    /// @dev Use the gateway address for your chain from the deployments/ folder
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

### Deployments

To deploy contracts, configure your [.env](./contracts/.env.example) file:

```bash
cd sp1-contracts/contracts

# Create .env with your values
PRIVATE_KEY=0x...
RPC_MAINNET=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY  # Use Alchemy/Infura, not public RPCs
ETHERSCAN_API_KEY=...
```

> **Important**:
> - Run `source .env` before any forge commands (the scripts read env vars directly)
> - The `--rpc-url` CLI flag is ignored; scripts read `RPC_<CHAIN>` from environment
> - Specify target chain with `CHAINS=` env var (e.g., `CHAINS=MAINNET`)

Deploy the SP1 Verifier Gateway:

```bash
# Groth16 gateway
CHAINS=MAINNET FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/SP1VerifierGatewayGroth16.s.sol:SP1VerifierGatewayScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --broadcast

# Plonk gateway (use different CREATE2_SALT to avoid collision)
CHAINS=MAINNET FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/SP1VerifierGatewayPlonk.s.sol:SP1VerifierGatewayScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --broadcast
```

### Adding Verifiers

Deploy verifiers and optionally register them with the gateway:

```bash
# Deploy Groth16 verifier
CHAINS=MAINNET FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/v6.0.0-beta.1/SP1VerifierGroth16.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --broadcast

# Deploy Plonk verifier
CHAINS=MAINNET FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/v6.0.0-beta.1/SP1VerifierPlonk.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --verify --verifier etherscan --broadcast
```

By default, `REGISTER_ROUTE=false` so verifiers are deployed without registering routes. This is intended for multisig-owned gateways where route registration requires a separate multisig transaction.

To deploy AND register routes in one step (only works if deployer owns the gateway):

```bash
REGISTER_ROUTE=true CHAINS=MAINNET FOUNDRY_PROFILE=deploy forge script ...
```

For multisig gateways, use the Safe Transaction Builder JSON generator after deploying:

```bash
node script/utils/generate-safe-batch.js --chain=1 --version=v6.0.0-beta.1
```

### Freezing Verifiers

> [!WARNING]
> Once frozen, a verifier cannot be unfrozen and can no longer be routed to.

```bash
CHAINS=MAINNET FOUNDRY_PROFILE=deploy forge script \
  ./script/deploy/v6.0.0-beta.1/SP1VerifierPlonk.s.sol:SP1VerifierScript \
  --private-key $PRIVATE_KEY --broadcast --sig "freeze()"
```

## For Developers: Integrate SP1 Contracts

This repository contains the EVM contracts for verifying SP1 PLONK EVM proofs.

You can find more details on the contracts in the [`contracts`](./contracts/README.md) directory.

Note: you should ensure that all the contracts are on Solidity version `0.8.20`.

## For Contributors

To update the SP1 contracts, please refer to the [`update`](./UPDATE_CONTRACTS.md) file.

## Security

SP1 Contracts has undergone an audit from [Veridise](https://www.veridise.com/). The audit report is available [here](./audits).
