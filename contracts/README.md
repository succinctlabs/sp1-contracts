# SP1 Contracts

This repository contains the smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs.

## Overview
- [`ISP1Verifier`](./src/ISP1Verifier.sol): Interface for SP1 verifiers.
- [`SP1VerifierGateway`](./src/SP1VerifierGateway.sol): Gateway contract that routes proofs to the correct versioned verifier.
- [`SP1MockVerifier`](./src/SP1MockVerifier.sol): A mock contract for testing SP1 EVM proofs.
- Versioned verifiers in `src/v*/`: Plonk and Groth16 verifier implementations for each SP1 version.
