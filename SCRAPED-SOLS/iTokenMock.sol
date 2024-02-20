//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { iToken } from "../../../../contracts/protocols/lending/iToken/main.sol";
import { ILiquidity } from "../../../../contracts/liquidity/interfaces/iLiquidity.sol";
import { ILendingFactory } from "../../../../contracts/protocols/lending/interfaces/iLendingFactory.sol";
import { LendingRewardsRateModel } from "../../../../contracts/protocols/lending/lendingRewardsRateModel/main.sol";

contract iTokenEIP2612Mock is iToken {
    constructor(
        ILiquidity liquidity_,
        ILendingFactory lendingFactory_,
        IERC20 asset_
    ) iToken(liquidity_, lendingFactory_, asset_) {}

    function updateRates(uint256 liquidityExchangePrice_) external returns (uint256 tokenExchangePrice_) {
        return _updateRates(liquidityExchangePrice_, false);
    }

    function getTokenExchangePrice() public view returns (uint256) {
        return _tokenExchangePrice;
    }
}
