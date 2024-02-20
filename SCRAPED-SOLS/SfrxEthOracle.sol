// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== SfrxEthOracle ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "frax-std/access-control/v1/Timelock2Step.sol";
import "interfaces/IFrxEthStableSwap.sol";
import "interfaces/ISfrxEth.sol";

contract SfrxEthOracle is Timelock2Step, AggregatorV3Interface {
    using SafeCast for uint256;

    /// @notice The contract where rewards are accrued
    ISfrxEth public constant staker = ISfrxEth(0xac3E018457B222d93114458476f3E3416Abbe38F);

    /// @notice The precision of staker pricePerShare, given as 10^decimals
    uint256 public constant stakingPricePrecision = 1e18;

    /// @notice Curve pool, source of EMA for token
    IFrxEthStableSwap public constant pool = IFrxEthStableSwap(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577);

    /// @notice Chainlink aggregator
    AggregatorV3Interface public constant chainlinkFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /// @notice Decimals of ETH/USD chainlink feed
    uint8 public immutable chainlinkFeedDecimals;

    /// @notice Precision of ema oracle given as 10^decimals
    uint256 public immutable emaPrecision = 1e18;

    /// @notice Maximum price of frxEth in Ether units of the EAM
    /// @dev Must match precision of EMA
    uint256 public immutable emaMax = 1e18;

    /// @notice Minimum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of EMA
    uint256 public emaMin;

    // Metadata

    /// @notice Description of oracle, follows chainlink convention
    string public description = "sfrxETH / USD v2 with min/max bounds";

    /// @notice Decimals of precision for price data
    uint8 public constant decimals = 18;

    /// @notice Name of Oracle
    string public name = "Staked Frax Ether (USD) Oracle v2 (Chainlink + EMA with min/max bounds + ERC4626 sharePrice)";

    /// @notice Version of Oracle (matches chainlink convention)
    uint256 public constant version = 4;

    constructor(address _timelockAddress, uint256 _emaMin) Timelock2Step() {
        chainlinkFeedDecimals = AggregatorV3Interface(chainlinkFeed).decimals();
        _setTimelock(_timelockAddress);
        emaMin = _emaMin;
    }

    /// @notice The ```SetEmaMinimum``` event is emitted when the minimum price of frxEth in Ether units of the EMA is set
    /// @param oldMinimum The previous minimum price of frxEth in Ether units of the EMA
    /// @param newMinimum The new minimum price of frxEth in Ether units of the EMA
    event SetEmaMinimum(uint256 oldMinimum, uint256 newMinimum);

    /// @notice The ```setEmaMin``` function sets the minimum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _minPrice The minimum price of frxEth in Ether units of the EMA
    function setEmaMin(uint256 _minPrice) external {
        _requireTimelock();
        emit SetEmaMinimum(emaMin, _minPrice);
        emaMin = _minPrice;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        revert("getRoundData not implemented");
    }

    /// @notice The ```latestRoundData``` function returns the latest price and metadata for the oracle
    /// @dev Adheres to chainlink's AggregatorV3Interface
    /// @return roundId The round from the chainlinkFeed
    /// @return answer The price of sfrxEth in USD
    /// @return startedAt The timestamp of start of the update of the round from the chainlinkFeed
    /// @return updatedAt The timestamp of update of the round from the chainlinkFeed
    /// @return answeredInRound The round from the chainlinkFeed
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // tokenA Eth price in USD
        // tokenB frxEth price in ETH
        // tokenC sfrxEth price in frxEth

        int256 _tokenAPriceInt;
        (roundId, _tokenAPriceInt, startedAt, updatedAt, answeredInRound) = chainlinkFeed.latestRoundData();
        if (_tokenAPriceInt < 0) revert FeedPriceNegative();
        uint256 _tokenAPrice = uint256(_tokenAPriceInt);

        // price oracle gives token1 price in terms of token0 units
        uint256 _oraclePrice = pool.price_oracle();

        // Bound _tokenPrice
        uint256 _tokenBPriceRelative = _oraclePrice > emaMax ? emaMax : _oraclePrice;
        _tokenBPriceRelative = _tokenBPriceRelative < emaMin ? emaMin : _tokenBPriceRelative;

        uint256 _tokenCPriceInTokenB = staker.pricePerShare();

        uint256 _tokenAPriceScaled = (_tokenAPrice * (10 ** decimals)) / (10 ** chainlinkFeedDecimals);

        answer = ((_tokenCPriceInTokenB * _tokenBPriceRelative * _tokenAPriceScaled) /
            (emaPrecision * stakingPricePrecision)).toInt256();
    }

    error FeedPriceNegative();
}
