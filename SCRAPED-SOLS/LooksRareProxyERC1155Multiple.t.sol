// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

/**
 * @notice LooksRareProxy ERC1155 tests (amount > 1), forking Goerli
 */
contract LooksRareProxyERC1155MultipleTest is TestParameters, TestHelpers, LooksRareProxyTestHelpers {
    LooksRareAggregator private aggregator;
    LooksRareProxy private looksRareProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 7935348);

        aggregator = new LooksRareAggregator(address(this));
        looksRareProxy = new LooksRareProxy(0xD112466471b5438C1ca2D218694200e49d81D047, address(aggregator));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        vm.deal(_buyer, 1 ether);
        vm.deal(address(aggregator), 0);
    }

    function testExecuteAtomic() public {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public {
        _testExecute(false);
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        BasicOrder memory order = tradeData[0].orders[0];

        vm.prank(order.signer);
        IERC1155(order.collection).setApprovalForAll(
            0xF2ae42e871937F4e9ffb394C5A814357C16e06d6, // TransferManagerERC1155
            true
        );

        vm.prank(_buyer);
        aggregator.execute{value: order.price}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC1155(order.collection).balanceOf(_buyer, 1), 2);
        assertEq(_buyer.balance, 0);
    }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validGoerliTestERC1155Order();

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9_800, 0, 0x6ACbeb7f6E225FbC0D1CEe27a40ADC49E7277E57);

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
