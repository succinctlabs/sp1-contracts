// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/// @notice Script to inherit from to get access to helper functions
abstract contract BaseScript is Script {
    string internal constant DEPLOYMENT_FILE = ".env.deployments";

    /// @notice Run the command with the `--broadcast` flag to send the transaction to the chain,
    /// otherwise just simulate the transaction execution.
    modifier broadcaster() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }

    /// @notice When used, runs the script on the chains specified in the `CHAIN_IDS` env variable.
    /// Must have a `RPC_${CHAIN_ID}` env variable set for each chain.
    modifier multichain() {
        uint256[] memory chainIds = vm.envUint("CHAIN_IDS", ",");
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 chainId = chainIds[i];

            // Switch to the chain using the RPC
            string memory rpc = vm.envString(string.concat("RPC_", Strings.toString(chainId)));
            vm.createSelectFork(rpc);

            _;
        }
    }

    function envUint256(string memory name) internal view returns (uint256) {
        uint256 value = vm.envUint(name);
        if (value == 0) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s=%s", name, value);
        return value;
    }

    function envBool(string memory name) internal view returns (bool) {
        bool value = vm.envBool(name);
        if (!value) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s=%s", name, value);
        return value;
    }

    function envUint32(string memory name) internal view returns (uint32) {
        uint32 value = uint32(vm.envUint(name));
        if (value == 0) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s=%s", name, value);
        return value;
    }

    function envUint32s(string memory name, string memory delimiter)
        internal
        view
        returns (uint32[] memory)
    {
        uint256[] memory values = new uint256[](0);
        values = vm.envOr(name, delimiter, values);
        if (values.length == 0) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s:", name);
        for (uint256 i = 0; i < values.length; i++) {
            console.log("  %s", values[i]);
        }
        uint32[] memory converted = new uint32[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            converted[i] = uint32(values[i]);
        }
        return converted;
    }

    function envUint64(string memory name) internal view returns (uint64) {
        uint64 value = uint64(vm.envUint(name));
        if (value == 0) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s=%s", name, value);
        return value;
    }

    function envBytes32(string memory name) internal view returns (bytes32) {
        bytes32 value = vm.envBytes32(name);
        if (value == bytes32(0)) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s=%s", name, Strings.toHexString(uint256(value)));
        return value;
    }

    function envAddress(string memory name) internal view returns (address) {
        address addr = vm.envAddress(name);
        if (addr == address(0)) {
            console.log("%s is not set", name);
            revert();
        }
        console.log("%s=%s", name, addr);
        return addr;
    }

    function envAddress(string memory name, uint256 chainId) internal view returns (address) {
        string memory envName = string.concat(name, "_", Strings.toString(chainId));
        address addr = vm.envOr(envName, address(0));
        if (addr == address(0)) {
            //try without chainId
            addr = vm.envOr(name, address(0));
            if (addr == address(0)) {
                console.log("%s/%s is not set", envName, name);
                revert();
            }
        }
        console.log("%s=%s", envName, addr);
        return addr;
    }

    function writeEnvAddress(string memory file, string memory name, address value) internal {
        string memory addrVar = string.concat(name, "_", Strings.toString(block.chainid));
        vm.setEnv(addrVar, Strings.toHexString(value));
        vm.writeLine(file, string.concat(string.concat(addrVar, "="), Strings.toHexString(value)));
        console.log(string.concat(string.concat(addrVar, "="), Strings.toHexString(value)));
    }
}
