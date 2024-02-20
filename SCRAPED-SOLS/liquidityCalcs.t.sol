//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { LiquidityCalcsTestHelper } from "./liquidityCalcsTestHelper.sol";
import { LiquiditySimulateStorageSlot } from "../../liquidity/liquidityTestHelpers.sol";
import { AuthInternals } from "../../../../contracts/liquidity/adminModule/main.sol";
import { Structs as AdminModuleStructs } from "../../../../contracts/liquidity/adminModule/structs.sol";
import { LiquidityCalcs } from "../../../../contracts/libraries/liquidityCalcs.sol";

import "forge-std/console2.sol";

contract LibraryLiquidityCalcsBaseTest is Test, LiquiditySimulateStorageSlot {
    // use testHelper contract to measure gas for library methods via forge --gas-report
    LiquidityCalcsTestHelper testHelper;

    function setUp() public {
        testHelper = new LiquidityCalcsTestHelper();
    }
}

contract LibraryLiquidityCalcsTokenDataTests is LibraryLiquidityCalcsBaseTest {
    uint256 constant DEFAULT_PERCENT_PRECISION = 1e2;
    uint256 constant HUNDRED_PERCENT = 100 * DEFAULT_PERCENT_PRECISION;
    uint256 constant DEFAULT_FEE = 50 * DEFAULT_PERCENT_PRECISION; // 50%
    uint256 constant EXCHANGE_PRICES_PRECISION = 1e12;

    uint256 constant supplyInterestFree = 2 ether;
    uint256 constant borrowInterestFree = 1 ether;

    function testLiquidityCalcs_calcExchangePrices() public {
        vm.warp(block.timestamp + 2000 days); // skip ahead to not cause an underflow for last update timestamp

        uint256 exchangePricesAndConfig;

        uint256 supplyWithInterestRaw = 10 ether;
        uint256 borrowWithInterestRaw = 8 ether;

        exchangePricesAndConfig = _simulateExchangePricesAndConfig(
            10 * DEFAULT_PERCENT_PRECISION, // borrow rate
            DEFAULT_FEE, // fee
            (HUNDRED_PERCENT * (borrowWithInterestRaw + borrowInterestFree)) /
                (supplyWithInterestRaw + supplyInterestFree), // utilization
            1 * DEFAULT_PERCENT_PRECISION, // updateOnStorageThreshold
            block.timestamp - 182.5 days, // last update timestamp -> half a year ago
            EXCHANGE_PRICES_PRECISION, // supplyExchangePrice
            EXCHANGE_PRICES_PRECISION, // borrowExchangePrice
            // supply ratio mode: if 0 then supplyInterestFree / supplyWithInterestRaw else supplyWithInterestRaw / supplyInterestFree
            // ratio always divides by bigger amount, ratio can never be > 100%
            supplyWithInterestRaw > supplyInterestFree ? 0 : 1,
            supplyWithInterestRaw > supplyInterestFree
                ? (supplyInterestFree * HUNDRED_PERCENT) / supplyWithInterestRaw
                : (supplyWithInterestRaw * HUNDRED_PERCENT) / supplyInterestFree,
            borrowWithInterestRaw > borrowInterestFree ? 0 : 1,
            borrowWithInterestRaw > borrowInterestFree
                ? (borrowInterestFree * HUNDRED_PERCENT) / borrowWithInterestRaw
                : (borrowWithInterestRaw * HUNDRED_PERCENT) / borrowInterestFree
        );

        (uint256 supplyExchangePrice, uint256 borrowExchangePrice) = testHelper.calcExchangePrices(
            exchangePricesAndConfig
        );

        console2.log("borrowExchangePrice", borrowExchangePrice);
        // borrow exchange price should be:
        // 8 ether paying 10% borrow rate in 1 year so 0.4 in half a year
        // so 8 raw * borrowExchangePrice = 8.4 -> borrowExchange price must be 1.05
        assertEq(borrowExchangePrice, 1.05e12);

        console2.log("supplyExchangePrice", supplyExchangePrice);
        // supply exchange price should be:
        // supply rate should be 10% - fee 50% = 5%. and only 75% is lent out with yield so 3,75%.
        // and only 8 out of 9 borrow are paying yield so 3,75*8/9 = 3,3333%
        // but 1/6 of supply is not getting the yield so 3,33%*6/5 = 4%
        // and for half the year only that would be 2%. so supplyExchangePrice must be 1.02.
        // or as cross-check:
        // 0.4 ether borrowing interest, but 50% of that are kept as fee -> so 0.2 yield.
        // total supply should end up 12.2 ether. With supplyInterestFree still 2 ether,
        // supplyWithInterest 10.2 ether.
        // so 10 raw * supplyExchangePrice = 10.2 -> supplyExchangePrice price must be 1.02
        assertEq(supplyExchangePrice, 1.02e12);

        // raw amounts to normal for updated exchange prices ->
        supplyWithInterestRaw = (supplyWithInterestRaw * supplyExchangePrice) / 1e12;
        borrowWithInterestRaw = (borrowWithInterestRaw * borrowExchangePrice) / 1e12;

        // assuming another half year has passed, starting exchange prices are not 1
        exchangePricesAndConfig = _simulateExchangePricesAndConfig(
            10 * DEFAULT_PERCENT_PRECISION, // borrow rate
            DEFAULT_FEE, // fee
            (HUNDRED_PERCENT * (borrowWithInterestRaw + borrowInterestFree)) /
                (supplyWithInterestRaw + supplyInterestFree), // utilization
            1 * DEFAULT_PERCENT_PRECISION, // updateOnStorageThreshold
            block.timestamp - 182.5 days, // last update timestamp -> half a year ago
            supplyExchangePrice, // supplyExchangePrice
            borrowExchangePrice, // borrowExchangePrice
            // supply ratio mode: if 0 then supplyInterestFree / supplyWithInterestRaw else supplyWithInterestRaw / supplyInterestFree
            // ratio always divides by bigger amount, ratio can never be > 100%
            supplyWithInterestRaw > supplyInterestFree ? 0 : 1,
            supplyWithInterestRaw > supplyInterestFree
                ? (supplyInterestFree * HUNDRED_PERCENT) / supplyWithInterestRaw
                : (supplyWithInterestRaw * HUNDRED_PERCENT) / supplyInterestFree,
            borrowWithInterestRaw > borrowInterestFree ? 0 : 1,
            borrowWithInterestRaw > borrowInterestFree
                ? (borrowInterestFree * HUNDRED_PERCENT) / borrowWithInterestRaw
                : (borrowWithInterestRaw * HUNDRED_PERCENT) / borrowInterestFree
        );

        (supplyExchangePrice, borrowExchangePrice) = testHelper.calcExchangePrices(exchangePricesAndConfig);

        console2.log("borrowExchangePrice", borrowExchangePrice);
        // borrow exchange price should be:
        // 8.4 ether paying 10% borrow rate in 1 year so 0.42 in half a year
        // so 8 raw * borrowExchangePrice = 8.82 -> borrowExchange price must be 1.1025
        assertEq(borrowExchangePrice, 1.1025e12);

        console2.log("supplyExchangePrice", supplyExchangePrice);
        // supply exchange price should be:
        // 0.42 ether new borrowings, but 50% of that are kept as fee -> so 0.21 yield
        // so 10 raw * supplyExchangePrice = 10.41 -> supplyExchangePrice price must be 1.041
        assertApproxEqAbs(supplyExchangePrice, 1.041e12, 1e7);
    }
}

contract LibraryLiquidityCalcsWithdrawalLimitTests is LibraryLiquidityCalcsBaseTest {
    function testLiquidityCalcs_CalcWithdrawalLimitCombination() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 expandPercentage = 20 * 1e2; // 20%
        uint256 baseLimit = 5 ether;
        uint256 expandDuration = 200 seconds;

        console2.log("-------------------------------");
        console2.log("Config expandPercentage 20%", expandPercentage);
        console2.log("Config baseLimit 5 ether", baseLimit);
        console2.log("Config expandDuration 200 seconds", expandDuration);

        uint256 previousLimit = 0;
        uint256 lastUpdateTimestamp = 0;

        console2.log("\n--------- Simualate 1. action: deposit of 1 ether ---------");
        uint256 userSupply = 0;

        uint256 userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 0);

        userSupply = 1 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 0);

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 100);
        console2.log("--------- TIME WARP 100 seconds ---------");

        console2.log("\n--------- Simualate 2. action: deposit of 4.5 ether to 5.5 ether total ---------");
        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 0);

        userSupply += 4.5 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 4.4 ether); // fully expanded immediately because of deposits only

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1);
        console2.log("--------- TIME WARP 1 seconds ---------");

        console2.log("\n--------- Simualate 3. action: deposit of 0.5 ether to 6 ether total ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 4.4 ether); // fully expanded immediately because of deposits only

        userSupply += 0.5 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 4.8 ether); // fully expanded immediately because of deposits only

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1);
        console2.log("--------- TIME WARP 1 seconds ---------");

        console2.log("\n--------- Simualate 4. action: withdraw 0.01 ether to total 5.99 ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 4.8 ether); // fully expanded immediately because of deposits only

        userSupply -= 0.01 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 4.8 ether); // triggered expansion from 4.8 down

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 200);
        console2.log("--------- TIME WARP 200 seconds ---------");

        console2.log("\n--------- Simualate 5. action: deposit of 1.01 ether to 7 ether total ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 4.792 ether); // fully expanded from 5.99

        userSupply += 1.01 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 5.6 ether); // fully expanded immediately because of deposits only

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1);
        console2.log("--------- TIME WARP 1 seconds ---------");

        console2.log("\n--------- Simualate 6. action: withdraw 1.4 ether down to 5.6 total ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 5.6 ether); // fully expanded immediately because of deposits only

        userSupply -= 1.4 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 5.6 ether); // last withdrawal limit used as point to expand from

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 40);
        console2.log("--------- TIME WARP 40 seconds (20% of 20% epanded, 0.224 down to 5.376) ---------\n");

        console2.log("\n--------- Simualate 7. action: withdraw 0.1 ether down to 5.5 total ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 5.376 ether); // last withdrawal limit 5.6 20% of 20% epanded, 0.224 down to 5.376

        userSupply -= 0.1 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 5.376 ether); // last withdrawal limit used as point to expand from

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 200);
        console2.log("--------- TIME WARP 200 seconds (full expansion to 4.4) ---------");

        console2.log("\n--------- Simualate 8. action: withdraw 0.51 ether down to 4.99 total ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 4.4 ether); // fully expanded from 5.5

        userSupply -= 0.51 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 0); // below base limit so 0

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1);
        console2.log("--------- TIME WARP 1 seconds ---------");

        console2.log("\n--------- Simualate 9. action: withdraw 4.99 ether down to 0 total ---------");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 0); // below base limit so 0

        userSupply -= 4.99 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 0); // below base limit so 0
    }

    function testLiquidityCalcs_CalcWithdrawalLimitAfterOperate() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 previousLimit = 0; // not used in calcWithdrawalLimitAfterOperate
        uint256 lastUpdateTimestamp = block.timestamp; // not used in calcWithdrawalLimitAfterOperate
        uint256 expandDuration = 200 seconds; // not used in calcWithdrawalLimitAfterOperate

        uint256 userSupply = 5.5 ether;
        uint256 expandPercentage = 20 * 1e2; // 20%
        uint256 baseLimit = 2 ether;
        uint256 beforeOperateWithdrawalLimit = 0;

        uint256 userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );

        uint256 limit = testHelper.calcWithdrawalLimitAfterOperate(
            userSupplyData,
            userSupply,
            beforeOperateWithdrawalLimit
        );

        console2.log("limit", limit);
    }

    function testLiquidityCalcs_CalcWithdrawalLimitBeforeOperate() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 userSupply = 10 ether;
        uint256 previousLimit = 9.5 ether;
        uint256 lastUpdateTimestamp = block.timestamp - 100;
        uint256 expandPercentage = 20 * 1e2; // 20%
        uint256 expandDuration = 200 seconds;
        uint256 baseLimit = 2 ether;

        uint256 userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );

        uint256 limit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);

        console2.log("limit", limit);
    }

    function testLiquidityCalcs_CalcWithdrawalLimitBeforeOperate1() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 userSupply = 5.5 ether;
        uint256 previousLimit = 0;
        uint256 lastUpdateTimestamp = block.timestamp;
        uint256 expandPercentage = 20 * 1e2; // 20% -> down to 4,4
        uint256 expandDuration = 200 seconds;
        uint256 baseLimit = 5 ether;

        uint256 userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );

        uint256 limit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);

        console2.log("limit", limit);
    }

    function testLiquidityCalcs_CalcWithdrawalLimitBeforeOperate2() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 userSupply = 5.5 ether;
        uint256 previousLimit = 4.4 ether;
        uint256 lastUpdateTimestamp = block.timestamp - 100; // half time passed
        uint256 expandPercentage = 20 * 1e2; // 20% -> down to 4,4
        uint256 expandDuration = 200 seconds;
        uint256 baseLimit = 5 ether;

        uint256 userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );

        uint256 limit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);

        console2.log("limit", limit);
    }

    function testLiquidityCalcs_CalcWithdrawalLimit_FirstTimeAboveBaseLimit() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 expandPercentage = 10 * 1e2; // 10%
        uint256 expandDuration = 200 seconds;
        uint256 baseLimit = 5 ether;

        console2.log("-------------------------------");
        console2.log("Config expandPercentage 10%", expandPercentage);
        console2.log("Config baseLimit 5 ether", baseLimit);
        console2.log("Config expandDuration 200 seconds", expandDuration);

        uint256 previousLimit = 0;
        uint256 lastUpdateTimestamp = 0;

        console2.log("\n--------- Simualate 1. action: deposit of 6 ether ---------");
        uint256 userSupply = 0;

        uint256 userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );

        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 0);

        userSupply = 6 ether;
        console2.log("userSupply", userSupply);
        assertEq(userSupply >= previousLimit, true, "USER SUPPLY IS < LIMIT");

        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitAfterOperate(userSupplyData, userSupply, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 5.4 ether);

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 100);
        console2.log("--------- TIME WARP 100 seconds ---------");

        console2.log("\n--------- Simualate 2. action: check before operate limit ---------");
        userSupplyData = _simulateUserSupplyDataFull(
            1,
            userSupply,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            false
        );
        previousLimit = testHelper.calcWithdrawalLimitBeforeOperate(userSupplyData, userSupply);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 5.4 ether);
    }
}

contract LibraryLiquidityCalcsBorrowLimitTests is LibraryLiquidityCalcsBaseTest {
    function testLiquidityCalcs_CalcBorrowLimitCombination() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 expandPercentage = 20 * 1e2; // 20%
        uint256 baseLimit = 5 ether;
        uint256 maxLimit = 7 ether;
        uint256 expandDuration = 200 seconds;

        console2.log("-------------------------------");
        console2.log("Config expandPercentage 20%", expandPercentage);
        console2.log("Config baseLimit 5 ether", baseLimit);
        console2.log("Config maxLimit 7 ether", maxLimit);
        console2.log("Config expandDuration 200 seconds", expandDuration);

        uint256 previousLimit = 0;
        uint256 lastUpdateTimestamp = 0;

        console2.log(
            "\n--------- Simualate 1. action: borrow of 4.18 ether, expands to 5.01 (above base limit) ---------"
        );
        uint256 userBorrow = 0;

        uint256 userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, baseLimit, 1e16); // allow BigMath precision delta

        userBorrow = 4.18 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, baseLimit, 1e16); // allow BigMath precision delta

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 200);
        console2.log("--------- TIME WARP 200 seconds ---------");

        console2.log("\n--------- Simualate 2. action: borrow of 0.82 ether to 5 ether total ---------");
        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertEq(previousLimit, 5.016 ether); // fully expanded from 4.18 to 5.016 ether (not base limit)

        userBorrow += 0.82 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertEq(previousLimit, 5.016 ether); // fully expanded from 4.18 to 5.016 ether (not base limit)

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 97); // tiny bit less than half to get closest to 5.5 & make up for 0.016 already as last limit
        console2.log("--------- TIME WARP 97 seconds (half expanded) ---------");

        console2.log("\n--------- Simualate 3. action: borrow of 0.5 ether to 5.5 ether total ---------");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 5.5 ether, 1e16); // allow BigMath precision delta

        userBorrow += 0.5 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 5.5 ether, 1e16); // allow BigMath precision delta

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1);
        console2.log("--------- TIME WARP 1 seconds ---------");

        console2.log("\n--------- Simualate 4. action: payback 0.01 ether to total 5.49 ---------");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 5.5 ether, 1e16); // allow BigMath precision delta

        userBorrow -= 0.01 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 5.5 ether, 1e16); // allow BigMath precision delta right after still 5.5 ether

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 200);
        console2.log("--------- TIME WARP 200 seconds (full expansion to 6.588 limit) ---------");

        console2.log("\n--------- Simualate 5. action: borrow of 1.01 ether to 6.5 ether total ---------");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 6.588 ether, 1e16); // 5.49 * 1.2 -> 6,588

        userBorrow += 1.01 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 6.588 ether, 1e16); // 5.49 * 1.2 -> 6,588

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 200);
        console2.log(
            "--------- TIME WARP 200 seconds (max expansion to 7.8 ether but max limit of 7 ether gets active)  ---------"
        );

        console2.log("\n--------- Simualate 6. action: borrow 0.49 ether up to max limit of 7 total ---------");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 7 ether, 1e16); // max limit of 7 ether with BigMath imprecision

        userBorrow += 0.49 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 7 ether, 1e16); // max limit of 7 ether with BigMath imprecision

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 200);
        console2.log("--------- TIME WARP 200 seconds ---------");

        console2.log(
            "\n--------- Simualate 7. action: borrow 0.01 ether would fail even after expansion (above max limit) ---------"
        );

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 7 ether, 1e16, "Limit is not ~7 ether");

        console2.log("\n--------- Simualate 8. action: payback 1.49 ether down to 5.5 total ---------");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 7 ether, 1e16, "Limit is not ~7 ether");

        userBorrow -= 1.49 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 6.6 ether, 1e16, "Limit is not ~6.6 ether"); // immediately shrinked to full expansion 5.5 * 1.2 = 6.6

        lastUpdateTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1);
        console2.log("--------- TIME WARP 1 seconds ---------");

        console2.log("\n--------- Simualate 9. action: payback 5.5 ether down to 0 total ---------");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, 6.6 ether, 1e16, "Limit is not ~6.6 ether"); // immediately shrinked to full expansion 5.5 * 1.2 = 6.6

        userBorrow -= 5.5 ether;
        console2.log("userBorrow", userBorrow);
        assertEq(userBorrow < previousLimit, true, "USER BORROW IS > LIMIT");

        userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitAfterOperate(userBorrowData, userBorrow, previousLimit);
        console2.log("AFTER operate limit", previousLimit);
        assertApproxEqAbs(previousLimit, baseLimit, 1e16, "Limit is not baseLimit"); // immediately shrinked to base limit
    }

    function testLiquidityCalcs_CalcBorrowLimitFirstAction() public {
        vm.warp(block.timestamp + 10_000); // skip ahead to not cause an underflow for last update timestamp

        uint256 expandPercentage = 20 * 1e2; // 20%
        uint256 baseLimit = 5 ether;
        uint256 maxLimit = 7 ether;
        uint256 expandDuration = 200 seconds;
        uint256 previousLimit = 0; // previous limit is not set at config
        uint256 lastUpdateTimestamp = 0; // last update timestamp is 0 at first interaction (not set at config)
        uint256 userBorrow = 0; // user borrow amount at first action can only be 0 still

        uint256 userBorrowData = _simulateUserBorrowDataFull(
            1,
            userBorrow,
            previousLimit,
            lastUpdateTimestamp,
            expandPercentage,
            expandDuration,
            baseLimit,
            maxLimit,
            false
        );
        previousLimit = testHelper.calcBorrowLimitBeforeOperate(userBorrowData, userBorrow);
        console2.log("BEFORE operate limit first action (should be ~5 ether base limit)", previousLimit);
        assertApproxEqAbs(previousLimit, baseLimit, 1e16); // allow BigMath precision delta
    }
}

contract LibraryLiquidityCalcsRateV1Tests is LibraryLiquidityCalcsBaseTest, AuthInternals {
    uint256 constant _DEFAULT_PERCENT_PRECISION = 1e2;
    uint256 constant _DEFAULT_KINK = 80 * _DEFAULT_PERCENT_PRECISION; // 80%
    uint256 constant _DEFAULT_RATE_AT_ZERO = 4 * _DEFAULT_PERCENT_PRECISION; // 4%
    uint256 constant _DEFAULT_RATE_AT_KINK = 10 * _DEFAULT_PERCENT_PRECISION; // 10%
    uint256 constant _DEFAULT_RATE_AT_MAX = 150 * _DEFAULT_PERCENT_PRECISION; // 150%

    // test with AuthInternals utilization 70% etc.
    function testLiquidityCalcs_CalcRateV1() public {
        AdminModuleStructs.RateDataV1Params memory rataDataV1Params = AdminModuleStructs.RateDataV1Params(
            address(1),
            _DEFAULT_KINK,
            _DEFAULT_RATE_AT_ZERO,
            _DEFAULT_RATE_AT_KINK,
            _DEFAULT_RATE_AT_MAX
        );

        uint256 rateData = _computeRateDataPackedV1(rataDataV1Params);
        uint256 utilization = 90 * _DEFAULT_PERCENT_PRECISION; // 90%

        uint256 rate = testHelper.calcRateV1(rateData, utilization);

        console2.log("rate", rate);

        // rate should be rate at kink + half of 10% to 150% at 100%  -> 140% / 2 = 70% + 10% = 80%
        assertEq(rate, 80 * _DEFAULT_PERCENT_PRECISION);
    }
}

contract LibraryLiquidityCalcsRateV2Tests is LibraryLiquidityCalcsBaseTest, AuthInternals {
    uint256 constant _DEFAULT_PERCENT_PRECISION = 1e2;
    uint256 constant _DEFAULT_KINK = 80 * _DEFAULT_PERCENT_PRECISION; // 80%
    uint256 constant _DEFAULT_RATE_AT_ZERO = 4 * _DEFAULT_PERCENT_PRECISION; // 4%
    uint256 constant _DEFAULT_RATE_AT_KINK = 10 * _DEFAULT_PERCENT_PRECISION; // 10%
    uint256 constant _DEFAULT_RATE_AT_MAX = 150 * _DEFAULT_PERCENT_PRECISION; // 150%
    uint256 constant _DEFAULT_KINK2 = 90 * _DEFAULT_PERCENT_PRECISION; // 90%
    uint256 constant _DEFAULT_RATE_AT_KINK2 = 80 * _DEFAULT_PERCENT_PRECISION; // 10% + half way to 150% = 80% for data compatibility with v1

    // test with AuthInternals utilization 70% etc.
    function testLiquidityCalcs_CalcRateV2() public {
        AdminModuleStructs.RateDataV2Params memory rataDataV2Params = AdminModuleStructs.RateDataV2Params(
            address(1),
            _DEFAULT_KINK,
            _DEFAULT_KINK2,
            _DEFAULT_RATE_AT_ZERO,
            _DEFAULT_RATE_AT_KINK,
            _DEFAULT_RATE_AT_KINK2,
            _DEFAULT_RATE_AT_MAX
        );

        uint256 rateData = _computeRateDataPackedV2(rataDataV2Params);
        uint256 utilization = 95 * _DEFAULT_PERCENT_PRECISION; // 95%

        uint256 rate = testHelper.calcRateV2(rateData, utilization);

        console2.log("rate", rate);

        // rate should be rate at kink2 + half of 80% to 150% at 100%  -> 70% / 2 = 35% + 80% = 115%
        assertEq(rate, 115 * _DEFAULT_PERCENT_PRECISION);
    }
}
