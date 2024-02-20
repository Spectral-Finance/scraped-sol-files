// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./BaseOracleTest.t.sol";
import { FraxUsdcCurveLpDualOracle } from "src/FraxUsdcCurveLpDualOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "src/interfaces/IDualOracle.sol";
import "src/interfaces/IVirtualPriceStableSwap.sol";
import { deployFraxUsdcCurveLpDualOracle } from "script/deploy/DeployFraxUsdcCurveLpDualOracle.s.sol";
import { TestCurvePoolVirtualPriceOracleWithMinMax } from "./abstracts/TestCurvePoolVirtualPriceOracleWithMinMax.t.sol";
import { TestChainlinkOracleWithMaxDelay } from "./abstracts/TestChainlinkOracleWithMaxDelay.t.sol";
import { TestFraxUsdChainlinkOracleWithMaxDelay } from "./abstracts/TestFraxUsdChainlinkOracleWithMaxDelay.t.sol";
import { TestFraxUsdcUniswapV3SingleTwapOracle } from "./abstracts/TestFraxUsdcUniswapV3SingleTwapOracle.t.sol";

contract TestFraxUsdcCurveLpDualOracle is
    TestCurvePoolVirtualPriceOracleWithMinMax,
    TestChainlinkOracleWithMaxDelay,
    TestFraxUsdChainlinkOracleWithMaxDelay,
    TestFraxUsdcUniswapV3SingleTwapOracle
{
    using IDualOracleStructHelper for IDualOracle;

    FraxUsdcCurveLpDualOracle public localOracle;
    uint256 public ORACLE_PRECISION;

    function setUp() public {
        setupFunctions.push(scenario1);
        setupFunctions.push(scenario2);
    }

    function scenario1() public {
        console.log("scenario1: using mainnet fork with deployment functions");
        vm.createSelectFork(vm.envString("MAINNET_URL"), 16_451_985);
        dualOracleAddress = deployFraxUsdcCurveLpDualOracle()._address;
        dualOracle = IDualOracle(dualOracleAddress);
        localOracle = FraxUsdcCurveLpDualOracle(dualOracleAddress);
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    }

    function scenario2() public {
        console.log("scenario2: using deployed contract addresses");
        vm.createSelectFork(vm.envString("MAINNET_URL"), 17_273_484);
        dualOracleAddress = Constants.Mainnet.FRAX_USDC_CURVE_LP_DUAL_ORACLE_ADDRESS;
        dualOracle = IDualOracle(dualOracleAddress);
        localOracle = FraxUsdcCurveLpDualOracle(dualOracleAddress);
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    }

    function _assertInvariants(IDualOracle _dualOracle) internal {
        (, uint256 _priceLow, uint256 _priceHigh) = _dualOracle.getPrices();
        assertLe(_priceLow, _priceHigh, "Assert prices are in order");
    }

    function test_AssertPricesAreRelativelyEqual() public useMultipleSetupFunctions {
        (, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();
        assertApproxEqRelDecimal(_priceLow, _priceHigh, 20e15, 18, "Prices must be within 2% of each other");
        _assertInvariants(dualOracle);

        // Display values for sanity check
        Logger.decimal("_priceHigh", _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceHigh", 1e36 / _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, ORACLE_PRECISION);
        Logger.decimal("_priceLow", 1e36 / _priceLow, ORACLE_PRECISION);
    }

    function test_AssertUseOfFraxPerUsdcTwapCorrectly() public useMultipleSetupFunctions {
        // Initial values when twap == 1
        bool _isBadDataFraxUsdChainlink = false;
        uint256 _usdPerFraxChainlink = 100e16;
        uint256 _underlyingPerLp = 101e16;
        bool _isBadDataUsdcUsdChainlink = false;
        uint256 _usdPerUsdcChainlink = 100e16;
        uint256 _initialFraxPerUsdcTwap = 100e16;
        (, uint256 _initialPriceLow, uint256 _initialPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _usdPerUsdcChainlink,
            _fraxPerUsdcTwap: _initialFraxPerUsdcTwap
        });

        // Second case when twap == 0.5
        uint256 _smallFraxPerUsdcTwap = 50e16;
        (, uint256 _smallTwapPriceLow, uint256 _smallTwapPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _usdPerUsdcChainlink,
            _fraxPerUsdcTwap: _smallFraxPerUsdcTwap
        });
        assertEq(_initialPriceLow, _smallTwapPriceLow, "Assert low price is the same");
        assertEq(_initialPriceHigh * 2, _smallTwapPriceHigh, "Assert high price is 2x the original");

        // Third case when twap == 2
        uint256 _bigFraxPerUsdcTwap = 200e16;
        (, uint256 _bigTwapPriceLow, uint256 _bigTwapPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _usdPerUsdcChainlink,
            _fraxPerUsdcTwap: _bigFraxPerUsdcTwap
        });
        assertEq(
            _initialPriceLow,
            _bigTwapPriceLow,
            "Assert low price is equal to the original despite bigger twap value"
        );
        assertEq(_initialPriceHigh, _bigTwapPriceHigh, "Assert high price is the same");
    }

    function test_AssertUseOfFraxPerUsdcChainlinkUsedCorrectly() public useMultipleSetupFunctions {
        // Initial values when chainlink == 1
        bool _isBadDataFraxUsdChainlink = false;
        uint256 _usdPerFraxChainlink = 100e16;
        uint256 _underlyingPerLp = 101e16;
        bool _isBadDataUsdcUsdChainlink = false;
        uint256 _usdPerUsdcChainlink = 100e16;
        uint256 _initialFraxPerUsdcTwap = 100e16;
        (, uint256 _initialPriceLow, uint256 _initialPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _usdPerUsdcChainlink,
            _fraxPerUsdcTwap: _initialFraxPerUsdcTwap
        });

        // second case when chainlink = 0.5
        uint256 _smallUsdPerUsdcChainlink = 50e16;
        (, uint256 _smallChainlinkPriceLow, uint256 _smallChainlinkPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _smallUsdPerUsdcChainlink,
            _fraxPerUsdcTwap: _initialFraxPerUsdcTwap
        });
        assertEq(_initialPriceLow, _smallChainlinkPriceLow, "Assert low price is the same as the original");
        assertEq(_initialPriceHigh * 2, _smallChainlinkPriceHigh, "Assert high price is 2x the original for ");

        // third case when chainlink = 2
        uint256 _bigUsdPerUsdcChainlink = 200e16;
        (, uint256 _bigChainlinkPriceLow, uint256 _bigChainlinkPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _bigUsdPerUsdcChainlink,
            _fraxPerUsdcTwap: _initialFraxPerUsdcTwap
        });
        assertEq(_initialPriceLow, _bigChainlinkPriceLow, "Assert low price is the same");
        assertEq(_initialPriceHigh, _bigChainlinkPriceHigh, "Assert high price is the same");
    }

    function test_AssertTwapNumeratorDenominatorCorrect() public useMultipleSetupFunctions {
        address _uniV3PairAddress = localOracle.FRAX_USDC_UNI_V3_PAIR_ADDRESS();
        IERC20Metadata _fraxErc20 = IERC20Metadata(Constants.Mainnet.FRAX_ERC20);
        uint256 _fraxBalance = (_fraxErc20.balanceOf(_uniV3PairAddress) * 1e18) / _fraxErc20.decimals();
        IERC20Metadata _usdcErc20 = IERC20Metadata(Constants.Mainnet.USDC_ERC20);
        uint256 _usdcBalance = (_usdcErc20.balanceOf(_uniV3PairAddress) * 1e18) / _usdcErc20.decimals();
        if (_fraxBalance > _usdcBalance) {
            assertGt(localOracle.getTwapFraxPerUsdc(), 1e18, "if frax balance higher, expect usdc price to be higher");
        } else {
            assertLt(localOracle.getTwapFraxPerUsdc(), 1e18, "if usdc balance higher, expect usdc price to be lower");
        }
    }

    function test_UsdcDepegCausesCorrectPriceMovement() public useMultipleSetupFunctions {
        // Initial values when chainlink == 1 frax
        bool _isBadDataFraxUsdChainlink = false;
        uint256 _initialUsdPerFraxChainlink = 100e16;
        uint256 _underlyingPerLp = 101e16;
        bool _isBadDataUsdcUsdChainlink = false;
        uint256 _initialUsdPerUsdcChainlink = 100e16;
        uint256 _initialFraxPerUsdcTwap = 100e16;
        (, uint256 _initialPriceLow, uint256 _initialPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _initialUsdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _initialUsdPerUsdcChainlink,
            _fraxPerUsdcTwap: _initialFraxPerUsdcTwap
        });

        uint256 _depeggedUsdPerUsdcChainlink = 50e16;
        uint256 _depeggedFraxPerUsdcChainlink = 50e16;
        (, uint256 _depeggedPriceLow, uint256 _depeggedPriceHigh) = localOracle.calculatePrices({
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _initialUsdPerFraxChainlink,
            _underlyingPerLp: _underlyingPerLp,
            _isBadDataUsdcUsdChainlink: _isBadDataUsdcUsdChainlink,
            _usdPerUsdcChainlink: _depeggedUsdPerUsdcChainlink,
            _fraxPerUsdcTwap: _depeggedFraxPerUsdcChainlink
        });

        assertEq(_initialPriceLow, _depeggedPriceLow / 2, "Assert depegged low price is 2x the original");
        assertEq(_initialPriceHigh, _depeggedPriceHigh / 2, "Assert depegged high price is 2x the original");
    }

    struct SellReturn {
        uint256 finalPrice;
        uint256 initialPrice;
    }

    function test_DirectionOfCurvePoolVirtualPriceUp() external override useMultipleSetupFunctions {
        IDualOracleStructHelper.GetPricesReturn memory _initialPrices = dualOracle.__getPrices();
        _mockCurvePoolVirtualPrice(2e18);
        IDualOracleStructHelper.GetPricesReturn memory _finalPrices = dualOracle.__getPrices();

        // When virtual price goes up, the price of asset (frax) in LP terms goes down
        assertLt(_finalPrices.priceLow, _initialPrices.priceLow, "Assert price is increasing");
        assertLt(_finalPrices.priceHigh, _initialPrices.priceHigh, "Assert price is increasing");
    }
}
