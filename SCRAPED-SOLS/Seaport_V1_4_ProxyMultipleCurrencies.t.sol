// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {Seaport_V1_4_ProxyTestHelpers} from "./Seaport_V1_4_ProxyTestHelpers.sol";

/**
 * @notice Seaport multiple currencies execution in one transaction tests
 */
contract Seaport_V1_4_ProxyMultipleCurrenciesTest is TestParameters, TestHelpers, Seaport_V1_4_ProxyTestHelpers {
    LooksRareAggregator private aggregator;
    ERC20EnabledLooksRareAggregator private erc20EnabledAggregator;
    SeaportProxy private seaportProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 8_597_553);

        aggregator = new LooksRareAggregator(address(this));
        erc20EnabledAggregator = new ERC20EnabledLooksRareAggregator(address(aggregator));
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
        vm.deal(_buyer, INITIAL_ETH_BALANCE);
        deal(WETH_GOERLI, _buyer, INITIAL_ETH_BALANCE);
        vm.deal(address(aggregator), 1 wei);

        aggregator.approve(WETH_GOERLI, SEAPORT, type(uint256).max);
        aggregator.setERC20EnabledLooksRareAggregator(address(erc20EnabledAggregator));
    }

    function testExecuteAtomic() public asPrankedUser(_buyer) {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public asPrankedUser(_buyer) {
        _testExecute(false);
    }

    function testExecuteWithExcessWETHAtomic() public asPrankedUser(_buyer) {
        _testExecuteWithExcessWETH(true);
    }

    function testExecuteWithExcessWETHNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteWithExcessWETH(false);
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);

        uint256 ethAmount = tradeData[0].orders[0].price;
        uint256 wethAmount = tradeData[0].orders[1].price;

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0].amount = wethAmount;
        tokenTransfers[0].currency = WETH_GOERLI;

        IERC20(WETH_GOERLI).approve(address(erc20EnabledAggregator), wethAmount);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledAggregator.execute{value: ethAmount}(tokenTransfers, tradeData, _buyer, isAtomic);

        assertEq(IERC721(MULTIFAUCET_NFT).balanceOf(_buyer), 2);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828268), _buyer);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828269), _buyer);

        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - ethAmount);
        assertEq(IERC20(WETH_GOERLI).balanceOf(_buyer), INITIAL_ETH_BALANCE - wethAmount);
        assertEq(IERC20(WETH_GOERLI).allowance(_buyer, address(erc20EnabledAggregator)), 0);
    }

    function _testExecuteWithExcessWETH(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);

        uint256 excess = 100e6;

        uint256 ethAmount = tradeData[0].orders[0].price;
        uint256 wethAmount = tradeData[0].orders[1].price + excess;

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0].amount = wethAmount;
        tokenTransfers[0].currency = WETH_GOERLI;

        IERC20(WETH_GOERLI).approve(address(erc20EnabledAggregator), wethAmount);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledAggregator.execute{value: ethAmount}(tokenTransfers, tradeData, _buyer, isAtomic);

        assertEq(IERC721(MULTIFAUCET_NFT).balanceOf(_buyer), 2);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828268), _buyer);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828269), _buyer);

        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - ethAmount);
        assertEq(IERC20(WETH_GOERLI).balanceOf(_buyer), INITIAL_ETH_BALANCE - tradeData[0].orders[1].price);
        assertEq(IERC20(WETH_GOERLI).allowance(_buyer, address(erc20EnabledAggregator)), 0);

        assertEq(IERC20(WETH_GOERLI).balanceOf(address(aggregator)), 0);
        assertEq(IERC20(WETH_GOERLI).balanceOf(address(erc20EnabledAggregator)), 0);
        assertEq(IERC20(WETH_GOERLI).balanceOf(address(seaportProxy)), 0);
    }

    function _generateTradeData(bool isAtomic) private view returns (ILooksRareAggregator.TradeData[] memory) {
        BasicOrder memory orderOne = validMultifaucetId2828268Order();
        BasicOrder memory orderTwo = validMultifaucetId2828269Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes[] memory ordersExtraData = new bytes[](2);
        {
            bytes memory orderOneExtraData = validMultifaucetId2828268OrderExtraData();
            bytes memory orderTwoExtraData = validMultifaucetId2828269OrderExtraData();
            ordersExtraData[0] = orderOneExtraData;
            ordersExtraData[1] = orderTwoExtraData;
        }

        bytes memory extraData = isAtomic
            ? validMultipleItemsSameCollectionMultipleCurrenciesExtraData()
            : new bytes(0);
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
