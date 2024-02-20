// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";
import {ScamRecipient} from "./utils/ScamRecipient.sol";

/**
 * @notice LooksRareAggregator execution fail scenarios
 */
contract LooksRareAggregatorTradesTest is
    TestParameters,
    TestHelpers,
    LooksRareProxyTestHelpers,
    SeaportProxyTestHelpers
{
    LooksRareAggregator private aggregator;

    function testExecuteETHTransferFail() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_282_897);

        aggregator = new LooksRareAggregator(address(this));
        LooksRareProxy looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));

        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9_550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        vm.deal(address(this), orders[0].price);
        vm.deal(address(aggregator), 2 wei);
        vm.expectRevert(ILooksRareAggregator.ETHTransferFail.selector);
        // address(this) is a contract without receive/fallback, so ETH transfer will fail.
        aggregator.execute{value: orders[0].price}(tokenTransfers, tradeData, address(this), address(this), false);
    }

    function testExecuteZeroOriginator() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_282_897);

        aggregator = new LooksRareAggregator(address(this));
        LooksRareProxy looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));

        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9_550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        vm.deal(_buyer, orders[0].price);
        vm.prank(_buyer);
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: orders[0].price}(tokenTransfers, tradeData, address(0), _buyer, false);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testExecuteReentrancy() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_320_038);

        aggregator = new LooksRareAggregator(address(this));
        SeaportProxy seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
        // Since we are forking mainnet, we have to make sure it has 0 ETH.
        vm.deal(address(aggregator), 1 wei);
        vm.deal(address(seaportProxy), 0);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = validCityDaoOrders();
        bytes[] memory ordersExtraData = validCityDaoOrdersExtraData();
        bytes memory extraData = new bytes(0);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        uint256 totalPrice = orders[0].price + orders[1].price;
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });

        ScamRecipient scamRecipient = new ScamRecipient(address(aggregator), address(seaportProxy));

        vm.deal(_buyer, totalPrice);
        vm.startPrank(_buyer);
        aggregator.execute{value: totalPrice}(tokenTransfers, tradeData, _buyer, address(scamRecipient), false);

        assertEq(address(scamRecipient).balance, 0);
        assertEq(_buyer.balance, totalPrice);
        assertEq(IERC1155(CITY_DAO).balanceOf(_buyer, 42), 0);

        // Make sure the orders are actually valid and the last tx was not failing for other reasons.
        aggregator.execute{value: totalPrice}(tokenTransfers, tradeData, _buyer, _buyer, false);
        assertEq(_buyer.balance, 0);
        assertEq(IERC1155(CITY_DAO).balanceOf(_buyer, 42), 2);

        vm.stopPrank();
    }
}
