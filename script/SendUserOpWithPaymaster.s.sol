// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {
    IEntryPoint
} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {
    PackedUserOperation
} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendUserOpWithPaymaster is Script {
    using MessageHashUtils for bytes32;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address entryPoint = vm.envAddress("ENTRY_POINT");
        address sender = vm.envAddress("SMART_ACCOUNT_ADDRESS");
        address paymaster = vm.envAddress("PAYMASTER_ADDRESS");
        address beneficiary = vm.addr(pk);

        PackedUserOperation memory userOp = _buildUserOp(
            sender,
            entryPoint,
            paymaster
        );

        userOp.signature = _signUserOp(pk, entryPoint, userOp);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast(pk);
        IEntryPoint(entryPoint).handleOps(ops, payable(beneficiary));
        vm.stopBroadcast();

        console.log("UserOp submitted successfully!");
        console.log("Sender:", sender);
        console.log("Nonce:", userOp.nonce);
    }

    function _buildUserOp(
        address sender,
        address entryPoint,
        address paymaster
    ) internal view returns (PackedUserOperation memory) {
        bytes memory paymasterAndData = abi.encodePacked(
            paymaster,
            uint128(100_000),
            uint128(50_000)
        );

        return
            PackedUserOperation({
                sender: sender,
                nonce: IEntryPoint(entryPoint).getNonce(sender, 0),
                initCode: hex"",
                callData: hex"",
                accountGasLimits: bytes32(
                    (uint256(1_000_000) << 128) | 500_000
                ),
                preVerificationGas: 100_000,
                gasFees: bytes32((uint256(2 gwei) << 128) | 10 gwei),
                paymasterAndData: paymasterAndData,
                signature: hex""
            });
    }

    function _signUserOp(
        uint256 pk,
        address entryPoint,
        PackedUserOperation memory userOp
    ) internal view returns (bytes memory) {
        bytes32 userOpHash = IEntryPoint(entryPoint).getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            pk,
            userOpHash.toEthSignedMessageHash()
        );
        return abi.encodePacked(r, s, v);
    }
}
