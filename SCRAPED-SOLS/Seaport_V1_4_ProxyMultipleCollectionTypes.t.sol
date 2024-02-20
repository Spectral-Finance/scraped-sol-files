// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {Seaport_V1_4_ProxyTestHelpers} from "./Seaport_V1_4_ProxyTestHelpers.sol";

/**
 * @notice SeaportProxy ERC721/ERC1155 in one transaction tests
 */
contract Seaport_V1_4_ProxyMultipleCollectionTypesTest is TestParameters, TestHelpers, Seaport_V1_4_ProxyTestHelpers {
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

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);
        uint256 totalPrice = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: totalPrice}(new TokenTransfer[](0), tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828268), _buyer);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 0), 2);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - totalPrice);
    }

    function _generateTradeData(bool isAtomic) private view returns (ILooksRareAggregator.TradeData[] memory) {
        BasicOrder memory orderOne = validMultifaucetId2828268Order();
        BasicOrder memory orderTwo = validTestERC1155Id0Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes[] memory ordersExtraData = new bytes[](2);
        {
            bytes memory orderOneExtraData = validMultifaucetId2828268OrderExtraData();
            bytes memory orderTwoExtraData = validTestERC1155Id0OrderExtraData();
            ordersExtraData[0] = orderOneExtraData;
            ordersExtraData[1] = orderTwoExtraData;
        }

        bytes memory extraData = isAtomic ? validMultipleCollectionsExtraData() : new bytes(0);
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
