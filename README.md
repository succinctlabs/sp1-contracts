# SP1 Contracts

To update the SP1 contracts repository to include a new release for SP1, set the corresponding version tag in the `Cargo.toml` file:

```toml
[dependencies]
sp1-sdk = { git = "https://github.com/succinctlabs/sp1", tag = "<TESTNET_TAG>" }
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
    return "<TESTNET_TAG>";
}
```

After doing so, commit the changes and create a new `sp1-contracts` tag matching the SP1 tag for the new artifacts.