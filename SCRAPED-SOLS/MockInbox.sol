// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { AddressAliasHelper } from "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "frax-std/FraxTest.sol";

contract MockInbox is FraxTest {
    uint256 ticketId;

    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256 _ticketId) {
        _ticketId = ticketId;
        ticketId++;

        // Set msg.sender to expected in ArbitrumBlockHashProvider.receiveBlockHash()
        vm.prank(AddressAliasHelper.applyL1ToL2Alias(msg.sender));
        (bool success, bytes memory data) = to.call(data);

        if (!success) revert CallFailed();
    }

    error CallFailed();
}
