// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";

/// @notice Script to inherit from to get access to helper functions
abstract contract BaseScript is Script {
    using stdJson for string;

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
            string memory rpc = vm.envString(string.concat("RPC_", vm.toString(chainId)));
            vm.createSelectFork(rpc);

            // or try vm.createSelectFork(vm.rpcUrl(chainName));
            // https://github.com/ourzora/zora-protocol/blob/87fd4a0f06cbabe9bb081eb01babc7222bd1db91/packages/frames/script/MultichainScript.sol#L35

            _;
        }
    }

    function directory() internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deployments/");
    }

    function file() internal view returns (string memory) {
        return string.concat(vm.toString(block.chainid), ".json");
    }

    function path() internal view returns (string memory) {
        return string.concat(directory(), file());
    }

    function deployments() internal view returns (string memory) {
        return vm.readFile(path());
    }

    function ensureExists() internal {
        if (!vm.exists(directory())) {
            vm.createDir(directory(), true);
        }

        if (!vm.exists(path())) {
            vm.writeFile(path(), "{}");
        }
    }

    function readAddress(string memory key) internal view returns (address) {
        return deployments().readAddress(string.concat(".", key));
    }

    function readBytes32(string memory key) internal view returns (bytes32) {
        return deployments().readBytes32(string.concat(".", key));
    }

    function writeAddress(string memory key, address value) internal {
        ensureExists();

        if (vm.keyExists(deployments(), string.concat(".", key))) {
            vm.writeJson(vm.toString(value), path(), string.concat(".", key));
        } else {
            string memory root = "root";
            vm.serializeJson(root, deployments());
            vm.writeJson(vm.serializeAddress(root, key, value), path());
        }
    }

    function writeBytes32(string memory key, bytes32 value) internal {
        ensureExists();

        if (vm.keyExists(deployments(), string.concat(".", key))) {
            vm.writeJson(vm.toString(value), path(), string.concat(".", key));
        } else {
            string memory root = "root";
            vm.serializeJson(root, deployments());
            vm.writeJson(vm.serializeBytes32(root, key, value), path());
        }
    }
}
