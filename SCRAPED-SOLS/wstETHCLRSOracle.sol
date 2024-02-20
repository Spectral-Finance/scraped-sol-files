// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { FluidOracle } from "../fluidOracle.sol";
import { WstETHOracleImpl } from "../implementations/wstETHOracleImpl.sol";
import { FallbackOracleImpl } from "../implementations/fallbackOracleImpl.sol";
import { IWstETH } from "../interfaces/external/IWstETH.sol";
import { ChainlinkOracleImpl } from "../implementations/chainlinkOracleImpl.sol";
import { IRedstoneOracle } from "../interfaces/external/IRedstoneOracle.sol";
import { OracleUtils } from "../libraries/oracleUtils.sol";
import { ErrorTypes } from "../errorTypes.sol";

/// @title   WstETH Chainlink / Redstone Oracle (with fallback)
/// @notice  Gets the exchange rate between the underlying asset and the peg asset by using:
///          wstETH Oracle price in combination with rate from Chainlink price feeds (or Redstone as fallback),
///          hopping the 2 rates into 1 rate.
///          e.g. when going from wstETH to USDT:
///          wstETH -> stETH wstETH Oracle, stETH -> ETH Chainlink feed, ETH -> USDT Chainlink feed.
contract WstETHCLRSOracle is FluidOracle, WstETHOracleImpl, FallbackOracleImpl {
    /// @notice                     sets the wstETH address, main source, Chainlink Oracle and Redstone Oracle data.
    /// @param wstETH_              address of the wstETH contract
    /// @param mainSource_          which oracle to use as main source: 1 = Chainlink, 2 = Redstone (other one is fallback).
    /// @param chainlinkParams_     chainlink Oracle constructor params struct.
    /// @param redstoneOracle_      Redstone Oracle data. (address can be set to zero address if using Chainlink only)
    constructor(
        IWstETH wstETH_,
        uint8 mainSource_,
        ChainlinkConstructorParams memory chainlinkParams_,
        RedstoneOracleData memory redstoneOracle_
    ) WstETHOracleImpl(wstETH_) FallbackOracleImpl(mainSource_, chainlinkParams_, redstoneOracle_) {}

    /// @inheritdoc FluidOracle
    function getExchangeRate() external view override returns (uint256 exchangeRate_) {
        exchangeRate_ = _getRateWithFallback();

        if (exchangeRate_ == 0) {
            // revert if fetched exchange rate is 0
            revert FluidOracleError(ErrorTypes.WstETHCLRSOracle__ExchangeRateZero);
        }

        return (_getWstETHExchangeRate() * exchangeRate_) / (10 ** OracleUtils.RATE_OUTPUT_DECIMALS);
    }

    /// @notice which oracle to use as main source: 1 = Chainlink, 2 = Redstone (other one is fallback).
    function FALLBACK_ORACLE_MAIN_SOURCE() public view returns (uint8) {
        return _FALLBACK_ORACLE_MAIN_SOURCE;
    }
}
