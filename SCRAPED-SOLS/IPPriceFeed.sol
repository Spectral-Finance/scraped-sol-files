// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IPPriceFeed {
    function getPrice() external view returns (uint256);
}
