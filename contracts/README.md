# SP1 Contracts

This repository contains the smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs. 

## Overview
The repository supports both PLONK and Groth16 proof systems:

### Core Contracts
- [`ISP1Verifier`](./src/ISP1Verifier.sol): Interface for SP1 verifiers
- [`ISP1VerifierGateway`](./src/ISP1VerifierGateway.sol): Interface for the verifier gateway
- [`SP1VerifierGateway`](./src/SP1VerifierGateway.sol): Gateway contract that routes to appropriate verifier versions
- [`SP1MockVerifier`](./src/SP1MockVerifier.sol): Mock contract for testing

### Verifier Implementations by Version
Each version directory (e.g., `v5.0.0/`) contains:
- `SP1VerifierPlonk.sol`: PLONK proof verifier
- `SP1VerifierGroth16.sol`: Groth16 proof verifier
- `PlonkVerifier.sol`: Core PLONK verification logic
- `Groth16Verifier.sol`: Core Groth16 verification logic
