// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v3.0.0/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00467584e2e560847e9e96b5102c082f5e07155429c6622988799df9d95dbb47);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"090690900091bc3f08015e1ed96bee4e8c7a3ab074bfaa54129b1c63a9c6e478ec63255d3028cceaeed53e04bf0ee42f58ff0980ff00212e52a2a1d85b69b1268f5030820bc4589b0566e8a3f0738fa64405c10ee7347e58afbf4f1f431b327e5ba522c32f83c0c6e9e5bc37dfe2b31ae2bead89e0c7d8a0df1226b005d75f2e252b104a030d532c73f896df2328ce3322c055bda3b979dda22568ef85761b1d82bdcbec230f2838693d3663a0bd00006fa0f0dd4ea0e14b8b44273b0e8575e5478fa8d92a910cc26e0cdff4869f3fac686f91d245839368dbeadc9daaa4062ad1b3772523b284a3c41d60328f30461e03a465f4d6ec8d0fdfeeba176b8d0c7c82167c18";
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
