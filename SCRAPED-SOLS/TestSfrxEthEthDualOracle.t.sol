// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import { SfrxEthEthDualOracle } from "src/frax-oracle/SfrxEthEthDualOracle.sol";
import { TestFrxEthEthDualOracle, FrxEthEthDualOracle } from "./TestFrxEthEthDualOracle.t.sol";
import { deploySfrxEthEthDualOracle } from "script/deploy/DeploySfrxEthEthDualOracle.s.sol";

contract TestSfrxEthEthDualOracle is TestFrxEthEthDualOracle {
    address public sfrxEthDualOracleAddress;
    IDualOracle public sfrxEthDualOracle;

    SfrxEthEthDualOracle public sfrxEthLocalOracle;
    uint256 public SFRXETH_ORACLE_PRECISION;

    function setUp() public virtual override {
        super.setUp();
        (sfrxEthDualOracleAddress, , ) = deploySfrxEthEthDualOracle();
        sfrxEthDualOracle = IDualOracle(sfrxEthDualOracleAddress);
        sfrxEthLocalOracle = SfrxEthEthDualOracle(dualOracleAddress);
        SFRXETH_ORACLE_PRECISION = sfrxEthDualOracle.ORACLE_PRECISION();
    }

    function _assertInvariants(
        IDualOracle _dualOracle
    ) internal override returns (uint256 _priceLow, uint256 _priceHigh) {
        // pass the frxEthEth oracle
        (uint256 frxEthPriceLow, uint256 frxEthPriceHigh) = super._assertInvariants(dualOracle);

        SfrxEthEthDualOracle sfrxEthDualOracle = SfrxEthEthDualOracle(address(sfrxEthDualOracle));
        (, uint256 sfrxEthPriceLow, uint256 sfrxEthPriceHigh) = sfrxEthDualOracle.getPrices();

        assertGt(sfrxEthPriceLow, frxEthPriceLow, "sfrxEth price should always be higher than frxEth price");
        assertGt(sfrxEthPriceHigh, frxEthPriceHigh, "sfrxEth price should always be higher than frxEth price");
    }

    function testGetPricesSfrxEthInEth() public {
        (, uint256 _priceLow, uint256 _priceHigh) = sfrxEthDualOracle.getPrices();

        Logger.decimal("_priceHigh", _priceHigh, SFRXETH_ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, SFRXETH_ORACLE_PRECISION);
        _assertInvariants(sfrxEthDualOracle);
    }

    function testFuzzSfrxEthEthPriceHigher(
        uint256 ethPerFrxEthCurveEma,
        uint256 fraxPerFrxEthTwap,
        uint256 usdPerEthChainlink,
        uint256 usdPerFraxChainlink
    ) public {
        FrxEthEthDualOracle _frxEthDualOracle = FrxEthEthDualOracle(address(dualOracle));
        SfrxEthEthDualOracle _sfrxEthDualOracle = SfrxEthEthDualOracle(address(sfrxEthDualOracle));

        ethPerFrxEthCurveEma = bound(
            ethPerFrxEthCurveEma,
            _sfrxEthDualOracle.minimumCurvePoolEma(),
            _sfrxEthDualOracle.maximumCurvePoolEma()
        );
        fraxPerFrxEthTwap = bound(fraxPerFrxEthTwap, 6e20, 20e22); // $600 - $20,000
        usdPerEthChainlink = bound(
            usdPerEthChainlink,
            fraxPerFrxEthTwap - ((fraxPerFrxEthTwap * 3) / 100), // - 3%
            fraxPerFrxEthTwap + ((fraxPerFrxEthTwap * 3) / 100) //  + 3%
        );
        usdPerFraxChainlink = bound(usdPerFraxChainlink, 0.8e18, 1.1e18); // $.80 - 1.1$

        (bool frxEthIsBadData, uint256 frxEthPriceLow, uint256 frxEthPriceHigh) = _frxEthDualOracle.calculatePrices({
            _ethPerFrxEthCurveEma: ethPerFrxEthCurveEma,
            _fraxPerFrxEthTwap: fraxPerFrxEthTwap,
            _isBadDataEthUsdChainlink: false,
            _usdPerEthChainlink: usdPerEthChainlink,
            _isBadDataFraxUsdChainlink: false,
            _usdPerFraxChainlink: usdPerFraxChainlink
        });

        (bool sfrxEthIsBadData, uint256 sfrxEthPriceLow, uint256 sfrxEthPriceHigh) = _sfrxEthDualOracle
            .calculatePrices({
                _ethPerFrxEthCurveEma: ethPerFrxEthCurveEma,
                _fraxPerFrxEthTwap: fraxPerFrxEthTwap,
                _isBadDataEthUsdChainlink: false,
                _usdPerEthChainlink: usdPerEthChainlink,
                _isBadDataFraxUsdChainlink: false,
                _usdPerFraxChainlink: usdPerFraxChainlink
            });

        assertFalse(frxEthIsBadData);
        assertFalse(sfrxEthIsBadData);

        assertGt(sfrxEthPriceLow, frxEthPriceLow, "sfrxEth price should always be higher than frxEth price");
        assertGt(sfrxEthPriceHigh, frxEthPriceHigh, "sfrxEth price should always be higher than frxEth price");
    }
}
