// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SimplePaymasterV6 {
    address public immutable i_entryPoint;

    constructor(address _entryPoint) {
        i_entryPoint = _entryPoint;
    }

    function validatePaymasterUserOp(
        UserOperation calldata,
        bytes32,
        uint256
    ) external pure returns (bytes memory context, uint256 validationData) {
        return ("", 0);
    }

    function postOp(uint8, bytes calldata, uint256) external {}

    receive() external payable {}
}

contract MinimalAccountV6 {
    address public immutable i_entryPoint;
    address public immutable i_owner;

    constructor(address entryPoint, address owner) {
        i_entryPoint = entryPoint;
        i_owner = owner;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256
    ) external view returns (uint256 validationData) {
        require(msg.sender == i_entryPoint, "Not EntryPoint");
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        (address recovered, , ) = ECDSA_Recover(digest, userOp.signature);
        if (recovered != i_owner) return 1;
        return 0;
    }

    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        require(msg.sender == i_entryPoint, "Not EntryPoint");
        (bool success, ) = dest.call{value: value}(func);
        require(success, "Execution Failed");
    }

    function ECDSA_Recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, bytes32, bytes32) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) return (address(0), 0, 0);
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) v += 27;
        address signer = ecrecover(hash, v, r, s);
        return (signer, r, s);
    }
}

struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

interface IEntryPoint {
    function getNonce(
        address sender,
        uint192 key
    ) external view returns (uint256 nonce);
    function getUserOpHash(
        UserOperation calldata userOp
    ) external view returns (bytes32);
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) external;
    function depositTo(address account) external payable;
}

contract SendUserOpWithPaymaster is Script {
    using MessageHashUtils for bytes32;
    address constant ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        MinimalAccountV6 newAccount = new MinimalAccountV6(ENTRY_POINT, owner);
        address accountAddr = address(newAccount);

        SimplePaymasterV6 newPaymaster = new SimplePaymasterV6(ENTRY_POINT);
        address paymasterAddr = address(newPaymaster);

        console2.log("=== Configuration ===");
        console2.log("Account:", accountAddr);
        console2.log("Paymaster:", paymasterAddr);

        console2.log("Funding Paymaster...");
        IEntryPoint(ENTRY_POINT).depositTo{value: 0.01 ether}(paymasterAddr);

        bytes memory executeCalldata = abi.encodeWithSelector(
            MinimalAccountV6.execute.selector,
            address(0xdead),
            0,
            ""
        );
        UserOperation memory userOp = generateSignedUserOp(
            executeCalldata,
            accountAddr,
            privateKey,
            paymasterAddr
        );

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        console2.log("=== Sending UserOp... ===");
        IEntryPoint(ENTRY_POINT).handleOps(ops, payable(owner));
        vm.stopBroadcast();

        console2.log("=== SUCCESS ===");
    }

    function generateSignedUserOp(
        bytes memory callData,
        address sender,
        uint256 key,
        address paymaster
    ) public view returns (UserOperation memory) {
        uint256 nonce = IEntryPoint(ENTRY_POINT).getNonce(sender, 0);
        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            callGasLimit: 100000,
            verificationGasLimit: 200000,
            preVerificationGas: 50000,
            maxFeePerGas: 10 gwei,
            maxPriorityFeePerGas: 2 gwei,
            paymasterAndData: abi.encodePacked(paymaster),
            signature: hex""
        });
        bytes32 hash = IEntryPoint(ENTRY_POINT).getUserOpHash(op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            key,
            MessageHashUtils.toEthSignedMessageHash(hash)
        );
        op.signature = abi.encodePacked(r, s, v);
        return op;
    }
}
