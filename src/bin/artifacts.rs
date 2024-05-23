use anyhow::Result;
use sp1_sdk::artifacts::try_install_groth16_artifacts;

fn main() -> Result<()> {
    let artifacts_dir = try_install_groth16_artifacts();

    // Write SP1Verifier.sol, ISP1Verifier.sol, SP1MockVerifier.sol and Groth16Verifier.sol from artifacts_dir to ../contracts/src.
    let sp1_verifier_sol = std::fs::read(artifacts_dir.join("SP1Verifier.sol"))?;
    let isp1_verifier_sol = std::fs::read(artifacts_dir.join("ISP1Verifier.sol"))?;
    let sp1_mock_verifier_sol = std::fs::read(artifacts_dir.join("SP1MockVerifier.sol"))?;
    let groth16_verifier_sol = std::fs::read(artifacts_dir.join("Groth16Verifier.sol"))?;

    let contracts_src_dir = std::path::Path::new("../contracts/src");
    std::fs::write(contracts_src_dir.join("SP1Verifier.sol"), sp1_verifier_sol)?;
    std::fs::write(
        contracts_src_dir.join("ISP1Verifier.sol"),
        isp1_verifier_sol,
    )?;
    std::fs::write(
        contracts_src_dir.join("SP1MockVerifier.sol"),
        sp1_mock_verifier_sol,
    )?;
    std::fs::write(
        contracts_src_dir.join("Groth16Verifier.sol"),
        groth16_verifier_sol,
    )?;

    Ok(())
}
