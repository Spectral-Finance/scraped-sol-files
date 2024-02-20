// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";

/**
 * @notice LooksRare orders helper contract
 */
abstract contract LooksRareProxyTestHelpers {
    address private constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function validBAYCOrders() internal pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        orders[0].signer = 0x2137213d50207Edfd92bCf4CF7eF9E491A155357;
        orders[0].collection = BAYC;
        orders[0].collectionType = CollectionType.ERC721;
        uint256[] memory orderOneTokenIds = new uint256[](1);
        orderOneTokenIds[0] = 7139;
        orders[0].tokenIds = orderOneTokenIds;
        orders[0].amounts = amounts;
        orders[0].price = 81.8 ether;
        orders[0].currency = WETH;
        orders[0].startTime = 1659632508;
        orders[0].endTime = 1662186976;
        orders[0]
            .signature = hex"e669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c";

        orders[1].signer = 0xaf0f4479aF9Df756b9b2c69B463214B9a3346443;
        orders[1].collection = BAYC;
        orders[1].collectionType = CollectionType.ERC721;
        uint256[] memory orderTwoTokenIds = new uint256[](1);
        orderTwoTokenIds[0] = 3939;
        orders[1].tokenIds = orderTwoTokenIds;
        orders[1].amounts = amounts;
        orders[1].price = 83.391 ether;
        orders[1].currency = WETH;
        orders[1].startTime = 1659484473;
        orders[1].endTime = 1660089268;
        orders[1]
            .signature = hex"146a8f500fea9cde68c339da9abe8654ffb60c5a80506532e3500d1edba687640519093ff36ab3a728c961fc763d6e6a107ed823cfa5bd45182cab8029dab5d21b";
    }

    function validBAYCId9483Order() internal pure returns (BasicOrder memory order) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        order.signer = 0x17331428346E388f32013e6bEc0Aba29303857FD;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 9483;
        order.tokenIds = tokenIds;
        order.amounts = amounts;
        order.price = 73.88 ether;
        order.currency = WETH;
        order.startTime = 1662683712;
        order.endTime = 1663288508;
        order
            .signature = hex"137b835f53750e28c2ca2c14686206fc1b5e44b47b22f619ae35ac7e661de1fa2d22c786fd897ad08ae30113d1a8804e2313b6410438ba9187e14e94ef25e4671c";
    }

    function validBAYCId3569Order() internal pure returns (BasicOrder memory order) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        order.signer = 0x290dC64Bd6B079d0Fe41c8383D720938Bfa69cB1;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 3569;
        order.tokenIds = tokenIds;
        order.amounts = amounts;
        order.price = 74 ether;
        order.currency = WETH;
        order.startTime = 1662522412;
        order.endTime = 1664367698;
        order
            .signature = hex"c0b72a9fc4068e489c0464b44c6e93ff28c24e30bb2ff1776d6afbc23d8235e75d4c996bf069c445133dcdc01dd1615fedfbb4a3e43fc539d5795215baf767101b";
    }

    function validSlicesOrder() internal pure returns (BasicOrder memory order) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        order.signer = 0x3A8713065e4DAa9603b91Ef35d6a8336eF7b26C6;
        order.collection = 0x5150B29a431eCe5eB0e62085535b8aaC8df193bE;
        order.collectionType = CollectionType.ERC1155;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        order.tokenIds = tokenIds;
        order.amounts = amounts;
        order.price = 0.01 ether;
        order.currency = WETH;
        order.startTime = 1667292639;
        order.endTime = 1669888235;
        order
            .signature = hex"f5e65638475e7387b9cc84a8dc52963e02ae2bd25a5f4b6f35a285fbf3e41e7c2c080d2e2b8293db1a824b1528691838996429a2d3d6062ea50d253cc33829661c";
    }

    function validGoerliTestERC1155Order() internal pure returns (BasicOrder memory order) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2;

        order.signer = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
        order.collection = 0x58c3c2547084CC1C94130D6fd750A3877c7Ca5D2;
        order.collectionType = CollectionType.ERC1155;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        order.tokenIds = tokenIds;
        order.amounts = amounts;
        order.price = 1 ether;
        order.currency = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        order.startTime = 1668190971;
        order.endTime = 1668277371;
        order
            .signature = hex"b93d585da923afba40af2304fd46cd4f740187b0f6f9b06fbe7409627e9301f15ee3fd2ea3f132d141ea3dfc41539946b9665b17bd16b6d7b264af9a94de779c1b";
    }

    function validCryptoCoven1244Order() internal pure returns (BasicOrder memory order) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        order.signer = 0xfc27C589B33b7a52EB0a304d76c0544CA4B496E6;
        order.collection = 0x5180db8F5c931aaE63c74266b211F580155ecac8;
        order.collectionType = CollectionType.ERC721;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1244;
        order.tokenIds = tokenIds;
        order.amounts = amounts;
        order.price = 0.1814 ether;
        order.currency = WETH;
        order.startTime = 1668410867;
        order.endTime = 1671002867;
        order
            .signature = hex"08ae20d23fc4efda6ba409ab56a5619a9278c1edc75981a33166001cd9977b07728042faa31f8e945089361e97160af44406c557492d36dae053df3e6fd93f911c";
    }

    function validTwerky63Order() internal pure returns (BasicOrder memory order) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        order.signer = 0x8d894500675C860D86619cC77742b8Dca7eF74e2;
        order.collection = 0xf4680c917A873E2dd6eAd72f9f433e74EB9c623C;
        order.collectionType = CollectionType.ERC1155;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 63;
        order.tokenIds = tokenIds;
        order.amounts = amounts;
        order.price = 0.0995 ether;
        order.currency = WETH;
        order.startTime = 1668716386;
        order.endTime = 1684264772;
        order
            .signature = hex"3ea34f6e25acaeb57f2c043ee5d03213395919e09524d6c004f95f2917880bdc561af73fd982c5e1a1a8c96843a7a195a91a1e86f6952807161f01bba5708f8d1c";
    }
}
