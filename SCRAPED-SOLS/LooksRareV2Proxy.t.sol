// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {LooksRareV2Proxy} from "../../contracts/proxies/LooksRareV2Proxy.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {ITransferManager} from "../../contracts/interfaces/ITransferManager.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {MerkleTree} from "../../contracts/libraries/looksrare-v2/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength, TradeExecutionFailed} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {LooksRareV2ProxyTestHelpers} from "./LooksRareV2ProxyTestHelpers.sol";

contract LooksRareV2ProxyTest is TestParameters, TestHelpers, LooksRareV2ProxyTestHelpers {
    LooksRareAggregator private aggregator;
    ERC20EnabledLooksRareAggregator private erc20EnabledLooksRareAggregator;
    LooksRareV2Proxy private looksRareV2Proxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 8_543_681);

        vm.deal(LOOKSRARE_V2_GOERLI, 1 wei);

        aggregator = new LooksRareAggregator(address(this));
        looksRareV2Proxy = new LooksRareV2Proxy(LOOKSRARE_V2_GOERLI, address(aggregator));
        aggregator.addFunction(address(looksRareV2Proxy), LooksRareV2Proxy.execute.selector);

        erc20EnabledLooksRareAggregator = new ERC20EnabledLooksRareAggregator(address(aggregator));
        aggregator.setERC20EnabledLooksRareAggregator(address(erc20EnabledLooksRareAggregator));

        aggregator.approve(WETH_GOERLI, LOOKSRARE_V2_GOERLI, type(uint256).max);

        vm.deal(_buyer, 200 ether);
        vm.deal(NFT_OWNER, 200 ether);
        deal(WETH_GOERLI, _buyer, 200 ether);
        deal(WETH_GOERLI, NFT_OWNER, 200 ether);
        vm.deal(address(aggregator), 1 wei);

        vm.startPrank(NFT_OWNER);
        IERC721(MULTIFAUCET_NFT).setApprovalForAll(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI, true);
        IERC1155(TEST_ERC1155).setApprovalForAll(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI, true);
        address[] memory operators = new address[](1);
        operators[0] = LOOKSRARE_V2_GOERLI;
        ITransferManager(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI).grantApprovals(operators);
        vm.stopPrank();
    }

    function testExecuteERC721SingleMakerAskAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721SingleMakerAsk(true);
    }

    function testExecuteERC721SingleMakerAskNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721SingleMakerAsk(false);
    }

    function testExecuteERC721MultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721MultipleMakerAsks(true);
    }

    function testExecuteERC721MultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721MultipleMakerAsks(false);
    }

    function testExecuteERC1155SingleMakerAskAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155SingleMakerAsk(true);
    }

    function testExecuteERC1155SingleMakerAskNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155SingleMakerAsk(false);
    }

    function testExecuteERC1155MultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155MultipleMakerAsks(true);
    }

    function testExecuteERC1155MultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155MultipleMakerAsks(false);
    }

    function testExecuteERC721WETHSingleMakerAskAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721WETHSingleMakerAsk(true);
    }

    function testExecuteERC721WETHSingleMakerAskNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721WETHSingleMakerAsk(false);
    }

    function testExecuteERC721WETHMultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721WETHMultipleMakerAsks(true);
    }

    function testExecuteERC721WETHMultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721WETHMultipleMakerAsks(false);
    }

    function testExecuteERC1155WETHSingleMakerAskAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155WETHSingleMakerAsk(true);
    }

    function testExecuteERC1155WETHSingleMakerAskNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155WETHSingleMakerAsk(false);
    }

    function testExecuteERC1155WETHMultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155WETHMultipleMakerAsks(true);
    }

    function testExecuteERC1155WETHMultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155WETHMultipleMakerAsks(false);
    }

    function testExecuteMultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteMultipleMakerAsks(true);
    }

    function testExecuteMultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteMultipleMakerAsks(false);
    }

    function testExecuteWETHMultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteWETHMultipleMakerAsks(true);
    }

    function testExecuteWETHMultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteWETHMultipleMakerAsks(false);
    }

    function testExecuteMixedCurrenciesMultipleMakerAsksAtomic() public asPrankedUser(_buyer) {
        _testExecuteMixedCurrenciesMultipleMakerAsks(true);
    }

    function testExecuteMixedCurrenciesMultipleMakerAsksNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteMixedCurrenciesMultipleMakerAsks(false);
    }

    function testExecuteCallerNotAggregator() public {
        looksRareV2Proxy = new LooksRareV2Proxy(LOOKSRARE_V2_GOERLI, address(1));
        aggregator.addFunction(address(looksRareV2Proxy), looksRareV2Proxy.execute.selector);

        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721MultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectRevert(IProxy.InvalidCaller.selector);
        vm.prank(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721MultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0)) - 0.01 ether;

        vm.expectRevert(TradeExecutionFailed.selector);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecutePartialSuccess() public {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721MultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        // Seller no longer owns one of the NFTs in the second order
        vm.prank(NFT_OWNER);
        IERC721(MULTIFAUCET_NFT).transferFrom(NFT_OWNER, address(69), 2828267);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        vm.prank(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(MULTIFAUCET_NFT).balanceOf(_buyer), 1);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828266), _buyer);
        _assertETHChangedHands(tradeData[0].orders[0].price);
    }

    function testExecuteRefundExtraPaid() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721MultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value + 0.1 ether}(tokenTransfers, tradeData, _buyer, _buyer, false);

        _assertERC721OwnershipChangedHands();
        _assertETHChangedHands(value);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareV2Proxy),
            selector: LooksRareV2Proxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: abi.encode(address(0)) // affiliate
        });

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: 0}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecuteOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = validGoerliTestERC721Orders();

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        ILooksRareAggregator.TradeData[] memory tradeData = _tradeData(orders, ordersExtraData);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function _testExecuteERC721SingleMakerAsk(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721SingleMakerAskTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC721(MULTIFAUCET_NFT).balanceOf(_buyer), 1);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828266), _buyer);
        _assertETHChangedHands(value);
    }

    function _testExecuteERC721MultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721MultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        _assertERC721OwnershipChangedHands();
        _assertETHChangedHands(value);
    }

    function _testExecuteERC1155SingleMakerAsk(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC1155SingleMakerAskTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 69), 5);
        _assertETHChangedHands(value);
    }

    function _testExecuteERC1155MultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC1155MultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        _assertERC1155OwnershipChangedHands();
        _assertETHChangedHands(value);
    }

    function _testExecuteERC721WETHSingleMakerAsk(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721WETHSingleMakerAskTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        uint256 value = _orderValue(tradeData[0], WETH_GOERLI);
        tokenTransfers[0] = TokenTransfer({amount: value, currency: WETH_GOERLI});

        IERC20(WETH_GOERLI).approve(address(erc20EnabledLooksRareAggregator), value);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledLooksRareAggregator.execute(tokenTransfers, tradeData, _buyer, isAtomic);

        assertEq(IERC721(MULTIFAUCET_NFT).balanceOf(_buyer), 1);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828266), _buyer);
        _assertWETHChangedHands(value);
    }

    function _testExecuteERC721WETHMultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721WETHMultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        uint256 value = _orderValue(tradeData[0], WETH_GOERLI);
        tokenTransfers[0] = TokenTransfer({amount: value, currency: WETH_GOERLI});

        IERC20(WETH_GOERLI).approve(address(erc20EnabledLooksRareAggregator), value);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledLooksRareAggregator.execute(tokenTransfers, tradeData, _buyer, isAtomic);

        _assertERC721OwnershipChangedHands();
        _assertWETHChangedHands(value);
    }

    function _testExecuteERC1155WETHSingleMakerAsk(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC1155WETHSingleMakerAskTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        uint256 value = _orderValue(tradeData[0], WETH_GOERLI);
        tokenTransfers[0] = TokenTransfer({amount: value, currency: WETH_GOERLI});

        IERC20(WETH_GOERLI).approve(address(erc20EnabledLooksRareAggregator), value);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledLooksRareAggregator.execute(tokenTransfers, tradeData, _buyer, isAtomic);

        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 69), 5);
        _assertWETHChangedHands(value);
    }

    function _testExecuteERC1155WETHMultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC1155WETHMultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        uint256 value = _orderValue(tradeData[0], WETH_GOERLI);
        tokenTransfers[0] = TokenTransfer({amount: value, currency: WETH_GOERLI});

        IERC20(WETH_GOERLI).approve(address(erc20EnabledLooksRareAggregator), value);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledLooksRareAggregator.execute(tokenTransfers, tradeData, _buyer, isAtomic);

        _assertERC1155OwnershipChangedHands();
        _assertWETHChangedHands(value);
    }

    function _testExecuteMultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateMultipleMakerAsksTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = _orderValue(tradeData[0], address(0));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        _assertERC721OwnershipChangedHands();
        _assertERC1155OwnershipChangedHands();
        _assertETHChangedHands(value);
    }

    function _testExecuteWETHMultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateWETHMultipleMakerAsksTradeData();
        uint256 value = _orderValue(tradeData[0], WETH_GOERLI);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0] = TokenTransfer({amount: value, currency: WETH_GOERLI});

        IERC20(WETH_GOERLI).approve(address(erc20EnabledLooksRareAggregator), value);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledLooksRareAggregator.execute(tokenTransfers, tradeData, _buyer, isAtomic);

        _assertERC721OwnershipChangedHands();
        _assertERC1155OwnershipChangedHands();
        _assertWETHChangedHands(value);
    }

    function _testExecuteMixedCurrenciesMultipleMakerAsks(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateMixedCurrenciesMultipleMakerAsksTradeData();

        uint256 ethValue = _orderValue(tradeData[0], address(0));
        uint256 wethValue = _orderValue(tradeData[0], WETH_GOERLI);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0] = TokenTransfer({amount: wethValue, currency: WETH_GOERLI});

        IERC20(WETH_GOERLI).approve(address(erc20EnabledLooksRareAggregator), wethValue);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});

        emit Sweep(_buyer);
        erc20EnabledLooksRareAggregator.execute{value: ethValue}(tokenTransfers, tradeData, _buyer, isAtomic);

        _assertERC721OwnershipChangedHands();
        _assertERC1155OwnershipChangedHands();
        _assertWETHChangedHands(wethValue);
        _assertETHChangedHands(ethValue);
    }

    function _generateERC721SingleMakerAskTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validGoerliTestERC721Orders()[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC721MultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = validGoerliTestERC721Orders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 1});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC1155SingleMakerAskTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validGoerliTestERC1155Orders()[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 2});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC1155MultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = validGoerliTestERC1155Orders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 2});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 3});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC721WETHSingleMakerAskTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validGoerliTestERC721WETHOrders()[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC721WETHMultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = validGoerliTestERC721WETHOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 1});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC1155WETHSingleMakerAskTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validGoerliTestERC1155WETHOrders()[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 2});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateERC1155WETHMultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = validGoerliTestERC1155WETHOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 2});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 3});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateMultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory erc721Orders = validGoerliTestERC721Orders();
        BasicOrder[] memory erc1155Orders = validGoerliTestERC1155Orders();
        BasicOrder[] memory orders = new BasicOrder[](4);
        orders[0] = erc721Orders[0];
        orders[1] = erc721Orders[1];
        orders[2] = erc1155Orders[0];
        orders[3] = erc1155Orders[1];

        bytes[] memory ordersExtraData = new bytes[](4);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 1});
        ordersExtraData[2] = _orderExtraData({price: orders[2].price, orderNonce: 2});
        ordersExtraData[3] = _orderExtraData({price: orders[3].price, orderNonce: 3});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateWETHMultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory erc721Orders = validGoerliTestERC721WETHOrders();
        BasicOrder[] memory erc1155Orders = validGoerliTestERC1155WETHOrders();
        BasicOrder[] memory orders = new BasicOrder[](4);
        orders[0] = erc721Orders[0];
        orders[1] = erc721Orders[1];
        orders[2] = erc1155Orders[0];
        orders[3] = erc1155Orders[1];

        bytes[] memory ordersExtraData = new bytes[](4);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 1});
        ordersExtraData[2] = _orderExtraData({price: orders[2].price, orderNonce: 2});
        ordersExtraData[3] = _orderExtraData({price: orders[3].price, orderNonce: 3});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _generateMixedCurrenciesMultipleMakerAsksTradeData()
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory erc721Orders = validGoerliTestERC721Orders();
        BasicOrder[] memory erc1155Orders = validGoerliTestERC1155WETHOrders();
        BasicOrder[] memory orders = new BasicOrder[](4);
        orders[0] = erc721Orders[0];
        orders[1] = erc1155Orders[0];
        orders[2] = erc721Orders[1];
        orders[3] = erc1155Orders[1];

        bytes[] memory ordersExtraData = new bytes[](4);
        ordersExtraData[0] = _orderExtraData({price: orders[0].price, orderNonce: 0});
        ordersExtraData[1] = _orderExtraData({price: orders[1].price, orderNonce: 2});
        ordersExtraData[2] = _orderExtraData({price: orders[2].price, orderNonce: 1});
        ordersExtraData[3] = _orderExtraData({price: orders[3].price, orderNonce: 3});

        tradeData = _tradeData(orders, ordersExtraData);
    }

    function _orderValue(ILooksRareAggregator.TradeData memory tradeData, address currency)
        private
        pure
        returns (uint256 value)
    {
        BasicOrder[] memory orders = tradeData.orders;
        uint256 length = orders.length;
        for (uint256 i; i < length; i++) {
            if (orders[i].currency == currency) {
                value += orders[i].price;
            }
        }
    }

    function _tradeData(BasicOrder[] memory orders, bytes[] memory ordersExtraData)
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareV2Proxy),
            selector: LooksRareV2Proxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: abi.encode(address(0)) // affiliate
        });
    }

    function _orderExtraData(uint256 price, uint256 orderNonce) private pure returns (bytes memory) {
        MerkleTree memory merkleTree;
        return
            abi.encode(
                LooksRareV2Proxy.OrderExtraData({
                    merkleTree: merkleTree,
                    globalNonce: 0,
                    subsetNonce: 0,
                    orderNonce: orderNonce,
                    strategyId: 0,
                    price: price,
                    takerBidAdditionalParameters: new bytes(0),
                    makerAskAdditionalParameters: new bytes(0)
                })
            );
    }

    function _assertERC721OwnershipChangedHands() private {
        assertEq(IERC721(MULTIFAUCET_NFT).balanceOf(_buyer), 3);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828266), _buyer);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828267), _buyer);
        assertEq(IERC721(MULTIFAUCET_NFT).ownerOf(2828268), _buyer);
    }

    function _assertERC1155OwnershipChangedHands() private {
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 69), 5);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 420), 5);
    }

    function _assertETHChangedHands(uint256 value) private {
        assertEq(_buyer.balance, 200 ether - value);
        assertEq(address(NFT_OWNER).balance, 200 ether + (value * 9_800) / 10_000);
    }

    function _assertWETHChangedHands(uint256 value) private {
        assertEq(IERC20(WETH_GOERLI).balanceOf(_buyer), 200 ether - value);
        assertEq(IERC20(WETH_GOERLI).balanceOf(NFT_OWNER), 200 ether + (value * 9_800) / 10_000);
    }
}
