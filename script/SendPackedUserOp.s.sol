// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    address constant RANDOM_APPROVER = 0x8362D78b511d440B62876ea1fE7Da8bC9F9d2710;

    function run() public {
        // Setup
        HelperConfig helperConfig = new HelperConfig();
        address dest = helperConfig.getConfig().usdc;
        uint256 value = 0;
        address minimalAccountAddress = DevOpsTools.get_most_recent_deployment("MinimalAccount", block.chainid);
        address entryPoint = helperConfig.getConfig().entryPoint;
        bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, RANDOM_APPROVER, 1e18);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory userOp =
            generateSignedUserOperation(executeCallData, minimalAccountAddress, helperConfig.getConfig());
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        // Sending the transaction
        vm.startBroadcast();
        IEntryPoint(entryPoint).handleOps(ops, payable(helperConfig.getConfig().account));
        vm.stopBroadcast();
    }

    function generateSignedUserOperation(
        bytes memory callData,
        address minimalAccount,
        HelperConfig.NetworkConfig memory config
    ) public view returns (PackedUserOperation memory) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(minimalAccount, nonce, callData);

        // 2. Get the userOp hash. Then retrieve digest from it.
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(address sender, uint256 nonce, bytes memory callData)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        PackedUserOperation memory unsignedUserOperation = PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
        return unsignedUserOperation;
    }
}
