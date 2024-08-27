// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v1.2.0-rc/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00cb87a72d222d61929c4d5e0dbfeb9e9902b3b88a1e19d3da3940ace511aff9);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"1b5a112d1e86fe060a33eb57cd5925bd7dc008d32908cdc747fa33650a996d292d4e91480df73809cca54a7f5c8f8310c6ff419e800453d7288cfea549a6ed0987567a850abe1d019dfdde1f3658d87fd640354e3fff4cef60b66ad53c3538dd49d36ee420ff7622c53f7b4656c9e9124aa88edda5cea853cd1399d3ef1d21f349b8ec7017f35a9bd592640a4161c230f5f75ace054d1bdb9b07c2acf919b6f6e7e760f419915199fda1750fecbd8f22d4cd019c55032eed40e4891913b91e819271eb0a0188af084c476cd8bb1911c7b7afaa43d1b2163f0900ad6ba296f639fa2c08860a4c9ee6ece0d6a32f8048a27071f638788f126181d28bfe2eec83f6a856d3eb";
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
