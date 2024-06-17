// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISP1Verifier} from "./ISP1Verifier.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title SP1 Verifier Gateway
/// @author Succinct Labs
/// @notice The verifier gateway which maps SP1 proofs to their respective verifiers. This contract
/// acts as a router that can be used to ensure that the appropriate proof is verified by the
/// correct verifier.
contract SP1VerifierGateway is ISP1Verifier, Ownable {
    /// @dev An address that indicates that a verifier was removed from the verifiers mapping.
    address internal constant REMOVED_VERIFIER = address(1);

    /// @notice Mapping of the verifier selector to the address of the verifier contract.
    mapping(bytes4 => address) public verifiers;

    /// @notice Emitted when a verifier is updated.
    /// @param selector The verifier selector that was updated.
    /// @param verifier The address of the new verifier contract.
    event VerifierUpdated(bytes4 selector, address verifier);

    /// @notice Thrown when a proof has a verifier selector that does not correspond to a
    /// verifier.
    /// @param selector The verifier selector that was retrieved from the proof.
    error VerifierNotFound(bytes4 selector);
    /// @notice Thrown when a proof has a verifier selector that corresponds to a removed verifier.
    /// @param selector The verifier selector that was removed.
    error VerifierRemoved(bytes4 selector);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Get the verifier selector from the proof bytes.
    /// @param proofBytes The proof of the program execution the SP1 zkVM encoded as bytes.
    /// @return selector The verifier selector (first 4 bytes of the proof).
    function getVerifierSelector(bytes calldata proofBytes) public pure returns (bytes4) {
        return bytes4(proofBytes[:4]);
    }

    /// @inheritdoc ISP1Verifier
    function verifyProof(bytes32 vkey, bytes calldata publicValues, bytes calldata proofBytes)
        external
        view
    {
        // Get the selector (first 4 bytes) from the proof and dispatch to corresponding verifier.
        // bytes4 selector = bytes4(proofBytes[:4]);
        bytes4 selector = getVerifierSelector(proofBytes);
        address verifier = verifiers[selector];
        if (verifier == address(0)) {
            revert VerifierNotFound(selector);
        } else if (verifier == REMOVED_VERIFIER) {
            revert VerifierRemoved(selector);
        }

        ISP1Verifier(verifier).verifyProof(vkey, publicValues, proofBytes);
    }

    /// @notice Updates the verifier mapping.
    /// @param selector The verifier selector (first 4 bytes of the proof).
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
            verifiers[selector] = verifierAddress;
        }

        emit VerifierUpdated(selector, verifierAddress);
    }
}
