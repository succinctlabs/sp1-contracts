// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "../utils/Base.s.sol";
import {SP1VerifierGateway} from "../../src/SP1VerifierGateway.sol";
import {ISP1VerifierGateway, VerifierRoute} from "../../src/ISP1VerifierGateway.sol";

import {console} from "forge-std/console.sol";

contract SP1VerifierGatewayScript is BaseScript {
    string internal constant KEY = "SP1_VERIFIER_GATEWAY_PLONK";

    function run() external multichain(KEY) broadcaster {
        // Read config
        bytes32 CREATE2_SALT = readBytes32("CREATE2_SALT");
        address OWNER = readAddress("OWNER");

        // Deploy contract
        address gateway = address(
            new SP1VerifierGateway{salt: CREATE2_SALT}(OWNER)
        );

        // Write address
        writeAddress(KEY, gateway);
    }

    function swapOwner() external multichain(KEY) broadcaster {
        // Swap owner
        SP1VerifierGateway gateway = SP1VerifierGateway(
            0x3B6041173B80E77f038f3F2C0f9744f04837185e
        );
        gateway.transferOwnership(0xBaB2c2aF5b91695e65955DA60d63aD1b2aE81126);
    }

    function freezeRoute() external multichain(KEY) broadcaster {
        SP1VerifierGateway gateway = SP1VerifierGateway(
            0x3B6041173B80E77f038f3F2C0f9744f04837185e
        );

        bytes4[] memory selectors = new bytes4[](18);
        selectors[1] = bytes4(0xfedc1fcc); // v1.0.1 PLONK
        selectors[2] = bytes4(0x8c5bc5e4); // 1.0.7-testnet PLONK
        selectors[3] = bytes4(0x801c66ac); // v1.0.8-testnet PLONK
        selectors[4] = bytes4(0xc430ff7f); // 1.1.0 PLONK
        selectors[5] = bytes4(0xc865c1b6); // v1.2.0 PLONK
        selectors[6] = bytes4(0x837629d3); // v1.2.0 Groth16
        selectors[7] = bytes4(0x3c65f6c4); // v2.0.0 PLONK
        selectors[8] = bytes4(0x3c65f6c4); // v2.0.0 PLONK
        selectors[9] = bytes4(0xb49c53a7); // v3.0.0-rc1 PLONK
        selectors[10] = bytes4(0x6548aa67); // v3.0.0-rc3 PLONK
        selectors[11] = bytes4(0x894b4e66); // v3.0.0-rc4 PLONK
        selectors[12] = bytes4(0x54bdcae3); // PLONK V3
        selectors[13] = bytes4(0x4aca240a); // PLONK V2
        selectors[14] = bytes4(0x6a2906ac); // Groth16 V2
        selectors[15] = bytes4(0x3e923f1f); // v3.0.0-rc1 Groth16
        selectors[16] = bytes4(0x2a12d1d0); // v3.0.0-rc4 Groth16
        selectors[17] = bytes4(0x09069090); // v3.0.0 Groth16

        for (uint i = 0; i < selectors.length; i++) {
            (address verifier, bool frozen) = gateway.routes(selectors[i]);
            if (!frozen && verifier != address(0)) {
                console.logBytes4(selectors[i]);
                gateway.freezeRoute(selectors[i]);
            }
        }
    }
}
