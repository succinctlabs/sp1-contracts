// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISP1Verifier, ISP1VerifierWithHash} from "./ISP1Verifier.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title SP1 Verifier Gateway
/// @author Succinct Labs
/// @notice This contract acts as a router that can be used to ensure that an SP1 proof is verified
/// by the correct verifier. This is possible because an SP1 proof has it's first 4 bytes equal to
/// first 4 bytes of VERIFIER_HASH of the verifier.
contract SP1VerifierGateway is ISP1Verifier, Ownable {
    /// @dev An address that indicates that a verifier was removed from the verifiers mapping.
    address internal constant REMOVED_VERIFIER = address(1);

    /// @notice Mapping of the verifier selector to the address of the verifier contract.
    mapping(bytes4 => address) public verifiers;

    /// @notice Emitted when a verifier is updated.
    /// @param selector The verifier selector that was updated.
    /// @param verifier The address of the new verifier contract.
    event VerifierUpdated(bytes4 selector, address verifier);

    /// @notice Thrown when a proof has a verifier selector that does not correspond to a verifier.
    /// @param selector The verifier selector that was retrieved from the proof.
    error VerifierNotFound(bytes4 selector);
    /// @notice Thrown when a proof has a verifier selector that corresponds to a removed verifier.
    /// @param selector The verifier selector that was removed.
    error VerifierRemoved(bytes4 selector);
    /// @notice Thrown when updating a verifier and the selector does not match the first 4 bytes
    /// of the verifier's VERIFIER_HASH.
    /// @param selector The verifier selector that was given
    error VerifierSelectorMismatch(bytes4 selector);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Get the verifier selector from the proof bytes.
    /// @param proofBytes The proof of the program execution the SP1 zkVM encoded as bytes.
    /// @return selector The verifier selector (first 4 bytes of the VERIFIER_HASH).
    function getVerifierSelector(bytes calldata proofBytes) public pure returns (bytes4) {
        return bytes4(proofBytes[:4]);
    }

    /// @inheritdoc ISP1Verifier
    function verifyProof(
        bytes32 programVkey,
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external view {
        bytes4 selector = getVerifierSelector(proofBytes);
        address verifier = verifiers[selector];
        if (verifier == address(0)) {
            revert VerifierNotFound(selector);
        } else if (verifier == REMOVED_VERIFIER) {
            revert VerifierRemoved(selector);
        }

        ISP1VerifierWithHash(verifier).verifyProof(programVkey, publicValues, proofBytes);
    }

    /// @notice Updates the verifier mapping.
    /// @param selector The verifier selector (first 4 bytes of the VERIFIER_HASH).
    /// @param verifierAddress The address of the verifier contract to use. If the address is 0,
    /// the verifier is removed.
    function updateVerifier(bytes4 selector, address verifierAddress) external onlyOwner {
        if (verifierAddress == address(0)) {
            if (verifiers[selector] != address(0)) {
                verifiers[selector] = REMOVED_VERIFIER;
            } else {
                revert VerifierNotFound(selector);
            }
        } else {
            if (selector == bytes4(ISP1VerifierWithHash(verifierAddress).VERIFIER_HASH())) {
                verifiers[selector] = verifierAddress;
            } else {
                revert VerifierSelectorMismatch(selector);
            }
        }

        emit VerifierUpdated(selector, verifierAddress);
    }
}
