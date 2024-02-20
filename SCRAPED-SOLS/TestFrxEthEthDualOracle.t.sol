// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import { FrxEthEthDualOracle } from "src/frax-oracle/FrxEthEthDualOracle.sol";
import { IDualOracle } from "src/interfaces/IDualOracle.sol";
import { deployFrxEthEthDualOracle } from "script/deploy/DeployFrxEthEthDualOracle.s.sol";
import { TestUniswapV3SingleTwapOracle } from "../abstracts/TestUniswapV3SingleTwapOracle.t.sol";
import { TestFraxUsdChainlinkOracleWithMaxDelay } from "../abstracts/TestFraxUsdChainlinkOracleWithMaxDelay.t.sol";
import { TestEthUsdChainlinkOracleWithMaxDelay } from "../abstracts/TestEthUsdChainlinkOracleWithMaxDelay.t.sol";
import { TestCurvePoolEmaPriceOracleWithMinMax } from "../abstracts/TestCurvePoolEmaPriceOracleWithMinMax.t.sol";
import "interfaces/IFrxEthStableSwap.sol";

contract TestFrxEthEthDualOracle is
    TestUniswapV3SingleTwapOracle,
    TestFraxUsdChainlinkOracleWithMaxDelay,
    TestEthUsdChainlinkOracleWithMaxDelay,
    TestCurvePoolEmaPriceOracleWithMinMax
{
    FrxEthEthDualOracle public localOracle;
    uint256 public ORACLE_PRECISION;

    uint256 blockNumber = 17_571_401;

    function setUp() public virtual {
        console.log("scenario1: using eth mainnet fork with deployment functions");
        vm.createSelectFork(vm.envString("MAINNET_URL"), blockNumber);
        (dualOracleAddress, , ) = deployFrxEthEthDualOracle();
        dualOracle = IDualOracle(dualOracleAddress);
        localOracle = FrxEthEthDualOracle(dualOracleAddress);
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
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
        IFrxEthStableSwap _pool = IFrxEthStableSwap(Constants.Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP);
        address user1 = address(144_438_484);
        _return.initialPrice = _pool.price_oracle();

        startHoax(user1);
        _pool.exchange{ value: _amount }(0, 1, _amount, 0);
        vm.stopPrank();

        _return.finalPrice = _pool.price_oracle();
    }

    function test_DirectionOfCurvePoolEmaDown() external override {
        SellReturn memory _return = _sellFrxEthForEth(10_000e18);
        assertLt(_return.finalPrice, _return.initialPrice, "Assert price is decreasing");
    }

    function test_DirectionOfCurvePoolEmaUp() external override {
        SellReturn memory _return = _sellEthForFrxEth(10_000e18);
        assertGt(_return.finalPrice, _return.initialPrice, "Assert price is increasing");
    }

    function _assertInvariants(
        IDualOracle _dualOracle
    ) internal virtual returns (uint256 _priceLow, uint256 _priceHigh) {
        FrxEthEthDualOracle frxEthDualOracle = FrxEthEthDualOracle(address(_dualOracle));
        (, _priceLow, _priceHigh) = frxEthDualOracle.getPrices();
        assertLe(_priceLow, _priceHigh, "Assert prices are in order");

        uint256 minimumPrice = frxEthDualOracle.minimumCurvePoolEma();
        uint256 maximumPrice = frxEthDualOracle.maximumCurvePoolEma();

        assertLe(_priceHigh, maximumPrice, "High price is never above maximumPrice");
        assertGe(_priceHigh, minimumPrice, "High price is never below minimumPrice");

        assertLe(_priceLow, maximumPrice, "High price is never above maximumPrice");
        assertGe(_priceLow, minimumPrice, "High price is never below minimumPrice");
    }

    function testGetPricesFrxEthInEth() public {
        (, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();

        Logger.decimal("_priceHigh", _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, ORACLE_PRECISION);
        _assertInvariants(dualOracle);
    }

    function testFuzzFrxEthEthPriceBounds(
        uint256 ethPerFrxEthCurveEma,
        uint256 fraxPerFrxEthTwap,
        uint256 usdPerEthChainlink,
        uint256 usdPerFraxChainlink
    ) public {
        FrxEthEthDualOracle _dualOracle = FrxEthEthDualOracle(address(dualOracle));
        uint256 minimumPrice = _dualOracle.minimumCurvePoolEma();
        uint256 maximumPrice = _dualOracle.maximumCurvePoolEma();

        ethPerFrxEthCurveEma = bound(ethPerFrxEthCurveEma, minimumPrice, maximumPrice);
        fraxPerFrxEthTwap = bound(fraxPerFrxEthTwap, 6e20, 20e22); // $600 - $20,000
        usdPerEthChainlink = bound(
            usdPerEthChainlink,
            fraxPerFrxEthTwap - ((fraxPerFrxEthTwap * 3) / 100), // - 3%
            fraxPerFrxEthTwap + ((fraxPerFrxEthTwap * 3) / 100) //  + 3%
        );
        usdPerFraxChainlink = bound(usdPerFraxChainlink, 0.8e18, 1.1e18); // $.80 - 1.1$

        (bool isBadData, uint256 priceLow, uint256 priceHigh) = _dualOracle.calculatePrices({
            _ethPerFrxEthCurveEma: ethPerFrxEthCurveEma,
            _fraxPerFrxEthTwap: fraxPerFrxEthTwap,
            _isBadDataEthUsdChainlink: false,
            _usdPerEthChainlink: usdPerEthChainlink,
            _isBadDataFraxUsdChainlink: false,
            _usdPerFraxChainlink: usdPerFraxChainlink
        });

        assertFalse(isBadData);

        assertLe(priceHigh, maximumPrice, "High price is never above maximumPrice");
        assertGe(priceHigh, minimumPrice, "High price is never below minimumPrice");

        assertLe(priceLow, maximumPrice, "High price is never above maximumPrice");
        assertGe(priceLow, minimumPrice, "High price is never below minimumPrice");
    }
}
