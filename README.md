# SP1 Contracts

To update the SP1 contracts repository to include a new release for SP1, set the corresponding version tag in the `Cargo.toml` file:

```toml
[dependencies]
sp1-sdk = { git = "https://github.com/succinctlabs/sp1", tag = "v1.0.2-testnet" }
```

Then, run the following to update the artifacts:

```bash
cargo update

cargo run --bin artifacts
```

After doing so, commit the changes and create a new `sp1-contracts` tag matching the SP1 tag for the new artifacts. Ensure the version in `SP1MockVerifier` and `SP1Verifier` match the new tag.