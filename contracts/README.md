# SP1 Contracts

Smart contracts for verifying [SP1](https://github.com/succinctlabs/sp1) EVM proofs.

## Contracts

- [`SP1VerifierGateway`](./src/SP1VerifierGateway.sol) — Routes proofs to the correct versioned verifier based on a 4-byte selector derived from `VERIFIER_HASH`.
- [`ISP1Verifier`](./src/ISP1Verifier.sol) — Interface for SP1 verifier contracts.
- [`ISP1VerifierGateway`](./src/ISP1VerifierGateway.sol) — Interface for the gateway.
- [`SP1MockVerifier`](./src/SP1MockVerifier.sol) — Mock verifier for testing.

Versioned verifier implementations (Groth16 and Plonk) are in `src/v*/` directories.

## Deployments

Per-chain contract addresses are in [`deployments/`](./deployments/) as JSON files keyed by chain ID (e.g., `1.json` for Ethereum mainnet).
