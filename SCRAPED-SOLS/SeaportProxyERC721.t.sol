// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";

/**
 * @notice SeaportProxy additional execution tests (refund, atomic fail/partial success)
 */
contract SeaportProxyERC721Test is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    LooksRareAggregator private aggregator;
    SeaportProxy private seaportProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_300_884);

        aggregator = new LooksRareAggregator(address(this));
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
        vm.deal(_buyer, INITIAL_ETH_BALANCE);
        vm.deal(address(aggregator), 1 wei);
    }

    function testExecuteRefundFromLooksRareAggregatorAtomic() public asPrankedUser(_buyer) {
        _testExecuteRefundFromLooksRareAggregator(true);
    }

    function testExecuteRefundFromLooksRareAggregatorNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteRefundFromLooksRareAggregator(false);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();

        vm.warp(block.timestamp + tradeData[0].orders[1].endTime + 1);

        vm.expectRevert(0xd5da9a1b); // NoSpecifiedOrdersAvailable
        aggregator.execute{value: tradeData[0].orders[0].price + tradeData[0].orders[1].price}(
            new TokenTransfer[](0),
            tradeData,
            _buyer,
            _buyer,
            true
        );
    }

    function testExecutePartialSuccess() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        // Not paying for the second order
        aggregator.execute{value: tradeData[0].orders[0].price}(
            new TokenTransfer[](0),
            tradeData,
            _buyer,
            _buyer,
            false
        );

        assertEq(IERC721(BAYC).balanceOf(_buyer), 1);
        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - tradeData[0].orders[0].price);
    }

    function _testExecuteRefundFromLooksRareAggregator(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        uint256 totalPrice = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: totalPrice + 1 ether}(new TokenTransfer[](0), tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
        assertEq(IERC721(BAYC).ownerOf(8498), _buyer);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - totalPrice);
    }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory) {
        BasicOrder memory orderOne = validBAYCId2518Order();
        BasicOrder memory orderTwo = validBAYCId8498Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes[] memory ordersExtraData = new bytes[](2);
        {
            bytes memory orderOneExtraData = validBAYCId2518OrderExtraData();
            bytes memory orderTwoExtraData = validBAYCId8498OrderExtraData();
            ordersExtraData[0] = orderOneExtraData;
            ordersExtraData[1] = orderTwoExtraData;
        }

        bytes memory extraData = validMultipleItemsSameCollectionExtraData();
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });

        return tradeData;
    }
}
