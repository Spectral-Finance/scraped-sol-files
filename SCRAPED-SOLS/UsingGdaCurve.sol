// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Configurable} from "./Configurable.sol";
import {ICurve} from "../../bonding-curves/ICurve.sol";
import {GDACurve} from "../../bonding-curves/GDACurve.sol";
import {LSSVMPair} from "../../LSSVMPair.sol";

abstract contract UsingGdaCurve is Configurable {
    function setupCurve() public override returns (ICurve) {
        return new GDACurve();
    }

    function modifyDelta(uint128) public view override returns (uint128) {
        // @dev hard coded because it's used in some implementation specific tests, yes this is gross, sorry
        return uint128(1e9 + 1) << 88;
    }

    function modifyDelta(uint128 delta, uint8) public view override returns (uint128) {
        return modifyDelta(delta);
    }

    function modifySpotPrice(uint56 /*spotPrice*/ ) public pure override returns (uint56) {
        return 0.01 ether;
    }

    function getParamsForPartialFillTest() public pure override returns (uint128 spotPrice, uint128 delta) {
        return (0.01 ether, 11);
    }

    // Adjusts price up or down
    function getParamsForAdjustingPriceToBuy(LSSVMPair pair, uint256 percentage, bool isIncrease)
        public
        view
        override
        returns (uint128 spotPrice, uint128 delta)
    {
        delta = pair.delta();
        if (isIncrease) {
            // Multiply token reserves by multiplier, divide by base for both spot price and delta
            spotPrice = uint128((pair.spotPrice() * percentage) / 1e18);
        } else {
            // Multiply token reserves by base, divide by multiplier for both spot price and delta
            spotPrice = uint128((pair.spotPrice() / 1e18) * percentage);
        }
    }

    function getReasonableDeltaAndSpotPrice() public pure override returns (uint128 delta, uint128 spotPrice) {
        delta = uint128(1e9 + 1) << 88;
        spotPrice = 1e18;
    }
}
