// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    IPaymaster
} from "account-abstraction/contracts/interfaces/IPaymaster.sol";
import {
    IEntryPoint
} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {
    PackedUserOperation
} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract SimplePaymaster is IPaymaster {
    error NotEntryPoint();
    error NotOwner();

    IEntryPoint public immutable entryPoint;
    address public owner;

    modifier onlyEntryPoint() {
        if (msg.sender != address(entryPoint)) revert NotEntryPoint();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _entryPoint) {
        entryPoint = IEntryPoint(_entryPoint);
        owner = msg.sender;
    }

    function validatePaymasterUserOp(
        PackedUserOperation calldata,
        bytes32,
        uint256
    )
        external
        override
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        context = "";
        validationData = 0;
    }

    function postOp(
        PostOpMode,
        bytes calldata,
        uint256,
        uint256
    ) external override onlyEntryPoint {}

    function deposit() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        entryPoint.withdrawTo(to, amount);
    }

    receive() external payable {}
}
