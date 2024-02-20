// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";

/**
 * @notice LooksRare V2 orders helper contract
 */
abstract contract LooksRareV2ProxyTestHelpers {
    address internal constant NFT_OWNER = 0x7c741AD1dd7Ce77E88e7717De1cC20e3314b4F38;
    address internal constant MULTIFAUCET_NFT = 0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b;
    address internal constant TEST_ERC1155 = 0x58c3c2547084CC1C94130D6fd750A3877c7Ca5D2;
    address private constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    function validGoerliTestERC721Orders() internal pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        orders[0].signer = NFT_OWNER;
        orders[0].collection = MULTIFAUCET_NFT;
        orders[0].collectionType = CollectionType.ERC721;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2828266;
        orders[0].tokenIds = tokenIds;
        orders[0].amounts = amounts;
        orders[0].price = 1 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 1677166047;
        orders[0].endTime = 1679796047;
        orders[0]
            .signature = hex"23d3fc4ef6d68c7b686db297cef3e56c1b78970af6b02e659120a4c8bee0fea70acd6ea0107b5084e15bf79d042348a0099167b7cb7c52af0fbe11fe962344621c";

        amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        orders[1].signer = NFT_OWNER;
        orders[1].collection = MULTIFAUCET_NFT;
        orders[1].collectionType = CollectionType.ERC721;
        tokenIds = new uint256[](2);
        tokenIds[0] = 2828267;
        tokenIds[1] = 2828268;
        orders[1].tokenIds = tokenIds;
        orders[1].amounts = amounts;
        orders[1].price = 2 ether;
        orders[1].currency = address(0);
        orders[1].startTime = 1677166047;
        orders[1].endTime = 1679796047;
        orders[1]
            .signature = hex"568fe6f12e1ed49351e34c393ff075b4ddf25e093e3f03a8d3f19aaba1d0047d5ede2047093d0d2237b77e3e0c72019fc97877ccccf0f70306f7174a2aff55351b";
    }

    function validGoerliTestERC1155Orders() internal pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5;

        orders[0].signer = NFT_OWNER;
        orders[0].collection = TEST_ERC1155;
        orders[0].collectionType = CollectionType.ERC1155;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 69;
        orders[0].tokenIds = tokenIds;
        orders[0].amounts = amounts;
        orders[0].price = 1 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 1677166047;
        orders[0].endTime = 1679796047;
        orders[0]
            .signature = hex"37be2cc97492f3f2cc4acf0f4355b686fb3278bea04e8b7402364ae836455d0d015df879228f9baba5efdac5f99837e91b0eca3cb5267139609b74c59f86ceba1b";

        orders[1].signer = NFT_OWNER;
        orders[1].collection = TEST_ERC1155;
        orders[1].collectionType = CollectionType.ERC1155;
        tokenIds = new uint256[](1);
        tokenIds[0] = 420;
        orders[1].tokenIds = tokenIds;
        orders[1].amounts = amounts;
        orders[1].price = 2 ether;
        orders[1].currency = address(0);
        orders[1].startTime = 1677166047;
        orders[1].endTime = 1679796047;
        orders[1]
            .signature = hex"6b42188574e6565eed6b3d005cb16257e8949bd2ee02dc6be91a4945e1d0fd8d20e072b3679ee5969663321bd170526b43b1b9b5f14ce18e20dc48ecf0c2c7581c";
    }

    function validGoerliTestERC721WETHOrders() internal pure returns (BasicOrder[] memory orders) {
        orders = validGoerliTestERC721Orders();

        orders[0].currency = WETH_GOERLI;
        orders[0]
            .signature = hex"1f83beb857d1f66a25d127aa6a0eeb3f2061267fb97211435c4029faebd892aa4480d9bfb464a97ed75ca3834de7bff247bc72b6fe283eda323b4d733a66c0961c";

        orders[1].currency = WETH_GOERLI;
        orders[1]
            .signature = hex"fee7ca593ffd6166c78c2c1f8b1545176f1dc54c19734be28d1ddd6bd2f60c022f28daab71775dd28201893954296810a634fb7957ebe9be0781f11f4c283dfc1b";
    }

    function validGoerliTestERC1155WETHOrders() internal pure returns (BasicOrder[] memory orders) {
        orders = validGoerliTestERC1155Orders();

        orders[0].currency = WETH_GOERLI;
        orders[0]
            .signature = hex"2d0b804e00dc419d61057d73425464c357de4a1b16621d61c70b568ab2ee04165f7e1a92f3383eca70c7a5972766518614088cc2d99c4524e9c6ec027f7b74cd1c";

        orders[1].currency = WETH_GOERLI;
        orders[1]
            .signature = hex"0682b145af4981e9a865ce767e57f46401f7fb75b98ab713dd37c9f803bd576932d14ee8bb652335115fee341f8d5badfae160177fca92bc606275a0875621731c";
    }
}
