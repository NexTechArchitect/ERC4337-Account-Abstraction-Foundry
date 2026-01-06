// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {
    IEntryPoint
} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract DepositPaymaster is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address entryPoint = vm.envAddress("ENTRY_POINT");
        address paymaster = vm.envAddress("PAYMASTER");

        vm.startBroadcast(pk);
        IEntryPoint(entryPoint).depositTo{value: 0.01 ether}(paymaster);
        vm.stopBroadcast();
    }
}
