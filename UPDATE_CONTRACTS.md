# Add a new SP1 Version to `sp1-contracts`

This section outlines the steps required to update the SP1 contracts repository with a new SP1 version. Follow these instructions to ensure the SP1 contracts are correctly updated and aligned with the latest version.

## Add SP1 Verifier Contracts

Let's add the verifier contracts for a new `sp1-sdk` tag.

1. Change the version tag in `Cargo.toml` to the target `sp1` version.

```toml
[dependencies]
sp1-sdk = "<SP1_TAG>"
```

2. Update `contracts/src` with the new verifier contracts.

```bash
cargo update

cargo run --bin artifacts --release

...

[sp1] plonk circuit artifacts for version v3.0.0-rc4 do not exist at /Users/ratankaliani/.sp1/circuits/plonk/v3.0.0-rc4. downloading...
⠦ [00:00:08] [#######>---------------------] 272.01 MiB/1.07 GiB (29.22 MiB/s, 28s)
```

This will download the circuit artifacts for the SP1 version, and write the verifier contracts to `/contracts/src/{SP1_CIRCUIT_VERSION}`.

## Create a new release

For users to use the contracts associated with a specific `sp1-sdk` tag, we need to create a new release.

1. Open a PR to add the changes to `main`.
2. After merging to `main`, create a release tag with the same version as the `sp1` tag used (e.g `2.0.0`). For release candidates (e.g. `v3.0.0-rc4`), the release tag should be a **pre-release** tag.
3. Now users will be able to install contracts for this version with `forge install succinctlabs/sp1-contracts@VERSION`. By default, `forge install` will install the latest release.

## Appendix

The SP1 Solidity contract artifacts are included in each release of `sp1`. You can see how these are included in the `sp1` repository [here](https://github.com/succinctlabs/sp1/blob/21455d318ae383b317c92e10709bbfc313d8f1df/recursion/gnark-ffi/src/plonk_bn254.rs#L57-L96).
