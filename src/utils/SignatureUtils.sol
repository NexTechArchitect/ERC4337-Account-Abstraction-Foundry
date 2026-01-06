// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title SignatureUtils
 * @notice Utility library for recovering signer from signature
 */
library SignatureUtils {
    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address signer) {
        bytes32 ethSigned = MessageHashUtils.toEthSignedMessageHash(hash);

        signer = ECDSA.recover(ethSigned, signature);
    }
}
