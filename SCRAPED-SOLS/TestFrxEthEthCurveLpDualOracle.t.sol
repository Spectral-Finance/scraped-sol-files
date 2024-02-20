// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IStaticOracle } from "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "./BaseOracleTest.t.sol";
import { IDualOracle } from "src/interfaces/IDualOracle.sol";
import { IFrxEthStableSwap } from "src/interfaces/IFrxEthStableSwap.sol";
import { FrxEthEthCurveLpDualOracle } from "src/FrxEthEthCurveLpDualOracle.sol";
import { TestCurvePoolVirtualPriceOracleWithMinMax } from "./abstracts/TestCurvePoolVirtualPriceOracleWithMinMax.t.sol";
import { TestCurvePoolEmaPriceOracleWithMinMax } from "./abstracts/TestCurvePoolEmaPriceOracleWithMinMax.t.sol";
import { TestChainlinkOracleWithMaxDelay } from "./abstracts/TestChainlinkOracleWithMaxDelay.t.sol";
import { TestEthUsdChainlinkOracleWithMaxDelay } from "./abstracts/TestEthUsdChainlinkOracleWithMaxDelay.t.sol";
import { TestUniswapV3SingleTwapOracle } from "./abstracts/TestUniswapV3SingleTwapOracle.t.sol";
import { deployFrxEthEthCurveLpDualOracle } from "script/deploy/DeployFrxEthEthCurveLpDualOracle.s.sol";
import { IDualOracleStructHelper } from "test/helpers/IDualOracleStructHelper.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

contract TestFrxEthEthCurveLpDualOracle is
    TestEthUsdChainlinkOracleWithMaxDelay,
    TestCurvePoolEmaPriceOracleWithMinMax,
    TestCurvePoolVirtualPriceOracleWithMinMax,
    TestUniswapV3SingleTwapOracle
{
    using OracleHelper for AggregatorV3Interface;
    using IDualOracleStructHelper for IDualOracle;

    uint256 public ORACLE_PRECISION;
    FrxEthEthCurveLpDualOracle public localOracle;

    function setUp() public {
        // vm.createSelectFork(vm.envString("MAINNET_URL"));
        vm.createSelectFork(vm.envString("MAINNET_URL"), 16_451_985);
        dualOracleAddress = deployFrxEthEthCurveLpDualOracle()._address;
        dualOracle = IDualOracle(dualOracleAddress);
        localOracle = FrxEthEthCurveLpDualOracle(dualOracleAddress);

        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    }

    function test_AssertPricesAreRelativelyEqual() public {
        (, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();
        assertApproxEqRelDecimal(_priceLow, _priceHigh, 15e15, 18, "Prices must be within 1% of each other");

        // Display values for sanity check
        Logger.decimal("_priceHigh", _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceHigh", 1e36 / _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, ORACLE_PRECISION);
        Logger.decimal("_priceLow", 1e36 / _priceLow, ORACLE_PRECISION);
    }

    function test_WhenChainlinkAndCurvePricesEqual() public {
        // Scenario 2 use curveEma and chainlink
        (, uint256 _priceLow, uint256 _priceHigh) = localOracle.calculatePrices({
            _isBadDataEthUsdChainlink: false,
            _chainlinkUsdPerEth: 2000 * ORACLE_PRECISION,
            _isBadDataTwap: false,
            _twapFrxEthPerUsd: ORACLE_PRECISION / 10_000,
            _virtualPrice: 1 * ORACLE_PRECISION,
            _curveEmaFrxEthPerUsd: ORACLE_PRECISION / 2000
        });
        assertApproxEqRelDecimal(_priceLow, _priceHigh, 15e15, 18, "Prices must be within 1% of each other");
        assertApproxEqRelDecimal(
            _priceLow,
            ORACLE_PRECISION / 2000,
            15e15,
            18,
            "Prices must be within 1% of expected values"
        );
    }

    function test_WhenTwapAndChainlinkPricesEqual() public {
        // Scenario 3 use chainlink and twap
        (, uint256 _priceLow, uint256 _priceHigh) = localOracle.calculatePrices({
            _isBadDataEthUsdChainlink: false,
            _chainlinkUsdPerEth: 2000 * ORACLE_PRECISION,
            _isBadDataTwap: false,
            _twapFrxEthPerUsd: ORACLE_PRECISION / 2000,
            _virtualPrice: 1 * ORACLE_PRECISION,
            _curveEmaFrxEthPerUsd: ORACLE_PRECISION / 10_000
        });
        assertApproxEqRelDecimal(_priceLow, _priceHigh, 15e15, 18, "Prices must be within 1% of each other");
        assertApproxEqRelDecimal(
            _priceLow,
            ORACLE_PRECISION / 2000,
            15e15,
            18,
            "Prices must be within 1% of each other"
        );
    }

    function test_WhenTwapAndCurvePricesEqual() public {
        // Scenario 1 use curveEma and twap
        (, uint256 _priceLow, uint256 _priceHigh) = localOracle.calculatePrices({
            _isBadDataEthUsdChainlink: false,
            _chainlinkUsdPerEth: 1000 * ORACLE_PRECISION,
            _isBadDataTwap: false,
            _twapFrxEthPerUsd: ORACLE_PRECISION / 2000,
            _virtualPrice: 1 * ORACLE_PRECISION,
            _curveEmaFrxEthPerUsd: ORACLE_PRECISION / 2000
        });
        assertApproxEqRelDecimal(_priceLow, _priceHigh, 15e15, 18, "Prices must be within 1% of each other");
        assertApproxEqRelDecimal(
            _priceLow,
            ORACLE_PRECISION / 1000,
            15e15,
            18,
            "Prices must be within 1% of each other"
        );
    }

    struct SellReturn {
        uint256 finalPrice;
        uint256 initialPrice;
    }

    function _sellFrxEthForEth(uint256 _amount) internal returns (SellReturn memory _return) {
        IFrxEthStableSwap _pool = IFrxEthStableSwap(Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP);
        address user1 = address(144_438_484);
        faucetFunds(IERC20(Constants_Mainnet.FRXETH_ERC20), _amount, user1);
        _return.initialPrice = _pool.price_oracle();

        startHoax(user1);
        IERC20(Constants_Mainnet.FRXETH_ERC20).approve(
            Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            type(uint256).max
        );
        _pool.exchange(1, 0, _amount, 0);
        vm.stopPrank();

        _return.finalPrice = _pool.price_oracle();
    }

    function _sellEthForFrxEth(uint256 _amount) internal returns (SellReturn memory _return) {
        IFrxEthStableSwap _pool = IFrxEthStableSwap(Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP);
        address user1 = address(144_438_484);
        _return.initialPrice = _pool.price_oracle();

        startHoax(user1);
        _pool.exchange{ value: _amount }(0, 1, _amount, 0);
        vm.stopPrank();

        _return.finalPrice = _pool.price_oracle();
    }

    function test_DirectionOfCurvePoolEmaUp() external override {
        SellReturn memory _return = _sellEthForFrxEth(10_000e18);
        assertGt(_return.finalPrice, _return.initialPrice, "Assert price is increasing");
    }

    function test_DirectionOfCurvePoolEmaDown() external override {
        SellReturn memory _return = _sellFrxEthForEth(10_000e18);
        assertLt(_return.finalPrice, _return.initialPrice, "Assert price is decreasing");
    }

    function test_DirectionOfCurvePoolVirtualPriceUp() external override {
        SellReturn memory _return = _sellEthForFrxEth(10_000e18);
        assertGt(_return.finalPrice, _return.initialPrice, "Assert price is increasing");
    }

    function test_PoolUsesLowerUnderlyingPrice() external {
        (, uint256 _usdPerEthChainlink) = localOracle.getChainlinkUsdPerEth();
        uint256 _ethPerUsdChainlink = (ORACLE_PRECISION * ORACLE_PRECISION) / _usdPerEthChainlink;

        uint256 _initialFrxEthPerUsd = localOracle.getCurveEmaFrxEthPerUsd(_usdPerEthChainlink);
        assertGt(_initialFrxEthPerUsd, _ethPerUsdChainlink, "Assert frxEth < Eth originally (inversed)");

        IDualOracleStructHelper.GetPricesReturn memory _initialPrices = dualOracle.__getPrices();

        uint256 _newPrice = ((ORACLE_PRECISION * ORACLE_PRECISION) / _initialFrxEthPerUsd) / 2;
        assertGt(_newPrice, _initialFrxEthPerUsd, "Assert new price is lower (inversed)");

        AggregatorV3Interface(localOracle.ETH_USD_CHAINLINK_FEED_ADDRESS()).setPrice(
            _newPrice,
            ORACLE_PRECISION,
            block.timestamp,
            vm
        );
        IDualOracleStructHelper.GetPricesReturn memory _finalPrices = dualOracle.__getPrices();
        assertGt(_finalPrices.priceLow, _initialPrices.priceLow, "Assert price is decreasing (inversed)");
        assertGt(_finalPrices.priceHigh, _initialPrices.priceHigh, "Assert price is decreasing (inversed)");
    }
}
