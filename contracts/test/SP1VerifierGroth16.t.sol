// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v2.0.0/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00365bdf422d83b7f9de1787cdc48d6ca03fe0451007d77ad1c7466a69ad6926);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"6a2906ac28fcf09c4dc6bcf7e5cdb659d51f55eda76653d88a876a72ab1c66f7796e95f9122c84f9f515b216b5618339f22a03bfd0f6ef9e15068535983e09f9bafeb7fe0e429a9a708d7adf00684380ca1169b96fff0c86ff692da1a4fc5e22759e13ea1cd28bcb9a412d42784eae6d6276fb5aa6f390d8bff36541253cb25af0983442283b78bc9193461e63d35908110278a95fa478bacc8d66c9ac0e1b6a8899456921c5d233f15f76adce53037d375ea09c0760b52e9255510041435cea77df9f92257e5ad5190a878c3780e4cf4f176a5e1a15864f0c6c88cf81bd023341e3d14d247cedc90d8483dc52fbcc3e32577960e467fc0a82f0d430e0e2ef989ada5862";
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
