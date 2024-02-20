// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../libraries/OrderStructs.sol";
import {IProxy} from "../interfaces/IProxy.sol";
import {ICryptoPunks} from "../interfaces/ICryptoPunks.sol";
import {InvalidOrderLength} from "../libraries/SharedErrors.sol";

/**
 * @title CryptoPunksProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from CryptoPunks
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract CryptoPunksProxy is IProxy {
    ICryptoPunks public immutable marketplace;
    address public immutable aggregator;

    /**
     * @param _marketplace CryptoPunks' address
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _marketplace, address _aggregator) {
        marketplace = ICryptoPunks(_marketplace);
        aggregator = _aggregator;
    }

    /**
     * @notice Execute CryptoPunks NFT sweeps in a single transaction
     * @dev ordersExtraData and extraData are not used
     * @param orders Orders to be executed by CryptoPunks
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata, /* ordersExtraData */
        bytes memory, /* extraData */
        address recipient,
        bool isAtomic
    ) external payable override {
        if (address(this) != aggregator) {
            revert InvalidCaller();
        }

        uint256 ordersLength = orders.length;
        if (ordersLength == 0) {
            revert InvalidOrderLength();
        }

        for (uint256 i; i < ordersLength; ) {
            uint256 punkId = orders[i].tokenIds[0];

            if (isAtomic) {
                marketplace.buyPunk{value: orders[i].price}(punkId);
                marketplace.transferPunk(recipient, punkId);
            } else {
                try marketplace.buyPunk{value: orders[i].price}(punkId) {
                    marketplace.transferPunk(recipient, punkId);
                } catch {}
            }

            unchecked {
                ++i;
            }
        }
    }
}
