# Phase 2: Register v6.0.0 Routes — Handoff Guide

Register v6.0.0 Groth16 + Plonk verifier routes on all 18 chain gateways.

## Prerequisites

- Phase 1 complete: 36 v6 verifiers deployed and verified across all 18 chains
- This repo checked out on `fakedev9999/deploy-v6` branch
- `.env` populated with all 18 RPC URLs (see `.env.example`)
- `cast` installed (foundry)

## Addresses

| Item | Address |
|------|---------|
| V6 Groth16 Verifier | `0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508` |
| V6 Plonk Verifier | `0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C` |
| Multisig Owner (5 mainnets) | `0xCafEf00d348Adbd57c37d1B77e0619C6244C6878` |
| Ledger EOA Owner (13 chains) | `0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126` |

## Pre-flight Check

Run this before starting to confirm all 36 routes are NOT REGISTERED:

```bash
cd contracts
./check-routes.sh
```

Expected output: **36/36 NOT REGISTERED** (clean slate).

---

## Phase 2a: Multisig Chains (5 mainnets via Safe TX Builder)

**Owner:** `0xCafEf00d348Adbd57c37d1B77e0619C6244C6878` (Safe multisig)

Each chain has a pre-generated Safe batch JSON in `safe-batches/`. Each JSON contains 2 transactions: `addRoute` for Groth16 + `addRoute` for Plonk.

> **Note:** Only the 5 mainnets use the multisig. All testnets are EOA-owned — see Phase 2b.

| # | Chain | ID | Safe Prefix | JSON File |
|---|-------|----|-------------|-----------|
| 1 | Ethereum | 1 | `eth:` | `1_add-route_v6_0_0.json` |
| 2 | Optimism | 10 | `oeth:` | `10_add-route_v6_0_0.json` |
| 3 | Arbitrum | 42161 | `arb1:` | `42161_add-route_v6_0_0.json` |
| 4 | Base | 8453 | `base:` | `8453_add-route_v6_0_0.json` |
| 5 | Scroll | 534352 | `scr:` | `534352_add-route_v6_0_0.json` |

### Steps per chain

1. Go to Safe app: `https://app.safe.global/home?safe=<PREFIX><SAFE_ADDRESS>`
   - Safe address: `0xCafEf00d348Adbd57c37d1B77e0619C6244C6878`
   - Example for Ethereum: `https://app.safe.global/home?safe=eth:0xCafEf00d348Adbd57c37d1B77e0619C6244C6878`
2. Open **Apps** > **Transaction Builder**
3. Click the upload icon (or drag-and-drop) to load the JSON file from `safe-batches/`
4. Review the 2 transactions:
   - tx1: `addRoute(0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508)` on Groth16 gateway
   - tx2: `addRoute(0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C)` on Plonk gateway
5. Click **Create Batch** > **Send Batch**
6. Collect required signatures and execute

### Spot-check after each chain

```bash
# Replace <RPC> with the chain's RPC URL from .env
# Groth16 route:
cast call 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B "routes(bytes4)(address,bool)" 0x0e78f4db --rpc-url <RPC>
# Should return: (0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508, false)

# Plonk route:
cast call 0x3B6041173B80E77f038f3F2C0f9744f04837185e "routes(bytes4)(address,bool)" 0xbb1a6f29 --rpc-url <RPC>
# Should return: (0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C, false)
```

---

## Phase 2b: Ledger Chains (13 chains via `cast send --ledger`)

**Owner:** `0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126` (EOA — requires Ledger)

### Recommended Order (testnets first)

| # | Chain | ID | Gateway (Groth16) | Gateway (Plonk) | RPC Var |
|---|-------|----|-------------------|-----------------|---------|
| 1 | Sepolia | 11155111 | `0x397A5f7f3dBd538f23DE225B51f532c34448dA9B` | `0x3B6041173B80E77f038f3F2C0f9744f04837185e` | `RPC_SEPOLIA` |
| 2 | Arbitrum Sepolia | 421614 | `0x397A5f7f3dBd538f23DE225B51f532c34448dA9B` | `0x3B6041173B80E77f038f3F2C0f9744f04837185e` | `RPC_ARBITRUM_SEPOLIA` |
| 3 | Base Sepolia | 84532 | `0x397A5f7f3dBd538f23DE225B51f532c34448dA9B` | `0x3B6041173B80E77f038f3F2C0f9744f04837185e` | `RPC_BASE_SEPOLIA` |
| 4 | OP Sepolia | 11155420 | `0x397A5f7f3dBd538f23DE225B51f532c34448dA9B` | `0x3B6041173B80E77f038f3F2C0f9744f04837185e` | `RPC_OPTIMISM_SEPOLIA` |
| 5 | Scroll Sepolia | 534351 | `0x397A5f7f3dBd538f23DE225B51f532c34448dA9B` | `0x3B6041173B80E77f038f3F2C0f9744f04837185e` | `RPC_SCROLL_SEPOLIA` |
| 6 | Hoodi | 560048 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_HOODI` |
| 7 | BSC | 56 | `0x940467b232cAD6A44FF36F2FBBe98CBd6509EFf2` | `0xfff6601146031815a84890aCBf0d926609a40249` | `RPC_BSC` |
| 8 | X Layer | 196 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_XLAYER` |
| 9 | Monad | 143 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_MONAD` |
| 10 | MegaETH | 4326 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_MEGA` |
| 11 | Plasma | 9745 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_PLASMA` |
| 12 | HyperEVM | 999 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_HYPEREVM` |
| 13 | Tempo | 4217 | `0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd` | `0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462` | `RPC_TEMPO` |

### Commands per chain

For each chain, run 2 commands (Groth16 then Plonk). Replace `$RPC_<CHAIN>` with the RPC URL from `.env`.

**Template:**
```bash
# addRoute on Groth16 gateway
cast send <GROTH16_GATEWAY> "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_<CHAIN>

# addRoute on Plonk gateway
cast send <PLONK_GATEWAY> "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_<CHAIN>
```

### Copy-paste commands

```bash
source .env

# --- Testnets (do these first) ---

# 1. Sepolia
cast send 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_SEPOLIA
cast send 0x3B6041173B80E77f038f3F2C0f9744f04837185e "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_SEPOLIA

# 2. Arbitrum Sepolia
cast send 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_ARBITRUM_SEPOLIA
cast send 0x3B6041173B80E77f038f3F2C0f9744f04837185e "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_ARBITRUM_SEPOLIA

# 3. Base Sepolia
cast send 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_BASE_SEPOLIA
cast send 0x3B6041173B80E77f038f3F2C0f9744f04837185e "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_BASE_SEPOLIA

# 4. OP Sepolia
cast send 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_OPTIMISM_SEPOLIA
cast send 0x3B6041173B80E77f038f3F2C0f9744f04837185e "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_OPTIMISM_SEPOLIA

# 5. Scroll Sepolia
cast send 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_SCROLL_SEPOLIA
cast send 0x3B6041173B80E77f038f3F2C0f9744f04837185e "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_SCROLL_SEPOLIA

# --- Other EOA chains ---

# 6. Hoodi
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_HOODI
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_HOODI

# 7. BSC
cast send 0x940467b232cAD6A44FF36F2FBBe98CBd6509EFf2 "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_BSC
cast send 0xfff6601146031815a84890aCBf0d926609a40249 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_BSC

# 8. X Layer
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_XLAYER
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_XLAYER

# 9. Monad
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_MONAD
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_MONAD

# 10. MegaETH
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_MEGA
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_MEGA

# 11. Plasma
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_PLASMA
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_PLASMA

# 12. HyperEVM
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_HYPEREVM
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_HYPEREVM

# 13. Tempo
cast send 0x7DA83eC4af493081500Ecd36d1a72c23F8fc2abd "addRoute(address)" 0x99A74A05a0FaBEB217C1A329b0dac59a1FA52508 --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_TEMPO
cast send 0x2a5A70409Ee9F057503a50E0F4614A6d8CcBb462 "addRoute(address)" 0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url $RPC_TEMPO
```

---

## Post-flight Check

Run this after completing all routes to confirm all 36 are REGISTERED:

```bash
cd contracts
./check-routes.sh
```

Expected output: **36/36 REGISTERED**.

---

## Troubleshooting

### `RouteAlreadyExists`

The verifier is already registered on that gateway. This is safe — it means the route was already added (possibly from a previous attempt). Skip that chain and verify with:
```bash
cast call <GATEWAY> "routes(bytes4)(address,bool)" <SELECTOR> --rpc-url <RPC>
```

### `OwnableUnauthorizedAccount`

You're sending from the wrong address. The gateway's `owner()` must match your signer:
- Multisig chains (5 mainnets): must come from Safe `0xCafEf00d...`
- Ledger chains (13 others): must come from EOA `0xBaB2c2aF...`

Check the gateway owner:
```bash
cast call <GATEWAY> "owner()(address)" --rpc-url <RPC>
```

### Gas issues on non-standard chains

`addRoute` is a lightweight state change (~50k gas). Unlike the deployment phase, gas issues from MegaETH, Tempo, or Plasma should NOT apply here. If a transaction fails with gas-related errors:

```bash
# Estimate gas first
cast estimate <GATEWAY> "addRoute(address)" <VERIFIER> --rpc-url <RPC>

# If needed, set gas explicitly
cast send <GATEWAY> "addRoute(address)" <VERIFIER> --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --rpc-url <RPC> --gas-limit 100000
```

### RPC timeout / connection errors

Some RPCs (especially Tempo, MegaETH) can be flaky. Retry after a few seconds. If persistent, check if the RPC URL in `.env` is still valid.

### Wrong Ledger derivation path

If `cast send --ledger` signs from a different address than `0xBaB2c2aF...`, specify the derivation path:
```bash
cast send <GATEWAY> "addRoute(address)" <VERIFIER> --from 0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126 --ledger --mnemonic-derivation-path "m/44'/60'/0'/0/0" --rpc-url <RPC>
```
