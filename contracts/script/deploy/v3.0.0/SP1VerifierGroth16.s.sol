// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "../../utils/Base.s.sol";
import {SP1Verifier} from "../../../src/v3.0.0/SP1VerifierGroth16.sol";
import {SP1VerifierGateway} from "../../../src/SP1VerifierGateway.sol";
import {ISP1VerifierWithHash} from "../../../src/ISP1Verifier.sol";

contract SP1VerifierScript is BaseScript {
    string internal constant KEY = "V3_0_0_SP1_VERIFIER_GROTH16";

    function run() external multichain(KEY) broadcaster {
        // Deploy contract with salt from config
        address verifier = address(new SP1Verifier{salt: readBytes32("CREATE2_SALT")}());

        // Add the verifier to the gateway
        SP1VerifierGateway(readAddress("SP1_VERIFIER_GATEWAY")).addRoute(verifier);

        // Write the verifier address
        writeAddress(KEY, verifier);
    }

    function freeze() external multichain(KEY) broadcaster {
        // Get addresses from config
        SP1VerifierGateway gateway = SP1VerifierGateway(readAddress("SP1_VERIFIER_GATEWAY"));
        bytes4 selector = ISP1VerifierWithHash(readAddress(KEY)).VERIFIER_HASH();

        // Freeze the verifier route on the gateway
        gateway.freezeRoute(selector);
    }
}

