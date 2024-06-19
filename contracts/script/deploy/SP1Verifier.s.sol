// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../utils/Base.s.sol";
import {SP1Verifier} from "../../src/v1.0.7-testnet/SP1Verifier.sol";
import {SP1VerifierGateway} from "../../src/SP1VerifierGateway.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SP1VerifierScript is BaseScript {
    function run() external multichain broadcaster {
        console.log("Deploying SP1_VERIFIER on chain %s", Strings.toString(block.chainid));

        // Read env variables
        bytes32 CREATE2_SALT = envBytes32("CREATE2_SALT");
        address SP1_VERIFIER_GATEWAY = envAddress("SP1_VERIFIER_GATEWAY", block.chainid);

        // Deploy contract
        address verifier = address(new SP1Verifier{salt: CREATE2_SALT}());

        // Add the verifier to the gateway
        SP1VerifierGateway gateway = SP1VerifierGateway(SP1_VERIFIER_GATEWAY);
        gateway.addRoute(verifier);

        // Write address
        writeEnvAddress(DEPLOYMENT_FILE, "SP1_VERIFIER", verifier);
    }
}
