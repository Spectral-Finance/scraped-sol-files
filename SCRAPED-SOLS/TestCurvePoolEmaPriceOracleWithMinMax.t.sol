// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import "src/interfaces/oracles/abstracts/ICurvePoolEmaPriceOracleWithMinMax.sol";
import "src/interfaces/IEmaPriceOracleStableSwap.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";

abstract contract TestCurvePoolEmaPriceOracleWithMinMax is BaseOracleTest {
    // test min

    function _mockCurvePoolEmaPrice(uint256 _price) internal returns (uint256 _realPrice) {
        address _curvePoolEmaPriceOracle = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress)
            .CURVE_POOL_EMA_PRICE_ORACLE();
        vm.mockCall(
            _curvePoolEmaPriceOracle,
            abi.encodeWithSelector(IEmaPriceOracleStableSwap.price_oracle.selector),
            abi.encode(_price)
        );
        _realPrice = IEmaPriceOracleStableSwap(_curvePoolEmaPriceOracle).price_oracle();
    }

    function _assertCurvePoolEmaInvariants() internal {
        uint256 _price = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).getCurvePoolToken1EmaPrice();
        uint256 _minPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolEma();
        uint256 _maxPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolEma();
        assertGe(_price, _minPrice, "Price should be greater than or equal to min");
        assertLe(_price, _maxPrice, "Price should be less than or equal to max");
    }

    function test_GetCurvePoolEmaLessThanMinimum() public useMultipleSetupFunctions {
        uint256 _minPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolEma();
        uint256 _realPrice = _mockCurvePoolEmaPrice(_minPrice / 2);
        assertLt(_realPrice, _minPrice, "Ensure mock price is less than min");
        _assertCurvePoolEmaInvariants();
    }

    function test_GetCurvePoolEmaGreaterThanCurvePoolEmaMinimum() public useMultipleSetupFunctions {
        uint256 _minPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolEma();
        uint256 _realPrice = _mockCurvePoolEmaPrice((_minPrice * 3) / 2);
        assertGt(_realPrice, _minPrice, "Ensure mock price is greater than min");
        _assertCurvePoolEmaInvariants();
    }

    function test_CanSet_MinimumCurvePoolEma() public useMultipleSetupFunctions {
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        uint256 _minPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).minimumCurvePoolEma();
        uint256 _newMinPrice = (_minPrice * 8) / 10;
        ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).setMinimumCurvePoolEma(_newMinPrice);
        vm.stopPrank();
        uint256 _realPrice = _mockCurvePoolEmaPrice((_newMinPrice * 8) / 10);
        assertLt(_realPrice, _newMinPrice, "Ensure mock price is less than new min");
        _assertCurvePoolEmaInvariants();
    }

    function test_RevertWith_OnlyTimelock_SetMinimumCurvePoolEma() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).setMinimumCurvePoolEma(5e17);
    }

    function test_GetCurvePoolEmaGreaterThanMaximum() public useMultipleSetupFunctions {
        uint256 _maxPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolEma();
        uint256 _realPrice = _mockCurvePoolEmaPrice((_maxPrice * 3) / 2);
        assertGt(_realPrice, _maxPrice, "Ensure mock price is greater than max");
        _assertCurvePoolEmaInvariants();
    }

    function test_GetCurvePoolEmaLessThanMaximum() public useMultipleSetupFunctions {
        uint256 _maxPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolEma();
        uint256 _realPrice = _mockCurvePoolEmaPrice(_maxPrice / 2);
        assertLt(_realPrice, _maxPrice, "Ensure mock price is less than max");
        _assertCurvePoolEmaInvariants();
    }

    function test_CanSet_MaximumCurvePoolEma() public useMultipleSetupFunctions {
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        uint256 _maxPrice = ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).maximumCurvePoolEma();
        uint256 _newMaxPrice = (_maxPrice * 10) / 8;
        ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).setMaximumCurvePoolEma(_newMaxPrice);
        vm.stopPrank();
        uint256 _realPrice = _mockCurvePoolEmaPrice(_newMaxPrice * 2);
        assertGt(_realPrice, _newMaxPrice, "Ensure mock price is more than new max");
        _assertCurvePoolEmaInvariants();
    }

    function test_RevertWith_OnlyTimelock_SetMaximumCurvePoolEma() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        ICurvePoolEmaPriceOracleWithMinMax(dualOracleAddress).setMaximumCurvePoolEma(5e17);
    }

    function test_DirectionOfCurvePoolEmaUp() external virtual;

    function test_DirectionOfCurvePoolEmaDown() external virtual;
}
