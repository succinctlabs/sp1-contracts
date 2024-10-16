use anyhow::Result;
use sp1_sdk::install::try_install_circuit_artifacts;
use sp1_sdk::utils::setup_logger;
use sp1_sdk::SP1_CIRCUIT_VERSION;
use std::fs::{create_dir_all, read, read_dir, write};
use std::path::PathBuf;

fn main() -> Result<()> {
    dotenv::dotenv().ok();

    setup_logger();

    let artifact_types = ["plonk", "groth16"];
    let mut artifact_dirs = Vec::new();

    for &artifact_type in &artifact_types {
        let artifacts_dir = try_install_circuit_artifacts(artifact_type);
        artifact_dirs.push(artifacts_dir);
    }

    // Read all Solidity files from the artifacts directories.
    let contracts_src_dir = PathBuf::from(format!("contracts/src/{}", SP1_CIRCUIT_VERSION));
    create_dir_all(&contracts_src_dir)?;

    for artifacts_dir in artifact_dirs {
        let sol_files = read_dir(artifacts_dir)?
            .filter_map(|entry| entry.ok())
            .filter(|entry| entry.path().extension().and_then(|ext| ext.to_str()) == Some("sol"))
            .collect::<Vec<_>>();

        // Write each Solidity file to the contracts directory.
        for sol_file in sol_files {
            let sol_file_path = sol_file.path();
            let sol_file_contents = read(&sol_file_path)?;
            write(
                contracts_src_dir.join(sol_file_path.file_name().unwrap()),
                sol_file_contents,
            )?;
        }
    }

    println!(
        "Added the new verifier contracts to {}",
        contracts_src_dir.display()
    );

    Ok(())
}
