// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v1.2.0/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00b94374c2266f0d2e01793c47156bc0badd5d4d60899e1b0963a27f09ac9475);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_VALID =
        hex"837629d32fe646eef2ba21ec161306d496e2938a0e3ec7f8990c3b0c74f28a8211852a1c2032cbb2a143b36636e1dafa6b02ae15db4884701ca24fed869efe4b8b4471441471f2f0778a20e563eda1852c7256118a447e35790fd719b9d3722401c537802f38e055b52c3f88abb76d4ac1da35112e7180d0a5c39ac37ce97b8ae38af59e254a8dcdfb728c9c55fa25c44e7ca994c30e1585792ad16494708b66ce54d75a0e6654e0b71270401e77e94615604a270cd73e549cb923bb997134bc1e96985f12f8d42a726a65767d0ae1265d216b703ba12d41a56c1b84b9e94d51ce6df8c42c8682896b84bbe18192ed3c36b3cedf6a0f93381e1d0c7e1e1ee40cd6bc75e9";
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
