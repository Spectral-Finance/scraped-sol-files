// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {TransferManager} from "../../contracts/TransferManager.sol";

// Create2 factory interface
import {IImmutableCreate2Factory} from "../../contracts/interfaces/IImmutableCreate2Factory.sol";

/**
 * @dev
 * Use
 * forge create --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $TESTNET_KEY \
 *     --constructor-args 0xF332533bF5d0aC462DC8511067A8122b4DcE2B57 \
 *     --etherscan-api-key $ETHERSCAN_API_KEY \
 *     --verify contracts/TransferManager.sol:TransferManager

 * for testnet deployment
 */
contract Deployment is Script {
    IImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;

        if (chainId != 1 && chainId != 42161) {
            revert ChainIdInvalid(chainId);
        }

        uint256 deployerPrivateKey = vm.envUint("MAINNET_KEY");
        address owner = 0x3ab105F0e4A22ec4A96a9b0Ca90c5C534d21f3a7;

        vm.startBroadcast(deployerPrivateKey);

        IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("ARBITRUM_TRANSFER_MANAGER_SALT"),
            initializationCode: abi.encodePacked(type(TransferManager).creationCode, abi.encode(owner))
        });

        vm.stopBroadcast();
    }
}
