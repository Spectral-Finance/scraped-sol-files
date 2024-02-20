// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SudoswapProxy} from "../../contracts/proxies/SudoswapProxy.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";

contract SudoswapProxyTest is TestParameters, TestHelpers {
    SudoswapProxy private sudoswapProxy;

    function setUp() public {
        sudoswapProxy = new SudoswapProxy(SUDOSWAP, _fakeAggregator);
        vm.deal(_buyer, 100 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.etch(_fakeAggregator, address(sudoswapProxy).code);
        vm.expectRevert(InvalidOrderLength.selector);
        IProxy(_fakeAggregator).execute(orders, ordersExtraData, "", _buyer, false);
    }

    function validMoodieOrder() private pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](1);
        orders[0].signer = address(0);
        orders[0].collection = MOODIE;
        orders[0].collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 5536;
        orders[0].tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;

        orders[0].price = 221649999999999993;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 0;
        orders[0].signature = "";
    }
}
