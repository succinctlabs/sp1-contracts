// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "../utils/Base.s.sol";
import {SP1VerifierGateway} from "../../src/SP1VerifierGateway.sol";
import {ISP1VerifierGateway, VerifierRoute} from "../../src/ISP1VerifierGateway.sol";
contract SP1VerifierGatewayScript is BaseScript {
    string internal constant KEY = "SP1_VERIFIER_GATEWAY_GROTH16";

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
        SP1VerifierGateway gateway = SP1VerifierGateway(0x397A5f7f3dBd538f23DE225B51f532c34448dA9B);
        gateway.transferOwnership(0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126);
    }

    function freezeRoute() external multichain(KEY) broadcaster {
        // Swap owner
        SP1VerifierGateway gateway = SP1VerifierGateway(0x397A5f7f3dBd538f23DE225B51f532c34448dA9B);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(0x09069090); // Groth16 V3

        for (uint i = 0; i < selectors.length; i++) {
            (address verifier, bool frozen) = gateway.routes(selectors[i]);
            if (!frozen && verifier != address(0)) {
                gateway.freezeRoute(selectors[i]);
            }
        }
    }
}
