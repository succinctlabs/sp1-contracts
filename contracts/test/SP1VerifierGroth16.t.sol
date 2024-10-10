// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v3.0.0-rc3/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x0031d9b929d13038eb7c25790617a5ff09d3e3f6d20fc3f0bb70ada6c20206cd);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"91ff06f3018012469797b672088e11fce5cf3b24608cbdf85609cd5f514d72683583ac531f17401a7e6dc84bc674dc9fbbf30f4ec6208ab587267e46269b728ffcb5ac4d2c3951eaf5b3c082750ac6ca369772a0907fd5dc02b01f6ff23cd4396f8f510c1a453dd45f069c48b6b4e597cf169237a08594f914ee2c188f1b89c2444029f51890876a3e64d57483554d818c0b55c8ceeb08983d5ba682a7854a2dfd6403b824a130c4a04118265db2925450ce879e15473d91280ab46f5d5779ac22eff16b044faba38a646c92d4ab8454bf0142bb8cffdd56a6c922aff15d55a8f0ce70860b883b929f6ca1afe2f0c774862093adf13ea8eefdcd9186d0c7d6d25fbf8a51";
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
