// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v4.0.0-rc.3/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00562c19b1948ce8f360ee32da6b8e18b504b7d197d522085d3e74c072e0ff7d);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"11b6a09d15c0a8f6b56f8226262eccb0d78ab7946001762a2a9117b0ce6626ee0f15338a164391b8e4af70b9ad5f80df72a2fd42038afc66190edd82bf1f0d752ce22ab208f5de7a1c73d97f82e989add997eca2e95af1716a5d9c03cbcec2bb477aa06d00b7de11d8465f44fc1073d49a2809a57d31ad543a3602be355ea05aedf894aa0839ad0113478bf84a25faff25306a84185c20d1320772e4769d993832626f081e432d60d8f4cb6f82f8835872aa0c3183ffe09f67d365951722c1a3debd6ae90c31023395fe16b29c3a01524447de9e22aa670c6a7cd880281ba14c642a601b0530706caf4af3644ff20a785ac0e499321f08cfc96cee48b64bfa08925ec27c";
    bytes internal constant PROOF_INVALID =
        hex"1b5a112d1e86fe060a33eb57cd5925bd7dc008d32908cdc747fa33650a996d292d4e";

    address internal verifier;

    function setUp() public virtual {
        verifier = address(new SP1Verifier());
    }

    /// @notice Should succeed when the proof is valid.
    function test_VerifyProof_WhenGroth16() public view {
        SP1Verifier(verifier).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_VALID);
    }

    /// @notice Should revert when the proof is invalid.
    function test_RevertVerifyProof_WhenGroth16() public view {
        SP1Verifier(verifier).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_VALID);
    }
}
