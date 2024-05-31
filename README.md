# SP1 Contracts

This repository contains the smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs.

## Installation

> [!WARNING]
> Foundry installs the latest release version initially, but subsequent `forge update` commands will use the `main` branch. This branch is the development branch and should be avoided in favor of tagged releases. The release process matches a specific SP1 version.

To install with [Foundry](https://github.com/foundry-rs/foundry):

```bash
forge install succinctlabs/sp1-contracts
```

To install a specific version (to verify proofs generated with a specific SP1 version):
```bash
forge install succinctlabs/sp1-contracts@<version>
```

Add `@sp1-contracts/=lib/sp1-contracts/contracts/src/` in `remappings.txt.`

### Usage

Once installed, you can use the contracts in the library by importing them:

```solidity
pragma solidity ^0.8.25;

import {SP1Verifier} from "@sp1-contracts/SP1Verifier.sol";

contract MyContract is SP1Verifier {
}
```

## For Developers: Integrate SP1 Contracts

This repository contains the EVM contracts for verifying SP1 PLONK EVM proofs.

You can find more details on the contracts in the [`contracts`](./contracts/README.md) directory.

## For Contributors

To update the SP1 contracts, please refer to the [`update`](./UPDATE_CONTRACTS.md) file.