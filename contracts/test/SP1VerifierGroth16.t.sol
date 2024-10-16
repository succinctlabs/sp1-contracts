// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v3.0.0-rc4/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00467584e2e560847e9e96b5102c082f5e07155429c6622988799df9d95dbb47);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"feb5e54e08d5ce8b93a002fbfc89f29003bf4a94d504e30674682a1bc9699ec0097e76e82b2c88a3841c9e498946abad576a3441e1e59251099a2f958b14a07881389899094b5a48ffc34608c4719fba1367b05985c668e1d960816c72dfaef70a33ea2a261408394e1191d4c5cd0dfd502111ab6232426e439c9c0847c83886085817620388bd7b4345b7eb65de1310470a907e11b9af950891b3494444cd88c8dd48361b54d46e02b57af4892b164535bdda23db428e1f0d18d90437cbf56e705e65a42fb8ed7ba78005546f8019f706cc586ee42e5781fe544975390d38deb61b99ef1309f10884fed2a0c4613410f58ae3597df856534c6814bc1d5f247edd034e1f";
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
