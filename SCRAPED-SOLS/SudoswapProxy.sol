// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../libraries/OrderStructs.sol";
import {IProxy} from "../interfaces/IProxy.sol";
import {ISudoswapRouter} from "../interfaces/ISudoswapRouter.sol";
import {InvalidOrderLength} from "../libraries/SharedErrors.sol";

/**
 * @title SudoswapProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from SudoswapProxy
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SudoswapProxy is IProxy {
    ISudoswapRouter public immutable marketplace;
    address public immutable aggregator;

    /**
     * @param _marketplace Sudoswap router's address
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _marketplace, address _aggregator) {
        marketplace = ISudoswapRouter(_marketplace);
        aggregator = _aggregator;
    }

    /**
     * @notice Execute Sudoswap NFT sweeps in a single transaction
     * @dev ordersExtraData and extraData are not used
     * @param orders Orders to be executed by Seaport
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

        uint256 ethValue;

        if (isAtomic) {
            ISudoswapRouter.PairSwapSpecific[] memory swapList = new ISudoswapRouter.PairSwapSpecific[](orders.length);

            for (uint256 i; i < ordersLength; ) {
                ISudoswapRouter.PairSwapSpecific memory pairSwapSpecific;
                // here the collection is the AMM pool address
                pairSwapSpecific.pair = orders[i].collection;
                pairSwapSpecific.nftIds = orders[i].tokenIds;

                swapList[i] = pairSwapSpecific;

                ethValue = ethValue + orders[i].price;

                unchecked {
                    ++i;
                }
            }

            marketplace.swapETHForSpecificNFTs{value: ethValue}(
                swapList,
                payable(recipient),
                recipient,
                block.timestamp
            );
        } else {
            ISudoswapRouter.RobustPairSwapSpecific[] memory swapList = new ISudoswapRouter.RobustPairSwapSpecific[](
                orders.length
            );

            for (uint256 i; i < ordersLength; ) {
                ISudoswapRouter.RobustPairSwapSpecific memory robustPairSwapSpecific;
                ISudoswapRouter.PairSwapSpecific memory pairSwapSpecific;
                robustPairSwapSpecific.maxCost = orders[i].price;
                ethValue = ethValue + orders[i].price;
                // here the collection is the AMM pool address
                pairSwapSpecific.pair = orders[i].collection;
                pairSwapSpecific.nftIds = orders[i].tokenIds;
                robustPairSwapSpecific.swapInfo = pairSwapSpecific;

                swapList[i] = robustPairSwapSpecific;

                unchecked {
                    ++i;
                }
            }

            // TODO: This cannot handle the case where the NFT to be purchased
            //       is no longer in the pool for whatever reasons. We will have
            //       to wait for Sudoswap's router V2 to go live to re-integrate
            //       as it allows partial fills.

            marketplace.robustSwapETHForSpecificNFTs{value: ethValue}(
                swapList,
                payable(recipient),
                recipient,
                block.timestamp
            );
        }
    }
}
