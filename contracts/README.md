# SP1 Contracts

This repository contains the smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs. 

## Overview
- [`ISP1Verifier`](./src/ISP1Verifier.sol): Interface for SP1 proof verification.
- [`SP1VerifierGateway`](./src/SP1VerifierGateway.sol): Gateway contract that routes proofs to the correct versioned verifier.
- [`SP1MockVerifier`](./src/SP1MockVerifier.sol): A mock contract for testing SP1 EVM proofs.
- `src/v*/SP1VerifierPlonk.sol`: Versioned Plonk verifier contracts.
- `src/v*/SP1VerifierGroth16.sol`: Versioned Groth16 verifier contracts.
