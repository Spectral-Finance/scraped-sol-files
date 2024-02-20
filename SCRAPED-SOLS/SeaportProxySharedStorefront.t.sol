// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";

/**
 * @notice SeaportProxy OpenSea shared storefront, forking Goerli
 */
contract SeaportProxySharedStorefrontTest is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    LooksRareAggregator private aggregator;
    SeaportProxy private seaportProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 7_993_401);

        aggregator = new LooksRareAggregator(address(this));
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);

        vm.deal(_buyer, 100 ether);
        vm.deal(address(aggregator), 0);
    }

    function testExecuteAtomic() public {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public {
        _testExecute(false);
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        BasicOrder memory order = tradeData[0].orders[0];

        vm.prank(_buyer);
        aggregator.execute{value: order.price}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC1155(order.collection).balanceOf(_buyer, order.tokenIds[0]), 1);
        assertEq(_buyer.balance, 0);
    }

    function _generateTradeData(bool isAtomic)
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = validOpenseaSharedStorefrontOrders();
        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = validOpenseaSharedStorefrontOrderExtraData();
        bytes memory extraData = isAtomic ? validSingleOfferExtraData(2) : new bytes(0);

        tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });
    }
}
