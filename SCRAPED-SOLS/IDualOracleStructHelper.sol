// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "interfaces/IDualOracle.sol";

library IDualOracleStructHelper {
    struct GetPricesReturn {
        bool isBadData;
        uint256 priceLow;
        uint256 priceHigh;
    }

    function __getPrices(IDualOracle _dualOracle) internal view returns (GetPricesReturn memory _return) {
        (_return.isBadData, _return.priceLow, _return.priceHigh) = _dualOracle.getPrices();
    }

    struct GetPricesNormalizedReturn {
        bool isBadData;
        uint256 priceLow;
        uint256 priceHigh;
    }

    function __getPricesNormalized(
        IDualOracle _dualOracle
    ) internal view returns (GetPricesNormalizedReturn memory _return) {
        (_return.isBadData, _return.priceLow, _return.priceHigh) = _dualOracle.getPricesNormalized();
    }
}
