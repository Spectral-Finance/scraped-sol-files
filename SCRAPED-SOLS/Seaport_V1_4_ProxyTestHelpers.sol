// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {AdditionalRecipient, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";

/**
 * @notice Seaport orders helper contract
 */
abstract contract Seaport_V1_4_ProxyTestHelpers {
    address internal constant OFFERER = 0x7c741AD1dd7Ce77E88e7717De1cC20e3314b4F38;
    address internal constant FEES = 0x0000a26b00c1F0DF003000390027140000fAa719;
    address internal constant MULTIFAUCET_NFT = 0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b;
    address internal constant TEST_ERC1155 = 0x58c3c2547084CC1C94130D6fd750A3877c7Ca5D2;
    address internal constant SEAPORT = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    address private constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    function validTestERC1155Id0Order() internal pure returns (BasicOrder memory order) {
        return
            _validTestERC1155Order({
                tokenId: 0,
                amount: 2,
                price: 2 ether,
                currency: address(0),
                startTime: 1677856016,
                endTime: 1680530816,
                signature: hex"443e3787ec5c06880efe81467743a2c0756a1ad1937855a55b897ad5d743017f85dbea3f4ef6692581cadc972e1d03f7e22c6feba10a90094a6bc05a9ca753e1"
            });
    }

    function validTestERC1155Id420Order() internal pure returns (BasicOrder memory order) {
        return
            _validTestERC1155Order({
                tokenId: 420,
                amount: 3,
                price: 6 ether,
                currency: address(0),
                startTime: 1677859982,
                endTime: 1680534782,
                signature: hex"823a4f8ca92cb855c97845bc236b2824fdf89dd57009c06503406b6db0f81d457c3ef7610e8a5728d9509c9b2a33814f13973eeb953da5675e6f1084b5ea9f57"
            });
    }

    function validMultifaucetId2828267Order() internal pure returns (BasicOrder memory order) {
        return
            _validMultifaucetNFTOrder({
                tokenId: 2828267,
                price: 3 ether,
                currency: WETH_GOERLI,
                startTime: 1677846317,
                endTime: 1680521117,
                signature: hex"2c41838edbb10aaf552d6b80082153f3e1dd580f806be4c3e29f42bd7d576223e9d4f1ea094b49ad162088dd6c2b1a13425572497322d1b03fccfc2e2abeb2b1"
            });
    }

    function validMultifaucetId2828268Order() internal pure returns (BasicOrder memory order) {
        return
            _validMultifaucetNFTOrder({
                tokenId: 2828268,
                price: 2 ether,
                currency: address(0),
                startTime: 1677843106,
                endTime: 1680517906,
                signature: hex"788cc332bec33bdf52e3506ef727a6e33c1ef583d6ee8323cabd4c055f4a3bbef6fb259264fdae65fbc00c80292e85b60d51c8dd6a496d448ad224b12a4aebd1"
            });
    }

    function validMultifaucetId2828269Order() internal pure returns (BasicOrder memory order) {
        return
            _validMultifaucetNFTOrder({
                tokenId: 2828269,
                price: 4 ether,
                currency: WETH_GOERLI,
                startTime: 1677854116,
                endTime: 1680528916,
                signature: hex"a502918ef738ffa861464535c51296f1119d3f8f092f90dc4836b728d81368c48eb33aed6fcd47fdc2b22fe16aae8ceca08ca04ca42c7adbd7eaa5827d3f284a"
            });
    }

    function validMultifaucetId2828270Order() internal pure returns (BasicOrder memory order) {
        return
            _validMultifaucetNFTOrder({
                tokenId: 2828270,
                price: 1 ether,
                currency: address(0),
                startTime: 1677842451,
                endTime: 1680517251,
                signature: hex"e73cfc9d62d01cc4b7ff5aa31e0632b5ccd8ff2dd010d31a1464306bd0b5a6bd6494e202edb2f16e085e0aa0573afa5213180453a4c312edad97e11f39826671"
            });
    }

    function validTestERC1155Id0OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = 1990000000000000000;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = 10000000000000000;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.salt = 0x360c6ebe0000000000000000000000000000000000000000a71d45560f4f77d7;
        orderExtraData.recipients = recipients;

        orderExtraData.numerator = 2;
        orderExtraData.denominator = 2;
        orderExtraData.orderType = OrderType.PARTIAL_OPEN;
        orderExtraData.zone = address(0);
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

        return abi.encode(orderExtraData);
    }

    function validTestERC1155Id420OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = 5970000000000000000;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = 30000000000000000;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.salt = 0x360c6ebe0000000000000000000000000000000000000000bb826b59d5b48174;
        orderExtraData.recipients = recipients;

        orderExtraData.numerator = 3;
        orderExtraData.denominator = 3;
        orderExtraData.orderType = OrderType.PARTIAL_OPEN;
        orderExtraData.zone = address(0);
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

        return abi.encode(orderExtraData);
    }

    function validMultifaucetId2828267OrderExtraData() internal pure returns (bytes memory) {
        return
            _validMultifaucetNFTOrderExtraData({
                amount0: 2985000000000000000,
                amount1: 15000000000000000,
                salt: 0x360c6ebe0000000000000000000000000000000000000000b6397b96d24fe3df
            });
    }

    function validMultifaucetId2828268OrderExtraData() internal pure returns (bytes memory) {
        return
            _validMultifaucetNFTOrderExtraData({
                amount0: 1990000000000000000,
                amount1: 10000000000000000,
                salt: 0x360c6ebe00000000000000000000000000000000000000004d531ffe9843708d
            });
    }

    function validMultifaucetId2828269OrderExtraData() internal pure returns (bytes memory) {
        return
            _validMultifaucetNFTOrderExtraData({
                amount0: 3980000000000000000,
                amount1: 20000000000000000,
                salt: 0x360c6ebe0000000000000000000000000000000000000000defce98e0fd2e9a8
            });
    }

    function validMultifaucetId2828270OrderExtraData() internal pure returns (bytes memory) {
        return
            _validMultifaucetNFTOrderExtraData({
                amount0: 995000000000000000,
                amount1: 5000000000000000,
                salt: 0x360c6ebe00000000000000000000000000000000000000007bb02b6dac7688cf
            });
    }

    function _baseOrderExtraData() private pure returns (SeaportProxy.OrderExtraData memory orderExtraData) {
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_OPEN;
        orderExtraData.zone = address(0);
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
    }

    function validMultipleItemsSameCollectionExtraData() internal pure returns (bytes memory) {
        SeaportProxy.ExtraData memory extraData;

        extraData.offerFulfillments = validMultipleOfferFulfillments(2);
        extraData.considerationFulfillments = validMultipleConsiderationFulfillments();

        return abi.encode(extraData);
    }

    function validMultipleOfferFulfillments(uint256 numberOfOffers)
        internal
        pure
        returns (FulfillmentComponent[][] memory offerFulfillments)
    {
        offerFulfillments = new FulfillmentComponent[][](numberOfOffers);

        for (uint256 i; i < numberOfOffers; ) {
            offerFulfillments[i] = new FulfillmentComponent[](1);
            offerFulfillments[i][0].orderIndex = i;
            offerFulfillments[i][0].itemIndex = 0;

            unchecked {
                ++i;
            }
        }
    }

    function validMultipleConsiderationFulfillments()
        internal
        pure
        returns (FulfillmentComponent[][] memory considerationFulfillments)
    {
        considerationFulfillments = new FulfillmentComponent[][](4);

        considerationFulfillments[0] = new FulfillmentComponent[](1);
        considerationFulfillments[0][0].orderIndex = 0;
        considerationFulfillments[0][0].itemIndex = 0;

        considerationFulfillments[1] = new FulfillmentComponent[](1);
        considerationFulfillments[1][0].orderIndex = 1;
        considerationFulfillments[1][0].itemIndex = 0;

        considerationFulfillments[2] = new FulfillmentComponent[](2);
        considerationFulfillments[2][0].orderIndex = 0;
        considerationFulfillments[2][0].itemIndex = 1;
        considerationFulfillments[2][1].orderIndex = 1;
        considerationFulfillments[2][1].itemIndex = 1;

        considerationFulfillments[3] = new FulfillmentComponent[](2);
        considerationFulfillments[3][0].orderIndex = 0;
        considerationFulfillments[3][0].itemIndex = 2;
        considerationFulfillments[3][1].orderIndex = 1;
        considerationFulfillments[3][1].itemIndex = 2;
    }

    function validMultipleCollectionsExtraData() internal pure returns (bytes memory) {
        SeaportProxy.ExtraData memory extraData;

        extraData.offerFulfillments = validMultipleOfferFulfillments(2);
        extraData.considerationFulfillments = validMultipleCollectionsConsiderationFulfillments();

        return abi.encode(extraData);
    }

    function validMultipleCollectionsConsiderationFulfillments()
        internal
        pure
        returns (FulfillmentComponent[][] memory considerationFulfillments)
    {
        considerationFulfillments = new FulfillmentComponent[][](5);

        considerationFulfillments[0] = new FulfillmentComponent[](1);
        considerationFulfillments[0][0].orderIndex = 0;
        considerationFulfillments[0][0].itemIndex = 0;

        considerationFulfillments[1] = new FulfillmentComponent[](1);
        considerationFulfillments[1][0].orderIndex = 1;
        considerationFulfillments[1][0].itemIndex = 0;

        considerationFulfillments[2] = new FulfillmentComponent[](2);
        considerationFulfillments[2][0].orderIndex = 0;
        considerationFulfillments[2][0].itemIndex = 1;
        considerationFulfillments[2][1].orderIndex = 1;
        considerationFulfillments[2][1].itemIndex = 1;

        considerationFulfillments[3] = new FulfillmentComponent[](1);
        considerationFulfillments[3][0].orderIndex = 0;
        considerationFulfillments[3][0].itemIndex = 2;

        considerationFulfillments[4] = new FulfillmentComponent[](1);
        considerationFulfillments[4][0].orderIndex = 1;
        considerationFulfillments[4][0].itemIndex = 2;
    }

    function validMultipleItemsSameCollectionMultipleCurrenciesExtraData() internal pure returns (bytes memory) {
        SeaportProxy.ExtraData memory extraData;

        extraData.offerFulfillments = validMultipleOfferFulfillments(2);
        extraData.considerationFulfillments = validMultipleCurrenciesConsiderationFulfillments();

        return abi.encode(extraData);
    }

    function validMultipleCurrenciesConsiderationFulfillments()
        internal
        pure
        returns (FulfillmentComponent[][] memory considerationFulfillments)
    {
        considerationFulfillments = new FulfillmentComponent[][](6);

        considerationFulfillments[0] = new FulfillmentComponent[](1);
        considerationFulfillments[0][0].orderIndex = 0;
        considerationFulfillments[0][0].itemIndex = 0;

        considerationFulfillments[1] = new FulfillmentComponent[](1);
        considerationFulfillments[1][0].orderIndex = 1;
        considerationFulfillments[1][0].itemIndex = 0;

        considerationFulfillments[2] = new FulfillmentComponent[](1);
        considerationFulfillments[2][0].orderIndex = 0;
        considerationFulfillments[2][0].itemIndex = 1;

        considerationFulfillments[3] = new FulfillmentComponent[](1);
        considerationFulfillments[3][0].orderIndex = 1;
        considerationFulfillments[3][0].itemIndex = 1;

        considerationFulfillments[4] = new FulfillmentComponent[](1);
        considerationFulfillments[4][0].orderIndex = 0;
        considerationFulfillments[4][0].itemIndex = 2;

        considerationFulfillments[5] = new FulfillmentComponent[](1);
        considerationFulfillments[5][0].orderIndex = 1;
        considerationFulfillments[5][0].itemIndex = 2;
    }

    function _validMultifaucetNFTOrder(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint256 startTime,
        uint256 endTime,
        bytes memory signature
    ) private pure returns (BasicOrder memory order) {
        order.signer = OFFERER;
        order.collection = MULTIFAUCET_NFT;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = price;
        order.currency = currency;
        order.startTime = startTime;
        order.endTime = endTime;
        order.signature = signature;
    }

    function _validTestERC1155Order(
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address currency,
        uint256 startTime,
        uint256 endTime,
        bytes memory signature
    ) private pure returns (BasicOrder memory order) {
        order.signer = OFFERER;
        order.collection = TEST_ERC1155;
        order.collectionType = CollectionType.ERC1155;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        order.amounts = amounts;

        order.price = price;
        order.currency = currency;
        order.startTime = startTime;
        order.endTime = endTime;
        order.signature = signature;
    }

    function _validMultifaucetNFTOrderExtraData(
        uint256 amount0,
        uint256 amount1,
        uint256 salt
    ) internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = amount0;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = amount1;

        SeaportProxy.OrderExtraData memory orderExtraData = _baseOrderExtraData();
        orderExtraData.salt = salt;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }
}
