// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SP1VerifierGateway} from "../src/SP1VerifierGateway.sol";

contract SP1VerifierTest is Test {
    SP1VerifierGateway public verifier;

    function setUp() public {
        verifier = new SP1VerifierGateway();
    }
}
