// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../../src/paymaster/SimplePaymaster.sol";
import {
    PackedUserOperation
} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {
    IEntryPoint
} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

/*//////////////////////////////////////////////////////////////
                        MOCK ENTRYPOINT
//////////////////////////////////////////////////////////////*/
contract MockEntryPoint {
    mapping(address => uint256) public deposits;

    function depositTo(address paymaster) external payable {
        deposits[paymaster] += msg.value;
    }

    function withdrawTo(address payable to, uint256 amount) external {
        (bool ok, ) = to.call{value: amount}("");
        require(ok);
    }
}

/*//////////////////////////////////////////////////////////////
                        PAYMASTER TEST
//////////////////////////////////////////////////////////////*/
contract SimplePaymasterTest is Test {
    SimplePaymaster paymaster;
    MockEntryPoint entryPoint;

    address owner;
    address attacker;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external {
        owner = makeAddr("owner");
        attacker = makeAddr("attacker");

        entryPoint = new MockEntryPoint();

        vm.prank(owner);
        paymaster = new SimplePaymaster(address(entryPoint));
    }

    /*//////////////////////////////////////////////////////////////
                        VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testValidatePaymasterUserOpOnlyEntryPoint() external {
        PackedUserOperation memory userOp;

        vm.prank(attacker);
        vm.expectRevert(SimplePaymaster.NotEntryPoint.selector);

        paymaster.validatePaymasterUserOp(userOp, bytes32(0), 0);
    }

    function testValidatePaymasterUserOpSucceeds() external {
        PackedUserOperation memory userOp;

        vm.prank(address(entryPoint));
        (bytes memory context, uint256 validationData) = paymaster
            .validatePaymasterUserOp(userOp, bytes32(0), 0);

        assertEq(context.length, 0);
        assertEq(validationData, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        POST-OP TESTS
    //////////////////////////////////////////////////////////////*/

    function testPostOpOnlyEntryPoint() external {
        vm.prank(attacker);
        vm.expectRevert(SimplePaymaster.NotEntryPoint.selector);

        paymaster.postOp(IPaymaster.PostOpMode.opSucceeded, "", 0, 0);
    }

    function testPostOpSucceeds() external {
        vm.prank(address(entryPoint));

        paymaster.postOp(IPaymaster.PostOpMode.opSucceeded, "", 0, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT / WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testDepositIncreasesEntryPointBalance() external {
        vm.deal(owner, 1 ether);

        vm.prank(owner);
        paymaster.deposit{value: 1 ether}();

        assertEq(entryPoint.deposits(address(paymaster)), 1 ether);
    }

    function testWithdrawOnlyOwner() external {
        vm.prank(attacker);
        vm.expectRevert(SimplePaymaster.NotOwner.selector);

        paymaster.withdraw(payable(attacker), 1 ether);
    }

    function testWithdrawSucceeds() external {
        vm.deal(address(entryPoint), 1 ether);

        vm.prank(owner);
        paymaster.withdraw(payable(owner), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        RECEIVE ETH
    //////////////////////////////////////////////////////////////*/

    function testReceiveETH() external {
        vm.deal(address(this), 1 ether);

        (bool ok, ) = address(paymaster).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(paymaster).balance, 1 ether);
    }
}
