// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SP1VerifierGateway} from "../src/SP1VerifierGateway.sol";
import {SP1MockVerifier} from "../src/SP1MockVerifier.sol";

contract SP1VerifierGatewayTest is Test {
    address internal verifier1;
    address internal verifier2;
    address internal owner;
    address internal verifierGateway;

    function setUp() public {
        verifier1 = address(new SP1MockVerifier());
        verifier2 = address(new SP1MockVerifier());
        owner = makeAddr("owner");

        verifierGateway = address(new SP1VerifierGateway(owner));
    }
}
