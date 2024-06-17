// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SP1VerifierGateway} from "../src/SP1VerifierGateway.sol";
import {ISP1VerifierWithHash} from "../src/ISP1Verifier.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SP1VerifierV1 is ISP1VerifierWithHash {
    function VERSION() external pure returns (string memory) {
        return "1";
    }

    function VERIFIER_HASH() public pure returns (bytes32) {
        return 0x19ff1d210e06a53ee50e5bad25fa509a6b00ed395695f7d9b82b68155d9e1065;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(bytes4(proofBytes[:4]) == bytes4(VERIFIER_HASH()));
    }
}

contract SP1VerifierV2 is ISP1VerifierWithHash {
    function VERSION() external pure returns (string memory) {
        return "2";
    }

    function VERIFIER_HASH() public pure returns (bytes32) {
        return 0xfd4b4d23a917e7d7d75deec81f86b55b1c86689a5e3a3c8ae054741af2a7fea8;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata proofBytes) external pure {
        assert(bytes4(proofBytes[:4]) == bytes4(VERIFIER_HASH()));
    }
}

contract SP1VerifierGatewayTest is Test {
    address internal constant REMOVED_VERIFIER = address(1);
    bytes32 internal constant PROGRAM_VKEY = bytes32(uint256(1));
    bytes internal constant PUBLIC_VALUES = hex"";
    bytes internal constant PROOF_1 = hex"19ff1d21";
    bytes internal constant PROOF_2 = hex"fd4b4d23";

    address internal verifier1;
    address internal verifier2;
    address internal owner;
    address internal gateway;

    event VerifierUpdated(bytes4 selector, address verifier);

    function setUp() public virtual {
        verifier1 = address(new SP1VerifierV1());
        verifier2 = address(new SP1VerifierV2());
        owner = makeAddr("owner");
        gateway = address(new SP1VerifierGateway(owner));
    }

    function test_SetUp() public view {
        assertEq(SP1VerifierGateway(gateway).owner(), owner);
        assertEq(
            SP1VerifierGateway(gateway).verifiers(bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH())),
            address(0)
        );
        assertEq(
            SP1VerifierGateway(gateway).verifiers(bytes4(SP1VerifierV2(verifier2).VERIFIER_HASH())),
            address(0)
        );
    }

    function test_UpdateVerifier() public {
        // Add verifier 1
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit VerifierUpdated(verifier1Selector, verifier1);
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, verifier1);

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), verifier1);
    }

    function test_RemoveVerifier() public {
        /// Add verifier 1
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH());
        // vm.expectEmit(true, true, true, true);
        // emit VerifierUpdated(verifier1Selector, verifier1);
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, verifier1);

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), verifier1);

        /// Remove verifier 1
        vm.expectEmit(true, true, true, true);
        emit VerifierUpdated(verifier1Selector, address(0));
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, address(0));

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), REMOVED_VERIFIER);
    }

    function test_RevertUpdateVerifier_WhenNotOwner() public {
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner)
        );
        vm.prank(notOwner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, verifier1);
    }

    function test_VerifyProof() public {
        // Add verifier 1
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit VerifierUpdated(verifier1Selector, verifier1);
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, verifier1);

        // Add verifier 2
        bytes4 verifier2Selector = bytes4(SP1VerifierV2(verifier2).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit VerifierUpdated(verifier2Selector, verifier2);
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier2Selector, verifier2);

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), verifier1);
        assertEq(SP1VerifierGateway(gateway).verifiers(verifier2Selector), verifier2);

        // Send a proof using verifier 1
        SP1VerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);

        // Send a proof using verifier 2
        SP1VerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_2);
    }

    function test_RevertVerifyProof_WhenRemovedVerifier() public {
        // Add verifier 1
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH());
        vm.expectEmit(true, true, true, true);
        emit VerifierUpdated(verifier1Selector, verifier1);
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, verifier1);

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), verifier1);

        // Send a proof using verifier 1
        SP1VerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);

        // Remove verifier 1
        vm.expectEmit(true, true, true, true);
        emit VerifierUpdated(verifier1Selector, address(0));
        vm.prank(owner);
        SP1VerifierGateway(gateway).updateVerifier(verifier1Selector, address(0));

        assertEq(SP1VerifierGateway(gateway).verifiers(verifier1Selector), REMOVED_VERIFIER);

        // Send a proof using verifier 1
        vm.expectRevert(
            abi.encodeWithSelector(SP1VerifierGateway.VerifierRemoved.selector, verifier1Selector)
        );
        SP1VerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);
    }

    function test_RevertVerifyProof_WhenNotFoundVerifier() public {
        // Send a proof to verifier 1 which was never added
        bytes4 verifier1Selector = bytes4(SP1VerifierV1(verifier1).VERIFIER_HASH());
        vm.expectRevert(
            abi.encodeWithSelector(SP1VerifierGateway.VerifierNotFound.selector, verifier1Selector)
        );
        SP1VerifierGateway(gateway).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_1);
    }
}
