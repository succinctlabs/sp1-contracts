// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v3.0.0-rc1/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00db1ca9cf1872ef132764a5aef4069a050266d812fbd95dce4fa860e2279857);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"5a1551d6138ff2379a9dc37c74bd85b5bf2c8aa677cb7655a6a91ac9609562dad8713a9d09ecb18f364d52de4e3946fa2f4ab75f60ffb3afad55de922579c02155c7aec71dc3335c901100e27a7e649236a89872133b0795880aa734ed6c8f4389fa29920da901c946af91c2cd6a44cd6146893d49360abd7e39a3df043212430aeb2fe20b75270abb643988229fa996298829e8dec6f48e75905a0d3a6cc24fa1309876196652e95d1e835255934761c05f89e95086e3fcfd832068a25baecbfb2fe71c2b73057a7f78e1417d61ab52943a1a3f2a0b8efbb4f8262b712797205c95fd6b03e2abc41070a37f6672fb56a0e90a61c893458fa35f693a14072f759d045d44";
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
