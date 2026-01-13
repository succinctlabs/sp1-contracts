// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v6.0.0-beta.1/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16V6Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00502858e1222437b63f4b710c8fd5e45a3c3797e02a84d9b70d97c9d22286e7);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_BYTES =
        hex"1eb7d55f000000000000000000000000000000000000000000000000000000000000000000410a5637e8b7b8c4b895991b4892efd0ff4da2b5e277d701f2f5c1f23d0c7b00000000000000000000000000000000000000000000000000000000000000000cb9a58949dcd08786cd1c307b0cd486d0041abe7408b1fd1a6cf50d1ab987ca2bac88cda1a056b80df2b04c39766682bb12201b45df583a11a4eed0f3fa1a330c94694f3f065ff9027b5abcb8f3d6bd6d99250425f511ab7be30bf1be06342317a35ad6fdba3af3c8313bb5485099d33d2b8ecdb6dbd4df7e9c91580f2ce3cc1a447823705d907888c0affefef087ef96e9adfadc31e9e3381a159aafe131ea2a9dba4d07dba578fa74bbd73a83ce9ee9f6a8c909dd7eab5d4dda7913df4968216e2daf0dd3a041e950b9a61a0289ad1f5371677ea8839b71e1f2adf07206a3191d0c9e59a2b7a52112075b81e659e983b27223621619646aa6ae0b18b9a9ae";

    address internal verifier;

    /// @notice Should succeed when the proof is valid.
    function setUp() public virtual {
        verifier = address(new SP1Verifier());
    }

    // /// @notice Test proof verification with v6 verifier (expected to fail).
    // /// @dev The v6 verifier has a slightly updated format for the proof nonce and the proof size.
    // function test_VerifyProof_V6() public view {
    //     SP1Verifier(verifier).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_BYTES);
    // }
}
