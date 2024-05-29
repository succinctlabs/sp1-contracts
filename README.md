# SP1 Contracts

The SP1 contract artifacts are included in each release of `sp1` as Solidity files. You can see how this is done in the `sp1` repository [here](https://github.com/succinctlabs/sp1/blob/21455d318ae383b317c92e10709bbfc313d8f1df/recursion/gnark-ffi/src/plonk_bn254.rs#L57-L96).

To update the SP1 contracts repository with a new `sp1` version, set the corresponding version tag in the `Cargo.toml` file:

```toml
[dependencies]
sp1-sdk = { git = "https://github.com/succinctlabs/sp1", tag = "<SP1_TAG>" }
```

Then, run the following to update the artifacts:

```bash
cargo update

cargo run --bin artifacts
```

This will update `contracts/src` with the new artifacts.

Ensure that you update the `VERSION` in both `SP1MockVerifier` and `SP1Verifier` to match the new tag.

```solidity
function VERSION() external pure returns (string memory) {
    return "<SP1_TAG>";
}
```

After doing so, commit the changes to `main`. Then, create a new `sp1-contracts` tag matching the SP1 tag for the new artifacts.