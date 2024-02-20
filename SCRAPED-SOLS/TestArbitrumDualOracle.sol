// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./BaseOracleTest.t.sol";
import { ArbitrumDualOracle } from "src/ArbitrumDualOracle.sol";
import { IDualOracle } from "src/interfaces/IDualOracle.sol";
import { deployArbitrumDualOracle } from "script/deploy/arbitrum/DeployArbitrumDualOracle.s.sol";
import { TestUniswapV3SingleTwapOracle } from "./abstracts/TestUniswapV3SingleTwapOracle.t.sol";
import { TestChainlinkOracleWithMaxDelay } from "./abstracts/TestChainlinkOracleWithMaxDelay.t.sol";
import { TestEthUsdChainlinkOracleWithMaxDelay } from "./abstracts/TestEthUsdChainlinkOracleWithMaxDelay.t.sol";

contract TestArbitrumDualOracle is
    TestUniswapV3SingleTwapOracle,
    TestChainlinkOracleWithMaxDelay,
    TestEthUsdChainlinkOracleWithMaxDelay
{
    using IDualOracleStructHelper for IDualOracle;
    using ArbitrumDualOracleStructHelper for ArbitrumDualOracle;

    ArbitrumDualOracle public localOracle;
    uint256 public ORACLE_PRECISION;

    function setUp() public {
        setupFunctions.push(scenario_manualDeploy);
        //setupFunctions.push(scenario2);
    }

    function scenario_manualDeploy() public {
        console.log("scenario1: using arb mainnet fork with deployment functions");
        vm.createSelectFork(vm.envString("ARBITRUM_MAINNET_URL"), 91_970_319);
        (dualOracleAddress, , ) = deployArbitrumDualOracle();
        dualOracle = IDualOracle(dualOracleAddress);
        localOracle = ArbitrumDualOracle(dualOracleAddress);
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    }

    //    function scenario_useDeployedContracts() public {
    //        console.log("scenario2: using arb mainnet deployed contract addresses");
    //     //    vm.createSelectFork(vm.envString("ARBITRUM_MAINNET_URL"), //TODO: block number);
    //        dualOracleAddress = Constants.Arbitrum.ARBITRUM_DUAL_ORACLE_ADDRESS;
    //        dualOracle = IDualOracle(dualOracleAddress);
    //        localOracle = deployArbitrumDualOracle(dualOracleAddress);
    //        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    //    }

    function _assertInvariants(IDualOracle _dualOracle) internal {
        (, uint256 _priceLow, uint256 _priceHigh) = _dualOracle.getPrices();
        assertLe(_priceLow, _priceHigh, "Assert prices are in order");
    }

    function testGetPricesArbitrum() public useMultipleSetupFunctions {
        (, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();

        Logger.decimal("_priceHigh", _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceHigh (inverted)", 1e36 / _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, ORACLE_PRECISION);
        Logger.decimal("_priceLow (inverted)", 1e36 / _priceLow, ORACLE_PRECISION);
        _assertInvariants(IDualOracle(address(dualOracle)));
    }

    function test_DirectionOfTwap() public useMultipleSetupFunctions {
        // Vars that dont change
        bool isBadDataArbUsdChainlink = false;
        uint256 arbPerUsdChainlink = 100e16; // 1:1
        bool isBadDataEthUsdChainlink = false;
        uint256 usdPerEthChainlink = 2000e18; // 2000:1

        // Vars that change
        uint256 arbPerWethTwap = 2000e18; // 2000:1
        ArbitrumDualOracleStructHelper.CalculatePricesReturn memory _initial = localOracle.__calculatePrices({
            isBadDataArbUsdChainlink: isBadDataArbUsdChainlink,
            arbPerUsdChainlink: arbPerUsdChainlink,
            arbPerWethTwap: arbPerWethTwap,
            isBadDataEthUsdChainlink: isBadDataEthUsdChainlink,
            usdPerEthChainlink: usdPerEthChainlink
        });
        // New Value for arbPerWethTwap
        uint256 newArbPerWethTwap = 2 * arbPerWethTwap; // 4000:1
        ArbitrumDualOracleStructHelper.CalculatePricesReturn memory _final = localOracle.__calculatePrices({
            isBadDataArbUsdChainlink: isBadDataArbUsdChainlink,
            arbPerUsdChainlink: arbPerUsdChainlink,
            arbPerWethTwap: newArbPerWethTwap,
            isBadDataEthUsdChainlink: isBadDataEthUsdChainlink,
            usdPerEthChainlink: usdPerEthChainlink
        });

        assertEq(_initial.priceLow, _final.priceLow, "Assert priceLow is unchanged");
        assertEq(_initial.priceHigh * 2, _final.priceHigh, "Assert priceHigh is unchanged");
        assertLe(_initial.priceLow, _initial.priceHigh, "Assert prices are in order");
        assertLe(_final.priceLow, _final.priceHigh, "Assert prices are in order");
    }
}
