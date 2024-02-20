// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CryptoPunksProxy} from "../../contracts/proxies/CryptoPunksProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ICryptoPunks} from "../../contracts/interfaces/ICryptoPunks.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength, TradeExecutionFailed} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";

contract CryptoPunksProxyTest is TestParameters, TestHelpers {
    LooksRareAggregator private aggregator;
    CryptoPunksProxy private cryptoPunksProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_358_065);

        aggregator = new LooksRareAggregator(address(this));
        cryptoPunksProxy = new CryptoPunksProxy(CRYPTOPUNKS, address(aggregator));
        aggregator.addFunction(address(cryptoPunksProxy), CryptoPunksProxy.execute.selector);
        vm.deal(_buyer, 138 ether);
        vm.deal(address(aggregator), 1 wei);
    }

    function testExecuteAtomic() public asPrankedUser(_buyer) {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public asPrankedUser(_buyer) {
        _testExecute(false);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        // Pay nothing for the second order
        tradeData[0].orders[1].price = 0;

        vm.expectRevert(TradeExecutionFailed.selector);
        aggregator.execute{value: 68.5 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: true
        });
    }

    function testExecutePartialSuccess() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        // Pay nothing for the second order
        tradeData[0].orders[1].price = 0;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);

        aggregator.execute{value: 68.5 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: false
        });

        assertEq(ICryptoPunks(CRYPTOPUNKS).balanceOf(_buyer), 1);
        assertEq(ICryptoPunks(CRYPTOPUNKS).punkIndexToAddress(3149), _buyer);
        assertEq(_buyer.balance, 69.5 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(cryptoPunksProxy),
            selector: CryptoPunksProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: 138 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: true
        });
    }

    function validCryptoPunksOrder() private pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        orders[0].signer = address(0);
        orders[0].collection = CRYPTOPUNKS;
        orders[0].collectionType = CollectionType.ERC721;

        orders[1].signer = address(0);
        orders[1].collection = CRYPTOPUNKS;
        orders[1].collectionType = CollectionType.ERC721;

        uint256[] memory orderOneTokenIds = new uint256[](1);
        orderOneTokenIds[0] = 3149;
        orders[0].tokenIds = orderOneTokenIds;

        uint256[] memory orderTwoTokenIds = new uint256[](1);
        orderTwoTokenIds[0] = 2675;
        orders[1].tokenIds = orderTwoTokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;
        orders[1].amounts = amounts;

        orders[0].price = 68.5 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 0;
        orders[0].signature = "";

        orders[1].price = 69.5 ether;
        orders[1].currency = address(0);
        orders[1].startTime = 0;
        orders[1].endTime = 0;
        orders[1].signature = "";
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);

        aggregator.execute{value: 138 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: isAtomic
        });

        assertEq(ICryptoPunks(CRYPTOPUNKS).balanceOf(_buyer), 2);
        assertEq(ICryptoPunks(CRYPTOPUNKS).punkIndexToAddress(3149), _buyer);
        assertEq(ICryptoPunks(CRYPTOPUNKS).punkIndexToAddress(2675), _buyer);
        assertEq(_buyer.balance, 0);
    }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        bytes[] memory ordersExtraData = new bytes[](2);
        tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(cryptoPunksProxy),
            selector: CryptoPunksProxy.execute.selector,
            orders: validCryptoPunksOrder(),
            ordersExtraData: ordersExtraData,
            extraData: ""
        });
    }
}
