// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/account/SmartAccount.sol";
import "../src/utils/SignatureUtils.sol";
import {
    PackedUserOperation
} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/*//////////////////////////////////////////////////////////////
                        DUMMY TARGET
//////////////////////////////////////////////////////////////*/
contract DummyTarget {
    event Called();

    function ping() external {
        emit Called();
    }
}

/*//////////////////////////////////////////////////////////////
                        TEST CONTRACT
//////////////////////////////////////////////////////////////*/
contract SmartAccountTest is Test {
    SmartAccount smartAccount;
    DummyTarget dummy;

    address owner;
    address entryPoint;
    address sessionKey;
    address attacker;

    uint256 ownerPk;
    uint256 sessionPk;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external {
        ownerPk = 0xA11CE;
        sessionPk = 0xB0B;

        owner = vm.addr(ownerPk);
        sessionKey = vm.addr(sessionPk);

        entryPoint = makeAddr("entryPoint");
        attacker = makeAddr("attacker");

        vm.prank(owner);
        smartAccount = new SmartAccount(owner, entryPoint);

        dummy = new DummyTarget();
    }

    /*//////////////////////////////////////////////////////////////
                        SESSION KEY TESTS
    //////////////////////////////////////////////////////////////*/
    function testOwnerCanEnableSessionKey() external {
        vm.prank(owner);
        smartAccount.enableSessionKey(sessionKey, 1 hours);

        assertTrue(smartAccount.isSessionKeyValid(sessionKey));
    }

    function testNonOwnerCannotEnableSessionKey() external {
        vm.prank(attacker);
        vm.expectRevert(SmartAccount.NotOwner.selector);
        smartAccount.enableSessionKey(sessionKey, 1 hours);
    }

    function testSessionKeyExpires() external {
        vm.prank(owner);
        smartAccount.enableSessionKey(sessionKey, 1 hours);

        vm.warp(block.timestamp + 1 hours + 1);

        assertFalse(smartAccount.isSessionKeyValid(sessionKey));
    }

    function testOwnerCanDisableSessionKey() external {
        vm.prank(owner);
        smartAccount.enableSessionKey(sessionKey, 1 hours);

        vm.prank(owner);
        smartAccount.disableSessionKey(sessionKey);

        assertFalse(smartAccount.isSessionKeyValid(sessionKey));
    }

    function testNeverEnabledSessionKeyIsInvalid() external view {
        assertFalse(smartAccount.isSessionKeyValid(sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                        VALIDATE USEROP TESTS
    //////////////////////////////////////////////////////////////*/
    function testValidateUserOpWithOwnerSignature() external {
        PackedUserOperation memory userOp = _buildUserOp(ownerPk);

        vm.prank(entryPoint);
        uint256 result = smartAccount.validateUserOp(userOp, _hashUserOp(), 0);

        assertEq(result, 0);
    }

    function testValidateUserOpWithSessionKey() external {
        vm.prank(owner);
        smartAccount.enableSessionKey(sessionKey, 1 hours);

        PackedUserOperation memory userOp = _buildUserOp(sessionPk);

        vm.prank(entryPoint);
        uint256 result = smartAccount.validateUserOp(userOp, _hashUserOp(), 0);

        assertEq(result, 0);
    }

    function testValidateUserOpFailsForInvalidSigner() external {
        PackedUserOperation memory userOp = _buildUserOp(0xDEAD);

        vm.prank(entryPoint);
        uint256 result = smartAccount.validateUserOp(userOp, _hashUserOp(), 0);

        assertTrue(result != 0);
    }

    function testValidateUserOpFailsForWrongNonce() external {
        PackedUserOperation memory userOp = _buildUserOp(ownerPk);
        userOp.nonce = 999;

        vm.prank(entryPoint);
        uint256 result = smartAccount.validateUserOp(userOp, _hashUserOp(), 0);

        assertTrue(result != 0);
    }

    /*//////////////////////////////////////////////////////////////
                            EXECUTION
    //////////////////////////////////////////////////////////////*/
    function testExecuteOnlyEntryPointAllowed() external {
        vm.prank(attacker);
        vm.expectRevert(SmartAccount.NotEntryPoint.selector);

        smartAccount.execute(address(dummy), 0, "");
    }

    function testExecuteSucceedsViaEntryPoint() external {
        vm.prank(entryPoint);
        smartAccount.execute(
            address(dummy),
            0,
            abi.encodeWithSelector(DummyTarget.ping.selector)
        );
    }

    /*//////////////////////////////////////////////////////////////
                        ETH RECEIVE
    //////////////////////////////////////////////////////////////*/
    function testReceiveETH() external {
        vm.deal(address(this), 1 ether);

        (bool ok, ) = address(smartAccount).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(smartAccount).balance, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    SIGNATURE UTILS COVERAGE
    //////////////////////////////////////////////////////////////*/
    function testSignatureUtilsRecoverSigner() external view {
        bytes32 hash = keccak256("hello");

        bytes32 ethSigned = MessageHashUtils.toEthSignedMessageHash(hash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, ethSigned);

        bytes memory sig = abi.encodePacked(r, s, v);

        address recovered = SignatureUtils.recoverSigner(hash, sig);

        assertEq(recovered, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/
    function _buildUserOp(
        uint256 signerPk
    ) internal view returns (PackedUserOperation memory userOp) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(_hashUserOp());

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);

        userOp.signature = abi.encodePacked(r, s, v);
        userOp.nonce = smartAccount.nonce();
    }

    function _hashUserOp() internal pure returns (bytes32) {
        return keccak256("userop");
    }
}
