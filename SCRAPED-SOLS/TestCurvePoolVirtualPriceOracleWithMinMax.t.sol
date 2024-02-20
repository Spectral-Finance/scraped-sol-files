// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import "src/interfaces/oracles/abstracts/ICurvePoolVirtualPriceOracleWithMinMax.sol";
import "src/interfaces/IVirtualPriceStableSwap.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";

abstract contract TestCurvePoolVirtualPriceOracleWithMinMax is BaseOracleTest {
    function _mockCurvePoolVirtualPrice(uint256 _price) internal returns (uint256 _realPrice) {
        address _curvePoolVirtualPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress)
            .CURVE_POOL_VIRTUAL_PRICE_ADDRESS();
        vm.mockCall(
            _curvePoolVirtualPrice,
            abi.encodeWithSelector(IVirtualPriceStableSwap.get_virtual_price.selector),
            abi.encode(_price)
        );
        _realPrice = IVirtualPriceStableSwap(_curvePoolVirtualPrice).get_virtual_price();
    }

    function _assertCurvePoolVirtualPriceInvariants() internal {
        uint256 _price = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).getCurvePoolVirtualPrice();
        uint256 _minPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolVirtualPrice();
        uint256 _maxPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolVirtualPrice();
        assertGe(_price, _minPrice, "Price should be greater than or equal to min");
        assertLe(_price, _maxPrice, "Price should be less than or equal to max");
    }

    // Test Min

    function test_GetCurvePoolVirtualPriceLessThanMinimum() public useMultipleSetupFunctions {
        uint256 _minPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolVirtualPrice();
        uint256 _realPrice = _mockCurvePoolVirtualPrice(_minPrice / 2);
        assertLt(_realPrice, _minPrice, "Ensure mock price is less than min");
        _assertCurvePoolVirtualPriceInvariants();
    }

    function test_GetGetCurvePoolVirtualPriceGreaterThanMinimum() public useMultipleSetupFunctions {
        uint256 _minPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolVirtualPrice();
        uint256 _realPrice = _mockCurvePoolVirtualPrice((_minPrice * 3) / 2);
        assertGt(_realPrice, _minPrice, "Ensure mock price is greater than min");
        _assertCurvePoolVirtualPriceInvariants();
    }

    function test_CanSet_MinimumCurvePoolVirtualPrice() public useMultipleSetupFunctions {
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        uint256 _minPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolVirtualPrice();
        uint256 _newMinPrice = (_minPrice * 8) / 10;
        ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).setMinimumCurvePoolVirtualPrice(_newMinPrice);
        vm.stopPrank();
        uint256 _realPrice = _mockCurvePoolVirtualPrice((_newMinPrice * 8) / 10);
        assertLt(_realPrice, _newMinPrice, "Ensure mock price is less than new min");
        _assertCurvePoolVirtualPriceInvariants();
    }

    function test_RevertWith_OnlyTimelock_SetMinimumCurvePollVirtualPrice() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).setMinimumCurvePoolVirtualPrice(5e17);
    }

    // max functions

    function test_GetCurvePoolVirtualPriceLessThanMaximum() public useMultipleSetupFunctions {
        uint256 _maxPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolVirtualPrice();
        uint256 _realPrice = _mockCurvePoolVirtualPrice(_maxPrice / 2);
        assertLt(_realPrice, _maxPrice, "Ensure mock price is less than max");
        _assertCurvePoolVirtualPriceInvariants();
    }

    function test_GetCurvePoolVirtualPriceGreaterThanMaximum() public useMultipleSetupFunctions {
        uint256 _maxPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolVirtualPrice();
        uint256 _realPrice = _mockCurvePoolVirtualPrice((_maxPrice * 3) / 2);
        assertGt(_realPrice, _maxPrice, "Ensure mock price is greater than max");
        _assertCurvePoolVirtualPriceInvariants();
    }

    function test_CanSet_MaximumCurvePoolVirtualPrice() public useMultipleSetupFunctions {
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        uint256 _maxPrice = ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolVirtualPrice();
        uint256 _newMaxPrice = (_maxPrice * 10) / 8;
        ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).setMaximumCurvePoolVirtualPrice(_newMaxPrice);
        vm.stopPrank();
        uint256 _realPrice = _mockCurvePoolVirtualPrice((_newMaxPrice * 10) / 8);
        assertGt(_realPrice, _newMaxPrice, "Ensure mock price is greater than new max");
        _assertCurvePoolVirtualPriceInvariants();
    }

    function test_RevertWith_TimelockOnly_SetMaximumCurvePoolVirtualPrice() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        ICurvePoolVirtualPriceOracleWithMinMax(dualOracleAddress).setMaximumCurvePoolVirtualPrice(5e17);
    }

    function test_DirectionOfCurvePoolVirtualPriceUp() external virtual;
}
