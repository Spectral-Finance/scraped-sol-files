// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/x2y2/MarketConsts.sol";

interface IX2Y2 {
    function run(Market.RunInput memory input) external payable;
}
