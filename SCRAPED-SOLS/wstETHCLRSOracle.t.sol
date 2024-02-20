//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test } from "forge-std/Test.sol";

import { IRedstoneOracle } from "../../../contracts/oracle/interfaces/external/IRedstoneOracle.sol";
import { IChainlinkAggregatorV3 } from "../../../contracts/oracle/interfaces/external/IChainlinkAggregatorV3.sol";
import { IWstETH } from "../../../contracts/oracle/interfaces/external/IWstETH.sol";
import { IUniswapV3Pool } from "../../../contracts/oracle/interfaces/external/IUniswapV3Pool.sol";
import { WstETHCLRSOracle } from "../../../contracts/oracle/oracles/wstETHCLRSOracle.sol";
import { ChainlinkOracleImpl } from "../../../contracts/oracle/implementations/chainlinkOracleImpl.sol";
import { RedstoneOracleImpl } from "../../../contracts/oracle/implementations/redstoneOracleImpl.sol";
import { UniV3OracleImpl } from "../../../contracts/oracle/implementations/uniV3OracleImpl.sol";
import { TickMath } from "../../../contracts/oracle/libraries/TickMath.sol";
import { ErrorTypes } from "../../../contracts/oracle/errorTypes.sol";
import { Error } from "../../../contracts/oracle/error.sol";

import { MockChainlinkFeed } from "./mocks/mockChainlinkFeed.sol";
import { MockRedstoneFeed } from "./mocks/mockRedstoneFeed.sol";
import { OracleTestSuite } from "./oracleTestSuite.t.sol";

import "forge-std/console2.sol";

contract WstETHCLRSOracleTest is OracleTestSuite {
    function setUp() public override {
        super.setUp();

        oracle = new WstETHCLRSOracle(
            WSTETH_TOKEN,
            1,
            ChainlinkOracleImpl.ChainlinkConstructorParams({
                hops: 2,
                feed1: ChainlinkOracleImpl.ChainlinkFeedData({
                    feed: CHAINLINK_FEED_STETH_ETH,
                    invertRate: false,
                    token0Decimals: 18 // STETH has 18 decimals
                }),
                feed2: ChainlinkOracleImpl.ChainlinkFeedData({
                    feed: CHAINLINK_FEED_ETH_USD,
                    invertRate: false,
                    token0Decimals: 18 // ETH has 18 decimals
                }),
                feed3: ChainlinkOracleImpl.ChainlinkFeedData({
                    feed: IChainlinkAggregatorV3(address(0)),
                    invertRate: false,
                    token0Decimals: 0
                })
            }),
            RedstoneOracleImpl.RedstoneOracleData({
                oracle: IRedstoneOracle(address(MOCK_REDSTONE_FEED)),
                invertRate: false,
                token0Decimals: 1
            })
        );
    }

    function test_getExchangeRate() public {
        (, int256 exchangeRateStEthEth_, , , ) = CHAINLINK_FEED_STETH_ETH.latestRoundData();
        assertEq(exchangeRateStEthEth_, 999668908364503600);
        // 0.999668908364503600 -> STETH -> ETH
        // 0.999668908364503600 = 999668908364503600

        (, int256 exchangeRateEthUsd_, , , ) = CHAINLINK_FEED_ETH_USD.latestRoundData();
        assertEq(exchangeRateEthUsd_, 201805491600);
        // 2018,05491600 -> ETH -> USD

        uint256 rateStEthEth = (uint256(exchangeRateStEthEth_) * (1e27)) / 1e18; // 1e27 -> Oracle precision,  1e6 -> USD decimals
        uint256 rateEthUsd = (uint256(exchangeRateEthUsd_) * (1e27)) / 1e18; // 1e27 -> Oracle precision,  1e6 -> USD decimals

        // STETH -> USD
        uint256 rateStEthUsd = (rateEthUsd * rateStEthEth) / 1e27;

        uint256 stEthPerToken = WSTETH_TOKEN.stEthPerToken();
        uint256 expectedRate = ((rateStEthUsd * stEthPerToken * 1e27) / 1e18) / 1e27;

        uint256 rate = oracle.getExchangeRate();
        assertEq(rate, expectedRate); // 2316.10317215209519606
    }

    function test_getExchangeRate_FailExchangeRateZero() public {
        oracle = new WstETHCLRSOracle(
            WSTETH_TOKEN,
            1,
            ChainlinkOracleImpl.ChainlinkConstructorParams({
                hops: 1,
                feed1: ChainlinkOracleImpl.ChainlinkFeedData({
                    feed: IChainlinkAggregatorV3(address(MOCK_CHAINLINK_FEED)),
                    invertRate: false,
                    token0Decimals: 18
                }),
                feed2: ChainlinkOracleImpl.ChainlinkFeedData({
                    feed: IChainlinkAggregatorV3(address(0)),
                    invertRate: false,
                    token0Decimals: 18 // ETH has 18 decimals
                }),
                feed3: ChainlinkOracleImpl.ChainlinkFeedData({
                    feed: IChainlinkAggregatorV3(address(0)),
                    invertRate: false,
                    token0Decimals: 0
                })
            }),
            RedstoneOracleImpl.RedstoneOracleData({
                oracle: IRedstoneOracle(address(MOCK_REDSTONE_FEED)),
                invertRate: false,
                token0Decimals: 1
            })
        );
        MOCK_CHAINLINK_FEED.setExchangeRate(0);

        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidOracleError.selector, ErrorTypes.WstETHCLRSOracle__ExchangeRateZero)
        );
        oracle.getExchangeRate();
    }
}
