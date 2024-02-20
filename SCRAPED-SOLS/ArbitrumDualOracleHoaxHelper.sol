// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// **NOTE** This file is auto-generated do not edit it directly.
// Run `frax hoax hoax ./src/ArbitrumDualOracle.sol` to re-generate it.

import { Vm } from "forge-std/Test.sol";
import { ArbitrumDualOracle } from "src/ArbitrumDualOracle.sol";

library ArbitrumDualOracleHoaxHelper {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    function __ARBITRUM_ERC20_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.ARBITRUM_ERC20();
        vm.stopPrank();
    }

    function __BASE_TOKEN_0_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.BASE_TOKEN_0();
        vm.stopPrank();
    }

    function __BASE_TOKEN_0_DECIMALS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.BASE_TOKEN_0_DECIMALS();
        vm.stopPrank();
    }

    function __BASE_TOKEN_1_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.BASE_TOKEN_1();
        vm.stopPrank();
    }

    function __BASE_TOKEN_1_DECIMALS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.BASE_TOKEN_1_DECIMALS();
        vm.stopPrank();
    }

    function __CHAINLINK_FEED_ADDRESS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.CHAINLINK_FEED_ADDRESS();
        vm.stopPrank();
    }

    function __CHAINLINK_FEED_DECIMALS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint8 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.CHAINLINK_FEED_DECIMALS();
        vm.stopPrank();
    }

    function __CHAINLINK_FEED_PRECISION_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.CHAINLINK_FEED_PRECISION();
        vm.stopPrank();
    }

    function __ETH_USD_CHAINLINK_FEED_ADDRESS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.ETH_USD_CHAINLINK_FEED_ADDRESS();
        vm.stopPrank();
    }

    function __ETH_USD_CHAINLINK_FEED_DECIMALS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint8 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.ETH_USD_CHAINLINK_FEED_DECIMALS();
        vm.stopPrank();
    }

    function __ETH_USD_CHAINLINK_FEED_PRECISION_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.ETH_USD_CHAINLINK_FEED_PRECISION();
        vm.stopPrank();
    }

    function __NORMALIZATION_0_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (int256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.NORMALIZATION_0();
        vm.stopPrank();
    }

    function __NORMALIZATION_1_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (int256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.NORMALIZATION_1();
        vm.stopPrank();
    }

    function __ORACLE_PRECISION_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.ORACLE_PRECISION();
        vm.stopPrank();
    }

    function __QUOTE_TOKEN_0_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.QUOTE_TOKEN_0();
        vm.stopPrank();
    }

    function __QUOTE_TOKEN_0_DECIMALS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.QUOTE_TOKEN_0_DECIMALS();
        vm.stopPrank();
    }

    function __QUOTE_TOKEN_1_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.QUOTE_TOKEN_1();
        vm.stopPrank();
    }

    function __QUOTE_TOKEN_1_DECIMALS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.QUOTE_TOKEN_1_DECIMALS();
        vm.stopPrank();
    }

    function __TWAP_PRECISION_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint128 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.TWAP_PRECISION();
        vm.stopPrank();
    }

    function __UNISWAP_V3_TWAP_BASE_TOKEN_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.UNISWAP_V3_TWAP_BASE_TOKEN();
        vm.stopPrank();
    }

    function __UNISWAP_V3_TWAP_QUOTE_TOKEN_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.UNISWAP_V3_TWAP_QUOTE_TOKEN();
        vm.stopPrank();
    }

    function __UNI_V3_PAIR_ADDRESS_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.UNI_V3_PAIR_ADDRESS();
        vm.stopPrank();
    }

    function __acceptTransferTimelock_As(ArbitrumDualOracle _arbitrumDualOracle, address _impersonator) internal {
        vm.startPrank(_impersonator);
        _arbitrumDualOracle.acceptTransferTimelock();
        vm.stopPrank();
    }

    function __calculatePrices_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator,
        bool isBadDataArbUsdChainlink,
        uint256 arbPerUsdChainlink,
        uint256 arbPerWethTwap,
        bool isBadDataEthUsdChainlink,
        uint256 usdPerEthChainlink
    ) internal returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        vm.startPrank(_impersonator);
        (isBadData, priceLow, priceHigh) = _arbitrumDualOracle.calculatePrices(
            isBadDataArbUsdChainlink,
            arbPerUsdChainlink,
            arbPerWethTwap,
            isBadDataEthUsdChainlink,
            usdPerEthChainlink
        );
        vm.stopPrank();
    }

    function __decimals_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint8 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.decimals();
        vm.stopPrank();
    }

    function __getArbPerUsdChainlink_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (bool isBadData, uint256 arbPerUsd) {
        vm.startPrank(_impersonator);
        (isBadData, arbPerUsd) = _arbitrumDualOracle.getArbPerUsdChainlink();
        vm.stopPrank();
    }

    function __getChainlinkPrice_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (bool _isBadData, uint256 _updatedAt, uint256 _price) {
        vm.startPrank(_impersonator);
        (_isBadData, _updatedAt, _price) = _arbitrumDualOracle.getChainlinkPrice();
        vm.stopPrank();
    }

    function __getEthUsdChainlinkPrice_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth) {
        vm.startPrank(_impersonator);
        (_isBadData, _updatedAt, _usdPerEth) = _arbitrumDualOracle.getEthUsdChainlinkPrice();
        vm.stopPrank();
    }

    function __getPrices_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        vm.startPrank(_impersonator);
        (isBadData, priceLow, priceHigh) = _arbitrumDualOracle.getPrices();
        vm.stopPrank();
    }

    function __getPricesNormalized_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (bool isBadDataNormal, uint256 priceLowNormal, uint256 priceHighNormal) {
        vm.startPrank(_impersonator);
        (isBadDataNormal, priceLowNormal, priceHighNormal) = _arbitrumDualOracle.getPricesNormalized();
        vm.stopPrank();
    }

    function __getUniswapV3Twap_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 _twap) {
        vm.startPrank(_impersonator);
        (_twap) = _arbitrumDualOracle.getUniswapV3Twap();
        vm.stopPrank();
    }

    function __getUsdPerEthChainlink_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (bool isBadData, uint256 usdPerEth) {
        vm.startPrank(_impersonator);
        (isBadData, usdPerEth) = _arbitrumDualOracle.getUsdPerEthChainlink();
        vm.stopPrank();
    }

    function __maximumEthUsdOracleDelay_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.maximumEthUsdOracleDelay();
        vm.stopPrank();
    }

    function __maximumOracleDelay_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint256 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.maximumOracleDelay();
        vm.stopPrank();
    }

    function __name_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (string memory _name) {
        vm.startPrank(_impersonator);
        (_name) = _arbitrumDualOracle.name();
        vm.stopPrank();
    }

    function __pendingTimelockAddress_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.pendingTimelockAddress();
        vm.stopPrank();
    }

    function __renounceTimelock_As(ArbitrumDualOracle _arbitrumDualOracle, address _impersonator) internal {
        vm.startPrank(_impersonator);
        _arbitrumDualOracle.renounceTimelock();
        vm.stopPrank();
    }

    function __setMaximumEthUsdOracleDelay_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator,
        uint256 newMaxOracleDelay
    ) internal {
        vm.startPrank(_impersonator);
        _arbitrumDualOracle.setMaximumEthUsdOracleDelay(newMaxOracleDelay);
        vm.stopPrank();
    }

    function __setMaximumOracleDelay_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator,
        uint256 newMaxOracleDelay
    ) internal {
        vm.startPrank(_impersonator);
        _arbitrumDualOracle.setMaximumOracleDelay(newMaxOracleDelay);
        vm.stopPrank();
    }

    function __setTwapDuration_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator,
        uint32 newTwapDuration
    ) internal {
        vm.startPrank(_impersonator);
        _arbitrumDualOracle.setTwapDuration(newTwapDuration);
        vm.stopPrank();
    }

    function __supportsInterface_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator,
        bytes4 interfaceId
    ) internal returns (bool return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.supportsInterface(interfaceId);
        vm.stopPrank();
    }

    function __timelockAddress_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (address return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.timelockAddress();
        vm.stopPrank();
    }

    function __transferTimelock_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator,
        address _newTimelock
    ) internal {
        vm.startPrank(_impersonator);
        _arbitrumDualOracle.transferTimelock(_newTimelock);
        vm.stopPrank();
    }

    function __twapDuration_As(
        ArbitrumDualOracle _arbitrumDualOracle,
        address _impersonator
    ) internal returns (uint32 return0) {
        vm.startPrank(_impersonator);
        (return0) = _arbitrumDualOracle.twapDuration();
        vm.stopPrank();
    }
}
