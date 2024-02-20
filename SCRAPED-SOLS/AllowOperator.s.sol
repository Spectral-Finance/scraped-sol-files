// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

// Core contracts
import {TransferManager} from "../contracts/TransferManager.sol";

contract AllowOperator is Script {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey;

        // if (chainId == 1) {
        //     deployerPrivateKey = vm.envUint("MAINNET_KEY");
        // } else if (chainId == 5) {
        //     deployerPrivateKey = vm.envUint("TESTNET_KEY");
        // } else if (chainId == 11155111) {
        //     deployerPrivateKey = vm.envUint("TESTNET_KEY");
        // } else {
        //     revert ChainIdInvalid(chainId);
        // }

        if (chainId != 5) {
            revert ChainIdInvalid(chainId);
        }

        deployerPrivateKey = vm.envUint("TESTNET_KEY");

        vm.startBroadcast(deployerPrivateKey);

        TransferManager transferManager = TransferManager(0xb737687983D6CcB4003A727318B5454864Ecba9d);
        transferManager.allowOperator(0x5aad7D660fDfEe455243a45978072980773de42a);

        vm.stopBroadcast();
    }
}
