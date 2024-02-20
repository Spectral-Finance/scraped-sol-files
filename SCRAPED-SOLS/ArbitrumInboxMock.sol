// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

contract ArbitrumInboxMock {
    address constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));
    Vm public constant vm = Vm(VM_ADDRESS);

    uint256 id = 0;

    function createRetryableTicket(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256) {
        // Oracle is expecting the caller address to be aliased by Arbitrum
        vm.prank(AddressAliasHelper.applyL1ToL2Alias(msg.sender));
        destAddr.call{value: l2CallValue}(data);
        return id++;
    }
}
