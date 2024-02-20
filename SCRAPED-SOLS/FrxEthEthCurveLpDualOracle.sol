// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =================== FrxEthEthCurveLpDualOracle =====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import {
    ChainlinkOracleWithMaxDelay,
    ConstructorParams as ChainlinkOracleWithMaxDelayParams
} from "./abstracts/ChainlinkOracleWithMaxDelay.sol";
import {
    CurvePoolEmaPriceOracleWithMinMax,
    ConstructorParams as CurvePoolEmaPriceOracleWithMinMaxParams
} from "./abstracts/CurvePoolEmaPriceOracleWithMinMax.sol";
import {
    CurvePoolVirtualPriceOracleWithMinMax,
    ConstructorParams as CurvePoolVirtualPriceOracleWithMinMaxParams
} from "./abstracts/CurvePoolVirtualPriceOracleWithMinMax.sol";
import {
    EthUsdChainlinkOracleWithMaxDelay,
    ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams
} from "./abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import {
    UniswapV3SingleTwapOracle,
    ConstructorParams as UniswapV3SingleTwapOracleParams
} from "./abstracts/UniswapV3SingleTwapOracle.sol";
import { IDualOracle } from "interfaces/IDualOracle.sol";
import { DualOracleBase, ConstructorParams as DualOracleBaseParams } from "./DualOracleBase.sol";

struct ConstructorParams {
    address timelockAddress;
    address frxEthEthCurveLp;
    UniswapV3SingleTwapOracleParams frxEthFraxUniswapV3SingleTwapOracleParams;
    EthUsdChainlinkOracleWithMaxDelayParams ethUsdChainlinkOracleWithMaxDelayParams;
    CurvePoolEmaPriceOracleWithMinMaxParams frxEthEthCurvePoolEmaPriceOracleWithMinMaxParams;
    CurvePoolVirtualPriceOracleWithMinMaxParams frxEthEthCurvePoolVirtualPriceOracleWithMinMaxParams;
    ChainlinkOracleWithMaxDelayParams fraxUsdChainlinkOracleWithMaxDelayParams;
}

/// @title FrxEthEthCurveLpDualOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for frxEth prices
contract FrxEthEthCurveLpDualOracle is
    DualOracleBase,
    Timelock2Step,
    EthUsdChainlinkOracleWithMaxDelay,
    CurvePoolEmaPriceOracleWithMinMax,
    CurvePoolVirtualPriceOracleWithMinMax,
    UniswapV3SingleTwapOracle,
    ChainlinkOracleWithMaxDelay
{
    address public immutable FRXETH_ERC20;
    address public immutable FRAX_ERC20;

    constructor(
        ConstructorParams memory _params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: address(840),
                baseToken0Decimals: 18,
                quoteToken0: _params.frxEthEthCurveLp,
                quoteToken0Decimals: 18,
                baseToken1: address(840),
                baseToken1Decimals: 18,
                quoteToken1: _params.frxEthEthCurveLp,
                quoteToken1Decimals: 18
            })
        )
        Timelock2Step()
        EthUsdChainlinkOracleWithMaxDelay(_params.ethUsdChainlinkOracleWithMaxDelayParams)
        CurvePoolEmaPriceOracleWithMinMax(_params.frxEthEthCurvePoolEmaPriceOracleWithMinMaxParams)
        CurvePoolVirtualPriceOracleWithMinMax(_params.frxEthEthCurvePoolVirtualPriceOracleWithMinMaxParams)
        UniswapV3SingleTwapOracle(_params.frxEthFraxUniswapV3SingleTwapOracleParams)
        ChainlinkOracleWithMaxDelay(_params.fraxUsdChainlinkOracleWithMaxDelayParams)
    {
        _setTimelock({ _newTimelock: _params.timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });

        // General config
        FRAX_ERC20 = _params.frxEthFraxUniswapV3SingleTwapOracleParams.baseToken;
        FRXETH_ERC20 = _params.frxEthFraxUniswapV3SingleTwapOracleParams.quoteToken;
    }

    // ====================================================================
    // View Helpers
    // ====================================================================
    function name() external pure returns (string memory) {
        return "FrxETH/ETH Curve LP Dual Oracle w/ Staleness & Min/Max Bounds";
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumEthUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setMinimumCurvePoolEma``` function sets the minimum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _minimumPrice The minimum price of frxEth in Ether units of the EMA
    function setMinimumCurvePoolEma(uint256 _minimumPrice) external override {
        _requireTimelock();
        _setMinimumCurvePoolEma({ _minimumPrice: _minimumPrice });
    }

    /// @notice The ```setMaximumCurvePoolEma``` function sets the maximum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _maximumPrice The maximum price of frxEth in Ether units of the EMA
    function setMaximumCurvePoolEma(uint256 _maximumPrice) external override {
        _requireTimelock();
        _setMaximumCurvePoolEma({ _maximumPrice: _maximumPrice });
    }

    /// @notice The ```setMinimumCurvePoolVirtualPrice``` function sets the minimum virtual price
    /// @dev Must be called by the timelock
    /// @param _newMinimum The new minimum virtual price
    function setMinimumCurvePoolVirtualPrice(uint256 _newMinimum) external override {
        _requireTimelock();
        _setMinimumCurvePoolVirtualPrice({ _newMinimum: _newMinimum });
    }

    /// @notice The ```setMaximumCurvePoolVirtualPrice``` function sets the maximum virtual price
    /// @dev Must be called by the timelock
    /// @param _newMaximum The new maximum virtual price
    function setMaximumCurvePoolVirtualPrice(uint256 _newMaximum) external override {
        _requireTimelock();
        _setMaximumCurvePoolVirtualPrice({ _newMaximum: _newMaximum });
    }

    /// @notice The ```setTwapDuration``` function sets the TWAP duration for the Uniswap V3 oracle
    /// @dev Must be called by the timelock
    /// @param _newTwapDuration The new TWAP duration
    function setTwapDuration(uint32 _newTwapDuration) external override {
        _requireTimelock();
        _setTwapDuration({ _newTwapDuration: _newTwapDuration });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getTwapFrxEthPerFrax``` function gets the TWAP price of frxEth in frax units
    /// @dev normalized to match precision of oracle
    /// @return _frxEthPerFrax
    function getTwapFrxEthPerFrax() public view returns (uint256 _frxEthPerFrax) {
        _frxEthPerFrax = ((ORACLE_PRECISION * _getUniswapV3Twap()) / TWAP_PRECISION);
    }

    /// @notice The ```getChainlinkUsdPerFrax``` function gets the Chainlink price of frax in usd units
    /// @dev normalized to match precision of oracle
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _usdPerFrax
    function getChainlinkUsdPerFrax() public view returns (bool _isBadData, uint256 _usdPerFrax) {
        (bool _isBadDataChainlink, , uint256 _chainlinkPriceRaw) = _getChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerFrax = (_chainlinkPriceRaw * (ORACLE_PRECISION / CHAINLINK_FEED_PRECISION));
    }

    /// @notice The ```getTwapFrxEthPerUsd``` function gets the TWAP price of frxEth in usd units
    /// @dev normalized to match precision of oracle, combined chainlink with twap
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _twapFrxEthPerUsd The TWAP price of frxEth in usd units
    function getTwapFrxEthPerUsd() public view returns (bool _isBadData, uint256 _twapFrxEthPerUsd) {
        (bool _isBadDataChainlink, uint256 _usdPerFrax) = getChainlinkUsdPerFrax();
        uint256 _twapFrxEthPerFrax = getTwapFrxEthPerFrax();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _twapFrxEthPerUsd = (ORACLE_PRECISION * _twapFrxEthPerFrax) / _usdPerFrax;
    }

    /// @notice The ```getChainlinkUsdPerEth``` function gets the Chainlink price of eth in usd units
    /// @dev normalized to match precision of oracle
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _usdPerEth
    function getChainlinkUsdPerEth() public view returns (bool _isBadData, uint256 _usdPerEth) {
        (bool _isBadDataChainlink, , uint256 _usdEthPerRaw) = _getEthUsdChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerEth = (ORACLE_PRECISION * _usdEthPerRaw) / ETH_USD_CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getCurveEmaEthPerFrxEth``` function gets the EMA price of frxEth in eth units
    /// @dev normalized to match precision of oracle
    /// @return _ethPerFrxEth
    function getCurveEmaEthPerFrxEth() public view returns (uint256 _ethPerFrxEth) {
        uint256 _ethPerFrxEthRaw = _getCurvePoolToken1EmaPrice();

        _ethPerFrxEth = (ORACLE_PRECISION * _ethPerFrxEthRaw) / CURVE_POOL_EMA_PRICE_ORACLE_PRECISION;
    }

    /// @notice The ```getFrxEthEthCurvePoolVirtualPrice``` function gets the virtual price from the curve pool
    /// @dev normalized to match precision of oracle
    /// @return _virtualPrice
    function getFrxEthEthCurvePoolVirtualPrice() public view returns (uint256 _virtualPrice) {
        uint256 _virtualPriceRaw = _getCurvePoolVirtualPrice();

        _virtualPrice = (ORACLE_PRECISION * _virtualPriceRaw) / CURVE_POOL_VIRTUAL_PRICE_PRECISION;
    }

    /// @notice The ```getCurveEmaFrxEthPerUsd``` function gets the EMA price of frxEth in usd units
    /// @dev normalized to match precision of oracle
    /// @param _usdPerEth The price of eth in usd units
    /// @return _curveEmaFrxEthPerUsd
    function getCurveEmaFrxEthPerUsd(uint256 _usdPerEth) public view returns (uint256 _curveEmaFrxEthPerUsd) {
        uint256 _ethPerFrxEth = getCurveEmaEthPerFrxEth();

        _curveEmaFrxEthPerUsd = (ORACLE_PRECISION * ORACLE_PRECISION * ORACLE_PRECISION) / (_ethPerFrxEth * _usdPerEth);
    }

    /// @notice The ```calculatePrices``` function is a pure function to calculate the prices using arbitrary inputs, mainly for testing
    /// @param _isBadDataEthUsdChainlink Whether the Chainlink data is stale
    /// @param _chainlinkUsdPerEth The Chainlink price of eth in usd units
    /// @param _isBadDataTwap Whether the TWAP data is stale
    /// @param _twapFrxEthPerUsd The TWAP price of frxEth in usd units
    /// @param _virtualPrice The virtual price from the curve pool
    /// @param _curveEmaFrxEthPerUsd The EMA price of frxEth in usd units
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _priceLow The lower price of frax in usd units
    /// @return _priceHigh The higher price of frax in usd units
    function calculatePrices(
        bool _isBadDataEthUsdChainlink,
        uint256 _chainlinkUsdPerEth,
        bool _isBadDataTwap,
        uint256 _twapFrxEthPerUsd,
        uint256 _virtualPrice,
        uint256 _curveEmaFrxEthPerUsd
    ) external pure returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        return
            _calculatePrices({
                _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
                _chainlinkUsdPerEth: _chainlinkUsdPerEth,
                _isBadDataTwap: _isBadDataTwap,
                _twapFrxEthPerUsd: _twapFrxEthPerUsd,
                _virtualPrice: _virtualPrice,
                _curveEmaFrxEthPerUsd: _curveEmaFrxEthPerUsd
            });
    }

    function _calculatePrices(
        bool _isBadDataEthUsdChainlink,
        uint256 _chainlinkUsdPerEth,
        bool _isBadDataTwap,
        uint256 _twapFrxEthPerUsd,
        uint256 _virtualPrice,
        uint256 _curveEmaFrxEthPerUsd
    ) internal pure returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 _chainlinkEthPerUsd = (ORACLE_PRECISION * ORACLE_PRECISION) / _chainlinkUsdPerEth;

        // Use the least valuable (higher number) of the tokens for value calculations
        // Because given in per USD, the higher the number, the less value the token has
        uint256 _underlyingPrice1 = _curveEmaFrxEthPerUsd > _chainlinkEthPerUsd
            ? _curveEmaFrxEthPerUsd
            : _chainlinkEthPerUsd;
        uint256 _underlyingPrice2 = _twapFrxEthPerUsd > _chainlinkEthPerUsd ? _twapFrxEthPerUsd : _chainlinkEthPerUsd;

        // Calculate the LP token price
        uint256 _lpTokenPerUsd1 = (_underlyingPrice1 * _virtualPrice) / ORACLE_PRECISION;
        uint256 _lpTokenPerUsd2 = (_underlyingPrice2 * _virtualPrice) / ORACLE_PRECISION;

        // Set return values
        _isBadData = _isBadDataEthUsdChainlink || _isBadDataTwap;
        _priceLow = _lpTokenPerUsd1 < _lpTokenPerUsd2 ? _lpTokenPerUsd1 : _lpTokenPerUsd2;
        _priceHigh = _lpTokenPerUsd1 < _lpTokenPerUsd2 ? _lpTokenPerUsd2 : _lpTokenPerUsd1;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when chainlink data is stale or negative
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (bool _isBadDataEthUsdChainlink, uint256 _chainlinkUsdPerEth) = getChainlinkUsdPerEth();
        (bool _isBadDataTwap, uint256 _twapFrxEthPerUsd) = getTwapFrxEthPerUsd();
        uint256 _virtualPrice = getFrxEthEthCurvePoolVirtualPrice();

        // Calculate curve EMA price
        uint256 _curveEmaFrxEthPerUsd = getCurveEmaFrxEthPerUsd({ _usdPerEth: _chainlinkUsdPerEth });

        // Calculate prices
        (_isBadData, _priceLow, _priceHigh) = _calculatePrices({
            _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
            _chainlinkUsdPerEth: _chainlinkUsdPerEth,
            _isBadDataTwap: _isBadDataTwap,
            _twapFrxEthPerUsd: _twapFrxEthPerUsd,
            _virtualPrice: _virtualPrice,
            _curveEmaFrxEthPerUsd: _curveEmaFrxEthPerUsd
        });
    }

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @return _isBadDataNormal If the Chainlink oracle is stale
    /// @return _priceLowNormal The normalized low price
    /// @return _priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        returns (bool _isBadDataNormal, uint256 _priceLowNormal, uint256 _priceHighNormal)
    {
        (bool _isBadDataEthUsdChainlink, uint256 _chainlinkUsdPerEth) = getChainlinkUsdPerEth();
        (bool _isBadDataTwap, uint256 _twapFrxEthPerUsd) = getTwapFrxEthPerUsd();
        uint256 _virtualPrice = getFrxEthEthCurvePoolVirtualPrice();

        // Calculate curve EMA price
        uint256 _curveEmaFrxEthPerUsd = getCurveEmaFrxEthPerUsd({ _usdPerEth: _chainlinkUsdPerEth });
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = _calculatePrices({
            _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
            _chainlinkUsdPerEth: _chainlinkUsdPerEth,
            _isBadDataTwap: _isBadDataTwap,
            _twapFrxEthPerUsd: _twapFrxEthPerUsd,
            _virtualPrice: _virtualPrice,
            _curveEmaFrxEthPerUsd: _curveEmaFrxEthPerUsd
        });

        // Set return values
        _isBadDataNormal = _isBadData;
        _priceLowNormal = NORMALIZATION_0 > 0
            ? _priceLow * 10 ** uint256(NORMALIZATION_0)
            : _priceLow / 10 ** (uint256(-NORMALIZATION_0));
        _priceHighNormal = NORMALIZATION_1 > 0
            ? _priceHigh * 10 ** uint256(NORMALIZATION_1)
            : _priceHigh / 10 ** (uint256(-NORMALIZATION_1));
    }
}
