// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { FluidOracle } from "../fluidOracle.sol";
import { ChainlinkOracleImpl } from "../implementations/chainlinkOracleImpl.sol";
import { FallbackOracleImpl } from "../implementations/fallbackOracleImpl.sol";
import { UniV3OracleImpl } from "../implementations/uniV3OracleImpl.sol";
import { IChainlinkAggregatorV3 } from "../interfaces/external/IChainlinkAggregatorV3.sol";
import { IRedstoneOracle } from "../interfaces/external/IRedstoneOracle.sol";
import { ErrorTypes } from "../errorTypes.sol";
import { OracleUtils } from "../libraries/oracleUtils.sol";

/// @title   UniswapV3 checked against Chainlink / Redstone Oracle. Either one reported as exchange rate.
/// @notice  Gets the exchange rate between the underlying asset and the peg asset by using:
///          the price from a UniV3 pool (compared against 3 TWAPs) and (optionally) comparing it against a Chainlink
///          or Redstone price (one of Chainlink or Redstone being the main source and the other one the fallback source).
///          Alternatively it can also use Chainlink / Redstone as main price and use UniV3 as check price.
/// @dev     The process for getting the aggregate oracle price is:
///           1. Fetch the UniV3 TWAPS, the latest interval is used as the current price
///           2. Verify this price is within an acceptable DELTA from the Uniswap TWAPS e.g.:
///              a. 240 to 60s
///              b. 60 to 15s
///              c. 15 to 1s (last block)
///              d. 1 to 0s (current)
///           3. (unless UniV3 only mode): Verify this price is within an acceptable DELTA from the Chainlink / Redstone Oracle
///           4. If it passes all checks, return the price. Otherwise revert.
/// @dev     For UniV3 with check mode, if fetching the check price fails, the UniV3 rate is used directly.
contract UniV3CheckFallbackCLRSOracle is FluidOracle, UniV3OracleImpl, FallbackOracleImpl {
    /// @dev Rate check oracle delta percent in 1e2 percent. If current uniswap price is out of this delta,
    /// current price fetching reverts.
    uint256 internal immutable _RATE_CHECK_MAX_DELTA_PERCENT;

    /// @dev which oracle to use as final rate source:
    ///      - 1 = UniV3 ONLY (no check),
    ///      - 2 = UniV3 with Chainlink / Redstone check
    ///      - 3 = Chainlink / Redstone with UniV3 used as check.
    uint8 internal immutable _RATE_SOURCE;

    /// @param uniV3Params_                 UniV3Oracle constructor params struct.
    /// @param chainlinkParams_             ChainlinkOracle constructor params struct.
    /// @param redstoneOracle_              Redstone Oracle data. (address can be set to zero address if using Chainlink only)
    /// @param rateSource_                  which oracle to use as final rate source:
    ///                                         - 1 = UniV3 ONLY (no check),
    ///                                         - 2 = UniV3 with Chainlink / Redstone check
    ///                                         - 3 = Chainlink / Redstone with UniV3 used as check.
    /// @param fallbackMainSource_          which oracle to use as CL/RS main source: see FallbackOracleImpl constructor `mainSource_`
    /// @param rateCheckMaxDeltaPercent_    Rate check oracle delta in 1e2 percent
    constructor(
        UniV3ConstructorParams memory uniV3Params_,
        ChainlinkConstructorParams memory chainlinkParams_,
        RedstoneOracleData memory redstoneOracle_,
        uint8 rateSource_,
        uint8 fallbackMainSource_,
        uint256 rateCheckMaxDeltaPercent_
    ) UniV3OracleImpl(uniV3Params_) FallbackOracleImpl(fallbackMainSource_, chainlinkParams_, redstoneOracle_) {
        if (
            rateSource_ < 1 || rateSource_ > 3 || rateCheckMaxDeltaPercent_ > OracleUtils.HUNDRED_PERCENT_DELTA_SCALER
        ) {
            revert FluidOracleError(ErrorTypes.UniV3CheckFallbackCLRSOracle__InvalidParams);
        }

        _RATE_CHECK_MAX_DELTA_PERCENT = rateCheckMaxDeltaPercent_;
        _RATE_SOURCE = rateSource_;
    }

    /// @inheritdoc FluidOracle
    function getExchangeRate() external view override returns (uint256 exchangeRate_) {
        uint256 checkRate_;
        if (_RATE_SOURCE == 1) {
            // uniswap is the only main source without check
            return _getUniV3ExchangeRate();
        } else if (_RATE_SOURCE == 2) {
            // uniswap is main source, with check
            exchangeRate_ = _getUniV3ExchangeRate();
            checkRate_ = _getRateWithFallback();
            if (checkRate_ == 0) {
                // check price source failed to fetch -> directly use uniV3 TWAP checked price
                return exchangeRate_;
            }
        } else {
            // Chainlink / Redstone is main source.
            exchangeRate_ = _getRateWithFallback();
            if (exchangeRate_ == 0) {
                // main source failed to fetch -> revert
                revert FluidOracleError(ErrorTypes.UniV3CheckFallbackCLRSOracle__InvalidPrice);
            }

            checkRate_ = _getUniV3ExchangeRate();
        }

        if (OracleUtils.isRateOutsideDelta(exchangeRate_, checkRate_, _RATE_CHECK_MAX_DELTA_PERCENT)) {
            revert FluidOracleError(ErrorTypes.UniV3CheckFallbackCLRSOracle__InvalidPrice);
        }
    }

    /// @notice returns all oracle related data as utility for easy off-chain / block explorer use in a single view method
    function oracleData()
        public
        view
        returns (uint256 rateCheckMaxDelta_, uint256 rateSource_, uint256 fallbackMainSource_)
    {
        return (_RATE_CHECK_MAX_DELTA_PERCENT, _RATE_SOURCE, _FALLBACK_ORACLE_MAIN_SOURCE);
    }
}
