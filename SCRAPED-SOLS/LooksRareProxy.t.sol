// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

/**
 * @notice LooksRareProxy tests, tests involving actual executions live in other tests
 */
contract LooksRareProxyTest is TestParameters, TestHelpers, LooksRareProxyTestHelpers {
    LooksRareAggregator private aggregator;
    LooksRareProxy private looksRareProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_282_897);

        aggregator = new LooksRareAggregator(address(this));
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        vm.deal(_buyer, 200 ether);
        vm.deal(address(aggregator), 1 wei);
    }

    function testExecuteCallerNotAggregator() public {
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(1));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectRevert(IProxy.InvalidCaller.selector);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        // Pay less for order 0
        tradeData[0].orders[0].price -= 0.1 ether;
        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectRevert("Strategy: Execution invalid");
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecutePartialSuccess() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        // Pay less for order 0
        tradeData[0].orders[0].price -= 0.1 ether;
        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(BAYC).balanceOf(_buyer), 1);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
        assertEq(_buyer.balance, 200 ether - tradeData[0].orders[1].price);
    }

    function testExecuteRefundExtraPaid() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price + 0.1 ether;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(BAYC).balanceOf(_buyer), 2);
        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
        assertEq(_buyer.balance, 200 ether - value + 0.1 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: 0}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecuteOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9_550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = orders[0].price + orders[1].price;

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9_550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[1] = abi.encode(orders[1].price, 8_500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE);

        tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });
    }
}
