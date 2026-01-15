// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title SessionKeyManager
 * @author NEXTECHARHITECT
 * @notice Manages temporary session keys with expiry
 */
abstract contract SessionKeyManager {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    struct SessionKey {
        uint48 validUntil;
    }

    mapping(address => SessionKey) internal sessionKeys;

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _enableSessionKey(address key, uint48 duration) internal {
        sessionKeys[key].validUntil = uint48(block.timestamp + duration);
    }

    function _disableSessionKey(address key) internal {
        delete sessionKeys[key];
    }

    function _isValidSessionKey(address key) internal view returns (bool) {
        uint48 validUntil = sessionKeys[key].validUntil;

        if (validUntil == 0) return false;
        if (block.timestamp > validUntil) return false;

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function isSessionKeyValid(address key) external view returns (bool) {
        uint48 validUntil = sessionKeys[key].validUntil;

        if (validUntil == 0) return false;
        if (block.timestamp > validUntil) return false;

        return true;
    }
}
