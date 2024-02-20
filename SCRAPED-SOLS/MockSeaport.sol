// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FulfillmentComponent, Execution, AdvancedOrder, CriteriaResolver} from "../../../contracts/libraries/seaport/ConsiderationStructs.sol";

/**
 * @dev The only purpose of this mock contract for now is to test
 *      fulfillAvailableAdvancedOrders' failed case
 */
contract MockSeaport {
    /**
     * @dev Returns the availableOrders array with each element being false by default
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata,
        FulfillmentComponent[][] calldata,
        FulfillmentComponent[][] calldata,
        bytes32,
        address,
        uint256
    ) external payable returns (bool[] memory availableOrders, Execution[] memory executions) {
        uint256 length = advancedOrders.length;
        executions = new Execution[](length);
        availableOrders = new bool[](length);
    }
}
