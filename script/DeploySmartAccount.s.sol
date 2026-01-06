// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/account/SmartAccount.sol";

/**
 * @title DeploySmartAccount
 * @author NEXTECHARHITECT
 * @notice Deploys the SmartAccount with owner & EntryPoint
 */
contract DeploySmartAccount is Script {
    function run() external returns (SmartAccount smartAccount) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address owner = vm.envAddress("OWNER_ADDRESS");
        address entryPoint = vm.envAddress("ENTRY_POINT");

        vm.startBroadcast(deployerKey);

        smartAccount = new SmartAccount(owner, entryPoint);

        vm.stopBroadcast();
    }
}
