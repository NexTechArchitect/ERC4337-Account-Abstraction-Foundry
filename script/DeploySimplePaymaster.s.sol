// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {SimplePaymaster} from "../src/paymaster/SimplePaymaster.sol";

contract DeploySimplePaymaster is Script {
    // ✅ Official ERC-4337 v0.7 EntryPoint (Sepolia)
    address constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function run() external returns (address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        // Deploy Paymaster with correct EntryPoint
        SimplePaymaster paymaster = new SimplePaymaster(ENTRY_POINT);

        vm.stopBroadcast();

        return address(paymaster);
    }
}
