// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../utils/Base.s.sol";
import {SP1VerifierGateway} from "../../src/SP1VerifierGateway.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SP1VerifierGatewayScript is BaseScript {
    function run() external multichain broadcaster {
        console.log("Deploying SP1_VERIFIER_GATEWAY on chain %s", Strings.toString(block.chainid));

        // Read env variables
        bytes32 CREATE2_SALT = envBytes32("CREATE2_SALT");
        address OWNER = envAddress("OWNER", block.chainid);

        // Deploy contract
        address gateway = address(new SP1VerifierGateway{salt: CREATE2_SALT}(OWNER));

        // Write address
        writeEnvAddress(DEPLOYMENT_FILE, "SP1_VERIFIER_GATEWAY", gateway);
    }
}
