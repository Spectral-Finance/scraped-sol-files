// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "src/ApeCoinDualOracle.sol";
import "./BaseOracleTest.t.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "src/interfaces/IDualOracle.sol";
import "src/interfaces/IFrxEthStableSwap.sol";
import { deployApeCoinDualOracle } from "script/deploy/DeployApeCoinDualOracle.s.sol";

contract TestApeCoinDualOracle is TestHelper {
    ApeCoinDualOracle dualOracle;

    uint256 public ORACLE_PRECISION;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_URL"), 16_725_098);
        (address _address, , ) = deployApeCoinDualOracle();
        dualOracle = ApeCoinDualOracle(_address);

        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    }

    function _assertInvariants(IDualOracle _dualOracle) internal {
        (, uint256 _priceLow, uint256 _priceHigh) = _dualOracle.getPrices();
        assertLe(_priceLow, _priceHigh, "Assert prices are in order");
    }

    function testGetPricesApe() public {
        (, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();

        Logger.decimal("_priceHigh", _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceHigh (inverted)", 1e36 / _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, ORACLE_PRECISION);
        Logger.decimal("_priceLow (inverted)", 1e36 / _priceLow, ORACLE_PRECISION);
        _assertInvariants(IDualOracle(address(dualOracle)));
    }
}
