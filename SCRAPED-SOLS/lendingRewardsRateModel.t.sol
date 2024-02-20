//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/Test.sol";

import "../testERC20.sol";
import "../bytesLib.sol";
import { TestHelpers } from "../liquidity/liquidityTestHelpers.sol";
import { LendingRewardsRateModel } from "../../../contracts/protocols/lending/lendingRewardsRateModel/main.sol";
import { Structs as RateModelStructs } from "../../../contracts/protocols/lending/lendingRewardsRateModel/structs.sol";

import { Error } from "../../../contracts/protocols/lending/error.sol";
import { ErrorTypes } from "../../../contracts/protocols/lending/errorTypes.sol";

contract LendingRewardsRateModelTest is Test, TestHelpers {
    LendingRewardsRateModel rateModel;

    uint256 constant INPUT_PARAMS_PERCENT_PRECISION = 1e2;
    uint256 constant PERCENT_PRECISION = 1e2;
    uint256 constant RATE_PRECISION = 1e12;
    uint256 constant MAX_RATE = 25 * RATE_PRECISION; // 25%

    // define decimals for USDC
    uint256 decimals_ = 1e6;

    // define start time in 10 days
    uint256 startTime = block.timestamp + 10 days;
    // define end time 1 year
    uint256 endTime = startTime + 365 days;

    uint256 kink1 = 10_000 * decimals_;
    uint256 kink2 = 50_000 * decimals_;
    uint256 kink3 = 350_000 * decimals_;
    uint256 rateZeroAtTVL = 1_000_000 * decimals_;
    uint256 rateAtTVLZero = 20 * PERCENT_PRECISION;
    uint256 rateAtTVLKink1 = 10 * PERCENT_PRECISION;
    uint256 rateAtTVLKink2 = 5 * PERCENT_PRECISION;
    uint256 rateAtTVLKink3 = 2 * PERCENT_PRECISION;

    uint256 CONSTANT1;
    uint256 SLOPE1;
    uint256 CONSTANT2;
    uint256 SLOPE2;
    uint256 CONSTANT3;
    uint256 SLOPE3;
    uint256 CONSTANT4;
    uint256 SLOPE4;

    function setUp() public virtual {
        uint256 precisionAdjustment_ = RATE_PRECISION / INPUT_PARAMS_PERCENT_PRECISION;

        CONSTANT1 = rateAtTVLZero * precisionAdjustment_;
        SLOPE1 = ((rateAtTVLZero - rateAtTVLKink1) * precisionAdjustment_ * decimals_) / (kink1);
        SLOPE2 = ((rateAtTVLKink1 - rateAtTVLKink2) * precisionAdjustment_ * decimals_) / (kink2 - kink1);
        CONSTANT2 = ((rateAtTVLKink1 * precisionAdjustment_) + ((SLOPE2 * kink1) / decimals_));
        SLOPE3 = ((rateAtTVLKink2 - rateAtTVLKink3) * precisionAdjustment_ * decimals_) / (kink3 - kink2);
        CONSTANT3 = (rateAtTVLKink2 * precisionAdjustment_) + ((SLOPE3 * kink2) / decimals_);
        SLOPE4 = (rateAtTVLKink3 * precisionAdjustment_ * decimals_) / (rateZeroAtTVL - kink3);
        CONSTANT4 = (rateAtTVLKink3 * precisionAdjustment_) + ((SLOPE4 * kink3) / decimals_);
        // Rewards distribution for TVL in USDC
        // [0, 10k) -> [20%, 10%)
        // [10k, 50k) -> [10%, 5%)
        // [50k, 350k) -> [5%, 2%)
        // [350k, 1M) -> [2%, 0%)
        // [1M, ∞] -> [0%, 0%]
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: kink1,
            kink2: kink2,
            kink3: kink3,
            rateZeroAtTVL: rateZeroAtTVL,
            rateAtTVLZero: rateAtTVLZero,
            rateAtTVLKink1: rateAtTVLKink1,
            rateAtTVLKink2: rateAtTVLKink2,
            rateAtTVLKink3: rateAtTVLKink3
        });

        // create rewards contract
        rateModel = new LendingRewardsRateModel(decimals_, startTime, endTime, rateData);
    }

    function test_getConfig() public {
        LendingRewardsRateModel.Config memory rateModelConfig = rateModel.getConfig();
        assertEq(rateModelConfig.assetDecimals, decimals_);
        assertEq(rateModelConfig.maxRate, MAX_RATE);
        assertEq(rateModelConfig.startTime, startTime);
        assertEq(rateModelConfig.endTime, endTime);
        assertEq(rateModelConfig.kink1, kink1);
        assertEq(rateModelConfig.kink2, kink2);
        assertEq(rateModelConfig.kink3, kink3);
        assertEq(rateModelConfig.rateZeroAtTVL, rateZeroAtTVL);
        assertEq(rateModelConfig.slope1, SLOPE1);
        assertEq(rateModelConfig.slope2, SLOPE2);
        assertEq(rateModelConfig.slope3, SLOPE3);
        assertEq(rateModelConfig.slope4, SLOPE4);
        assertEq(rateModelConfig.constant1, CONSTANT1);
        assertEq(rateModelConfig.constant2, CONSTANT2);
        assertEq(rateModelConfig.constant3, CONSTANT3);
        assertEq(rateModelConfig.constant4, CONSTANT4);
    }

    function test_Constructor_RevertIfDecimalsEqualsZero() public {
        decimals_ = 0;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 50 * decimals_, // Invalid: kink1 > kink2
            kink2: 10 * decimals_,
            kink3: 100 * decimals_,
            rateZeroAtTVL: 200 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfStartTimeEqualsZero() public {
        decimals_ = 6;
        uint256 startTime_ = 0;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 50 * decimals_, // Invalid: kink1 > kink2
            kink2: 10 * decimals_,
            kink3: 100 * decimals_,
            rateZeroAtTVL: 200 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfEndTimeEqualsZero() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 50 * decimals_, // Invalid: kink1 > kink2
            kink2: 10 * decimals_,
            kink3: 100 * decimals_,
            rateZeroAtTVL: 200 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfKink1IsGreaterThanKink2() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 50 * decimals_, // Invalid: kink1 > kink2
            kink2: 10 * decimals_,
            kink3: 100 * decimals_,
            rateZeroAtTVL: 200 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfKink2IsGreaterThanKink3() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 10 * decimals_,
            kink2: 100 * decimals_, // Invalid: kink2 > kink3
            kink3: 50 * decimals_,
            rateZeroAtTVL: 200 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfKink3IsGreaterThanRateZeroAtTVL() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 10 * decimals_,
            kink2: 100 * decimals_,
            kink3: 200 * decimals_, // Invalid: kink3 > rateZeroAtTVL
            rateZeroAtTVL: 150 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfExceedMaxRate() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 10 * decimals_,
            kink2: 100 * decimals_,
            kink3: 200 * decimals_,
            rateZeroAtTVL: 250 * decimals_,
            rateAtTVLZero: MAX_RATE + 1, // Invalid: rate above max
            rateAtTVLKink1: 1000,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__MaxRate)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfRateAtTVLZeroIsSmallerThanRateAtTVLKink1() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 10 * decimals_,
            kink2: 100 * decimals_,
            kink3: 200 * decimals_,
            rateZeroAtTVL: 250 * decimals_,
            rateAtTVLZero: 200, // Invalid: rateAtTVLZero < rateAtTVLKink1
            rateAtTVLKink1: 1200,
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfRateAtTVLKink1IsSmallerThanRateAtTVLKink2() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 10 * decimals_,
            kink2: 100 * decimals_,
            kink3: 200 * decimals_,
            rateZeroAtTVL: 250 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 300, // Invalid: rateAtTVLKink1 < rateAtTVLKink2
            rateAtTVLKink2: 700,
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_Constructor_RevertIfRateAtTVLKink2IsSmallerThanRateAtTVLKink3() public {
        decimals_ = 6;
        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = block.timestamp + 30 days;
        RateModelStructs.RateDataParams memory rateData = RateModelStructs.RateDataParams({
            kink1: 10 * decimals_,
            kink2: 100 * decimals_,
            kink3: 200 * decimals_,
            rateZeroAtTVL: 250 * decimals_,
            rateAtTVLZero: 2000,
            rateAtTVLKink1: 1000,
            rateAtTVLKink2: 300, // Invalid: rateAtTVLKink2 < rateAtTVLKink3
            rateAtTVLKink3: 400
        });
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingRewardsRateModel__InvalidParams)
        );
        rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData);
    }

    function test_getRate_BeforeStartTime() public {
        vm.warp(startTime - 1);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(decimals_);
        assertEq(rate, 0);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AfterEndTime() public {
        // Simulate the passage of time beyond the END_TIME
        vm.warp(endTime + 1);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(decimals_);
        assertEq(rate, 0);
        assertTrue(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_WithinTime() public {
        // Simulate the passage of time within the START_TIME and END_TIME range
        vm.warp(startTime + 1);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(decimals_);
        assertFalse(rate == 0);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AssetAmountBelowRateZeroAtTVL() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(rateZeroAtTVL + 1);
        assertEq(rate, 0);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AtTVLZero() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(0);
        assertEq(rate, 20e12);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_LessThanKink1() public {
        vm.warp(startTime);
        uint256 totalAssets_ = 9_000 * decimals_;
        // rate at zero is 20%, at kink1 is 10%, kink1 is at 10_000 * decimals_
        // so at 9_000 * decimals_ rate should be 11%
        uint256 expectedRate_ = 11e12;
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(totalAssets_);
        assertEq(rate, expectedRate_);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AtKink1() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(kink1);
        assertEq(rate, 10e12);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_MoreThanKink1LessThanKink2() public {
        vm.warp(startTime);
        uint256 totalAssets_ = 18_000 * decimals_;
        // rate at kink1 is 10%, kink1 is at 10_000 * decimals_
        // rate at kink2 is 5%, kink2 is at 50_000 * decimals_
        // -> so it reduces 1% per 8_000 decimals_.
        // -> so at 18_000 * decimals_ rate should be 9%
        uint256 expectedRate_ = 9e12;
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(totalAssets_);
        assertEq(rate, expectedRate_);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AtKink2() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(kink2);
        assertEq(rate, 5e12);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_MoreThanKink2LessThanKink3() public {
        vm.warp(startTime);
        uint256 totalAssets_ = 150_000 * decimals_;
        // rate at kink2 is 5%, kink2 is at 50_000 * decimals_
        // rate at kink3 is 2%, kink3 is at 350_000 * decimals_
        // -> so it reduces 1% per 100_000 decimals_.
        // -> so at 150_000 * decimals_ rate should be 4%
        uint256 expectedRate_ = 4e12;
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(totalAssets_);
        assertEq(rate, expectedRate_);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AtKink3() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(kink3);
        assertEq(rate, 2e12);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_MoreThanKink3() public {
        vm.warp(startTime);
        uint256 totalAssets_ = 675_000 * decimals_;
        // rate at kink3 is 2%, kink3 is at 350_000 * decimals_
        // rate becomes zero at TVL 1_000_000 * decimals
        // -> so over 650_000 it reduces 2% so rate should be 1% at 350_000 + 650_000 / 2 = 675_000 decimals
        uint256 expectedRate_ = 1e12;
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(totalAssets_);
        // for towards RateZeroAtTVL calculation becomes a tiny bit less accurate but still accurate enough.
        // allow 1e5 difference
        assertApproxEqAbs(rate, expectedRate_, 1e5);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AtRateZeroAtTVL() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(rateZeroAtTVL);
        // for RateZeroAtTVL calculation becomes a tiny bit less accurate but still accurate enough.
        // allow 1e5 difference
        assertApproxEqAbs(rate, 0, 1e5);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }

    function test_getRate_AboveRateZeroAtTVL() public {
        vm.warp(startTime);
        (uint256 rate, bool ended, uint256 returnStartTime) = rateModel.getRate(rateZeroAtTVL + 100_000 * decimals_);
        assertEq(rate, 0);
        assertFalse(ended);
        assertEq(startTime, returnStartTime);
    }
}
