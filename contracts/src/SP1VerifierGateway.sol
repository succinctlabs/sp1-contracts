// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISP1Verifier} from "./ISP1Verifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SP1 Verifier Gateway
/// @author Succinct Labs
/// @notice Verifier gateway which is owned and can have its verifier mapping updated.
contract SP1VerifierGateway is ISP1Verifier, Ownable {
    error NoVerifierForSelector();
    error VerifierRemoved();

    address constant REMOVED_VERIFIER = address(1);

    mapping(bytes4 => address) public verifiers;

    constructor() Ownable(msg.sender) {}

    /// @notice Updates the verifier mapping.
    /// @param selector The 4-byte selector of the verifier.
    /// @param verifierAddress The address of the verifier contract to use. If the address is 0, the verifier is removed.
    function updateVerifier(bytes4 selector, address verifierAddress) external onlyOwner {
        if (verifierAddress == address(0)) {
            if (verifiers[selector] != address(0)) {
                verifiers[selector] = REMOVED_VERIFIER;
            } else {
                revert NoVerifierForSelector();
            }
        } else {
            verifiers[selector] = verifierAddress;
        }
    }

    /// @inheritdoc ISP1Verifier
    function verifyProof(bytes32 vkey, bytes calldata publicValues, bytes calldata proofBytes) public view {
        // Get the selector (first 4 bytes) of the proof and dispatch to corresponding verifier.
        bytes4 selector = bytes4(proofBytes[:4]);
        address verifier = verifiers[selector];
        if (verifier == address(0)) {
            revert NoVerifierForSelector();
        } else if (verifier == REMOVED_VERIFIER) {
            revert VerifierRemoved();
        }

        ISP1Verifier(verifier).verifyProof(vkey, publicValues, proofBytes);
    }
}
