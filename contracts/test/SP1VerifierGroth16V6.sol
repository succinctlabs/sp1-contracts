// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v6.0.0/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16V6Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x004a55ed3c7a07d0233a027278a8b7ff8681ffbd5d1ec4795c18966f6e693090);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_BYTES =
        hex"0e78f4db0000000000000000000000000000000000000000000000000000000000000000008cd56e10c2fe24795cff1e1d1f40d3a324528d315674da45d26afb376e867000000000000000000000000000000000000000000000000000000000000000001e2e0ff3f06238b1a0f13c92e9e6dc64bd103006ab92764445220fecc884ac6f2c7c5c82d3914e85262103f1e262b35d8d3c1e513672ef8482861f21241a8618031f773e85f625d0d3dd3f24b5dcc8489de1b12f38921c7fe55bc2b6d9abc6e716ed0979ff2668a4d50b2f2af2d0513a008e21823a93a19ce53287206191b5e71206f6bd7829711609fa90159683133d43d5e7ca12fb42d99bfd84d0961c02282dea228329dc9f774d214eb74f5c583e63035a9e6b7aae3b5c1f9e6b8929deca2d494130d03ce620238c428eb75c605aff699b779d51b21e93065ffda48c7e5b0c188f0e786e474cbf2263fb9fe2b9260fb4b08332b7ab331fc3f4f9b247a393";

    address internal verifier;

    /// @notice Should succeed when the proof is valid.
    function setUp() public virtual {
        verifier = address(new SP1Verifier());
    }

    /// @notice Test proof verification with v6 verifier.
    /// @dev The v6 verifier has a slightly updated format for the proof nonce and the proof size.
    function test_VerifyProof_V6() public view {
        SP1Verifier(verifier).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_BYTES);
    }
}
