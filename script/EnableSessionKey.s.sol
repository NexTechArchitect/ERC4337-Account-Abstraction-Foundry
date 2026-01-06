// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/account/SmartAccount.sol";

contract EnableSessionKey is Script {
    function run() external {
        uint256 ownerKey = vm.envUint("PRIVATE_KEY");

        address smartAccountAddr = vm.envAddress("SMART_ACCOUNT_ADDRESS");
        address sessionKey = vm.envAddress("SESSION_KEY_ADDRESS");
        uint48 duration = uint48(vm.envUint("SESSION_KEY_DURATION"));

        vm.startBroadcast(ownerKey);

        SmartAccount smartAccount = SmartAccount(payable(smartAccountAddr));
        smartAccount.enableSessionKey(sessionKey, duration);

        vm.stopBroadcast();
    }
}
