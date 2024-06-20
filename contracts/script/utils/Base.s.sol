// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/// @notice Script to inherit from to get access to helper functions
abstract contract BaseScript is Script {
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

    function deployments() public view returns (string memory) {
        return vm.readFile(string.concat("./deployments/", vm.toString(block.chainid), ".json"));
    }

    function readAddress(string memory name) internal view returns (address) {
        return vm.parseJsonAddress(deployments(), name);
    }

    function readBytes32(string memory name) internal view returns (bytes32) {
        return vm.parseJsonBytes32(deployments(), name);
    }

    // function writeAddress(string memory name) internal view returns (address) {
    //     return vm.writeJson(deployments(), name, vm.envAddress(name));
    // }

    function writeAddress(string memory name, address value) internal {
        string memory directory = string.concat(vm.projectRoot(), deployments());
        if (!vm.exists(directory)) {
            vm.createDir(directory, true);
        }

        string memory file =
            string.concat(vm.projectRoot(), deployments(), vm.toString(block.chainid), ".json");
        bool exists = vm.exists(file);
        if (!exists) {
            vm.writeFile(file, "{}");
        }

        string memory json = vm.readFile(file);
        if (vm.keyExists(json, string.concat(".", name))) {
            vm.writeJson(Strings.toHexString(value), file, string.concat(".", name));
        } else {
            string memory root = "root";
            vm.serializeJson(root, json);
            vm.writeJson(vm.serializeAddress(root, name, value), file);
        }
    }

    function writeEnvAddress(string memory file, string memory name, address value) internal {
        string memory addrVar = string.concat(name, "_", vm.toString(block.chainid));
        vm.setEnv(addrVar, Strings.toHexString(value));
        vm.writeLine(file, string.concat(string.concat(addrVar, "="), Strings.toHexString(value)));
        console.log(string.concat(string.concat(addrVar, "="), Strings.toHexString(value)));
    }
}
