// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice The inputs used to verify a contract call.
struct ContractPublicValues {
    uint256 id;
    bytes32 anchorHash;
    AnchorType anchorType;
    address callerAddress;
    address contractAddress;
    bytes contractCalldata;
    bytes contractOutput;
}

/// @notice The type of the anchor.
enum AnchorType {
    BlockHash,
    BeaconRoot
}

/// @notice The anchor is too old and can no longer be validated.
error ExpiredAnchor();

/// @notice The anchor doesn't match the witness.
error AnchorMismatch();

/// @notice The anchor type is not supported.
error AnchorTypeNotSupported(AnchorType);

/// @title SP1 ContractCall
/// @author Succinct Labs
/// @notice This library is an helper to verify contract calls.
library ContractCall {
    address internal constant BEACON_ROOTS_ADDRESS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;

    /// @notice Verify contract call public values.
    function verify(ContractPublicValues memory publicValues) internal view {
        if (publicValues.anchorType == AnchorType.BlockHash) {
            return verifyBlockAnchor(publicValues.id, publicValues.anchorHash);
        }
        if (publicValues.anchorType == AnchorType.BeaconRoot) {
            return verifyBeaconAnchor(publicValues.id, publicValues.anchorHash);
        }

        revert AnchorTypeNotSupported(publicValues.anchorType);
    }

    /// @notice Verify if the provided block hash matches the one of the given block number.
    function verifyBlockAnchor(uint256 blockNumber, bytes32 blockHash) internal view {
        if (block.number - blockNumber > 256) {
            revert ExpiredAnchor();
        }

        if (blockHash != blockhash(blockNumber)) {
            revert AnchorMismatch();
        }
    }

    /// @notice Verify if the provided block root matches the one of the given timestamp.
    function verifyBeaconAnchor(uint256 timestamp, bytes32 blockRoot) internal view {
        if (block.timestamp - timestamp > 12 * 8191) {
            revert ExpiredAnchor();
        }

        (bool success, bytes memory result) = BEACON_ROOTS_ADDRESS.staticcall(abi.encode(timestamp));
        if (success) {
            if (blockRoot != abi.decode(result, (bytes32))) {
                revert AnchorMismatch();
            }
        } else {
            revert AnchorMismatch();
        }
    }
}
