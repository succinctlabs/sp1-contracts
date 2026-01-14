// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SP1Verifier} from "../src/v6.0.0-beta.1/SP1VerifierGroth16.sol";

contract SP1VerifierGroth16V6Test is Test {
    bytes32 internal constant PROGRAM_VKEY =
        bytes32(0x00502858e1222437b63f4b710c8fd5e45a3c3797e02a84d9b70d97c9d22286e7);
    bytes internal constant PUBLIC_VALUES =
        hex"00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000001a6d0000000000000000000000000000000000000000000000000000000000002ac2";
    bytes internal constant PROOF_BYTES =
        hex"58b7a3c3000000000000000000000000000000000000000000000000000000000000000000410a5637e8b7b8c4b895991b4892efd0ff4da2b5e277d701f2f5c1f23d0c7b000000000000000000000000000000000000000000000000000000000000000014e9a2527f46b171765ec899347fd37659986fe967bd1ae30c55643ca0cf62a3268461232fdb5b7d1ba5a69868e8b598abda6cf53985ba1e7b8fe0a5df151a37045a81cf89115ae3978dfadce9149a4eebc7edbb8a2dadb70134d8a3f9c247cf20fbd89c5ad9bdef194dbfc5d9d8354fad6c86124079b23a768a468e588b1b1823958e6f802c959a489c019ebbad85a10a712e94c3f50e006aa80789fc7ef4ac14b7db52fdde1238e89c74daa5c22b79b39104b6534b419e0623d5db813d139a24a66dd5a80ac8bcf1a28fd1d444cf84efa1644369d1d84c7855456daab9b23d07d07fc6f32cbe73af675b20351ba2e723be019bf596636b40176e4559a3c58f";

    address internal verifier;

    /// @notice Should succeed when the proof is valid.
    function setUp() public virtual {
        verifier = address(new SP1Verifier());
    }

    /// @notice Test proof verification with v6 verifier.
    /// @dev The v6 verifier has a slightly updated format for the proof nonce and the proof size.
    function test_VerifyProof_V6() public view {
        SP1Verifier(verifier).verifyProof(PROGRAM_VKEY, PUBLIC_VALUES, PROOF_BYTES);
    }
}
