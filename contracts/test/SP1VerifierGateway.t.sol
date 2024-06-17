// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SP1MockVerifier} from "../src/SP1MockVerifier.sol";
import {SP1VerifierGateway} from "../src/SP1VerifierGateway.sol";
import {ISP1Verifier} from "../src/ISP1Verifier.sol";

contract SP1VerifierV1 is ISP1Verifier {
    function VERSION() external pure returns (string memory) {
        return "1";
    }

    function VKEY_HASH() public pure returns (bytes32) {
        return 0x19ff1d210e06a53ee50e5bad25fa509a6b00ed395695f7d9b82b68155d9e1065;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(bytes4(proofBytes[:4]) == bytes4(VKEY_HASH()));
    }
}

contract SP1VerifierV2 is ISP1Verifier {
    function VERSION() external pure returns (string memory) {
        return "2";
    }

    function VKEY_HASH() public pure returns (bytes32) {
        return 0xfd4b4d23a917e7d7d75deec81f86b55b1c86689a5e3a3c8ae054741af2a7fea8;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(bytes4(proofBytes[:4]) == bytes4(VKEY_HASH()));
    }
}

contract SP1VerifierGatewayTest is Test {
    bytes32 internal constant PROGRAM_VKEY = bytes32(uint256(1));
    bytes internal constant PUBLIC_VALUES = bytes("publicValues");
    bytes internal constant PROOF = bytes("");

    address internal verifier1;
    address internal verifier2;
    address internal owner;
    address internal gateway;

    function setUp() public virtual {
        verifier1 = address(new SP1VerifierV1());
        verifier2 = address(new SP1VerifierV2());
        owner = makeAddr("owner");

        gateway = address(new SP1VerifierGateway(owner));
    }

    function test_SetUp() public view {
        assertEq(SP1VerifierGateway(gateway).owner(), owner);
    }

    function test_UpdateVerifier() public {
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VKEY_HASH());
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, verifier1);

        bytes4 verifier2Selector = bytes4(SP1VerifierV2(verifier2).VKEY_HASH());
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier2Selector, verifier2);

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), verifier1);
        assertEq(SP1VerifierGateway(gateway).verifiers(verifier2Selector), verifier2);

        SP1VerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF);
    }
}
