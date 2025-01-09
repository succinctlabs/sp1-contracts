// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "../utils/Base.s.sol";
import {SP1VerifierGateway} from "../../src/SP1VerifierGateway.sol";

contract SP1VerifierGatewayScript is BaseScript {
    string internal constant KEY = "SP1_VERIFIER_GATEWAY_PLONK";

    function run() external multichain(KEY) broadcaster {
        // Read config
        bytes32 CREATE2_SALT = readBytes32("CREATE2_SALT");
        address OWNER = readAddress("OWNER");

        // Deploy contract
        address gateway = address(new SP1VerifierGateway{salt: CREATE2_SALT}(OWNER));

        // Write address
        writeAddress(KEY, gateway);
    }

    function swapOwner() external multichain(KEY) broadcaster {
        // Swap owner
        SP1VerifierGateway gateway = SP1VerifierGateway(0x3B6041173B80E77f038f3F2C0f9744f04837185e);
        gateway.transferOwnership(0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126);
    }
}
