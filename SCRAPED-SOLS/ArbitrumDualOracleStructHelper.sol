// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { ArbitrumDualOracle } from "src/ArbitrumDualOracle.sol";

library ArbitrumDualOracleStructHelper {
    struct CalculatePricesReturn {
        bool isBadData;
        uint256 priceLow;
        uint256 priceHigh;
    }

    function __calculatePrices(
        ArbitrumDualOracle _arbitrumDualOracle,
        bool isBadDataArbUsdChainlink,
        uint256 arbPerUsdChainlink,
        uint256 arbPerWethTwap,
        bool isBadDataEthUsdChainlink,
        uint256 usdPerEthChainlink
    ) internal pure returns (CalculatePricesReturn memory _return) {
        (_return.isBadData, _return.priceLow, _return.priceHigh) = _arbitrumDualOracle.calculatePrices(
            isBadDataArbUsdChainlink,
            arbPerUsdChainlink,
            arbPerWethTwap,
            isBadDataEthUsdChainlink,
            usdPerEthChainlink
        );
    }

    struct GetArbPerUsdChainlinkReturn {
        bool isBadData;
        uint256 arbitrumPerUsd;
    }

    function __getArbPerUsdChainlink(
        ArbitrumDualOracle _arbitrumDualOracle
    ) internal view returns (GetArbPerUsdChainlinkReturn memory _return) {
        (_return.isBadData, _return.arbitrumPerUsd) = _arbitrumDualOracle.getArbPerUsdChainlink();
    }

    struct GetChainlinkPriceReturn {
        bool isBadData;
        uint256 updatedAt;
        uint256 price;
    }

    function __getChainlinkPrice(
        ArbitrumDualOracle _arbitrumDualOracle
    ) internal view returns (GetChainlinkPriceReturn memory _return) {
        (_return.isBadData, _return.updatedAt, _return.price) = _arbitrumDualOracle.getChainlinkPrice();
    }

    struct GetEthUsdChainlinkPriceReturn {
        bool isBadData;
        uint256 updatedAt;
        uint256 usdPerEth;
    }

    function __getEthUsdChainlinkPrice(
        ArbitrumDualOracle _arbitrumDualOracle
    ) internal view returns (GetEthUsdChainlinkPriceReturn memory _return) {
        (_return.isBadData, _return.updatedAt, _return.usdPerEth) = _arbitrumDualOracle.getEthUsdChainlinkPrice();
    }

    struct GetPricesReturn {
        bool isBadData;
        uint256 priceLow;
        uint256 priceHigh;
    }

    function __getPrices(
        ArbitrumDualOracle _arbitrumDualOracle
    ) internal view returns (GetPricesReturn memory _return) {
        (_return.isBadData, _return.priceLow, _return.priceHigh) = _arbitrumDualOracle.getPrices();
    }

    struct GetPricesNormalizedReturn {
        bool isBadDataNormal;
        uint256 priceLowNormal;
        uint256 priceHighNormal;
    }

    function __getPricesNormalized(
        ArbitrumDualOracle _arbitrumDualOracle
    ) internal view returns (GetPricesNormalizedReturn memory _return) {
        (_return.isBadDataNormal, _return.priceLowNormal, _return.priceHighNormal) = _arbitrumDualOracle
            .getPricesNormalized();
    }

    struct GetUsdPerEthChainlinkReturn {
        bool isBadData;
        uint256 usdPerEth;
    }

    function __getUsdPerEthChainlink(
        ArbitrumDualOracle _arbitrumDualOracle
    ) internal view returns (GetUsdPerEthChainlinkReturn memory _return) {
        (_return.isBadData, _return.usdPerEth) = _arbitrumDualOracle.getUsdPerEthChainlink();
    }
}
