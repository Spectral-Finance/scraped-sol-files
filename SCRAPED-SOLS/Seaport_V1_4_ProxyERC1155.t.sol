// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TradeExecutionFailed} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {Seaport_V1_4_ProxyTestHelpers} from "./Seaport_V1_4_ProxyTestHelpers.sol";

/**
 * @notice SeaportProxy ERC1155 tests (refund, atomic fail/partial success)
 */
contract Seaport_V1_4_ProxyERC1155Test is TestParameters, TestHelpers, Seaport_V1_4_ProxyTestHelpers {
    LooksRareAggregator private aggregator;
    SeaportProxy private seaportProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 8_590_906);

        aggregator = new LooksRareAggregator(address(this));
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
        vm.deal(_buyer, INITIAL_ETH_BALANCE);
        vm.deal(address(aggregator), 1 wei);
    }

    function testExecuteAtomic() public asPrankedUser(_buyer) {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public asPrankedUser(_buyer) {
        _testExecute(false);
    }

    function testExecuteRefundFromLooksRareAggregatorAtomic() public asPrankedUser(_buyer) {
        _testExecuteRefundFromLooksRareAggregator(true);
    }

    function testExecuteRefundFromLooksRareAggregatorNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteRefundFromLooksRareAggregator(false);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(true);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectRevert(TradeExecutionFailed.selector); // InsufficientEtherSupplied
        // Not paying for the second order
        aggregator.execute{value: tradeData[0].orders[0].price}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecutePartialSuccess() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(false);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);

        // Not paying for the second order
        aggregator.execute{value: tradeData[0].orders[0].price}(tokenTransfers, tradeData, _buyer, _buyer, false);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 0), 2);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 420), 0);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - tradeData[0].orders[0].price);
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 0), 2);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 420), 3);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - value);
    }

    function _testExecuteRefundFromLooksRareAggregator(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;
        aggregator.execute{value: value + 0.1 ether}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 0), 2);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 420), 3);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - value);
    }

    function _generateTradeData(bool isAtomic)
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = validTestERC1155Id0Order();
        orders[1] = validTestERC1155Id420Order();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = validTestERC1155Id0OrderExtraData();
        ordersExtraData[1] = validTestERC1155Id420OrderExtraData();

        bytes memory extraData = isAtomic ? validMultipleItemsSameCollectionExtraData() : new bytes(0);

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
