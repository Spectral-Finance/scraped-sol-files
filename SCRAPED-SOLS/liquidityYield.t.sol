//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Structs as AdminModuleStructs } from "../../../../contracts/liquidity/adminModule/structs.sol";
import { AuthModule, AdminModule } from "../../../../contracts/liquidity/adminModule/main.sol";
import { Structs as ResolverStructs } from "../../../../contracts/periphery/resolvers/liquidity/structs.sol";
import { ErrorTypes } from "../../../../contracts/liquidity/errorTypes.sol";
import { Error } from "../../../../contracts/liquidity/error.sol";
import { LiquidityUserModuleBaseTest } from "./liquidityUserModuleBaseTest.t.sol";
import { BigMathMinified } from "../../../../contracts/libraries/bigMathMinified.sol";

import "forge-std/console2.sol";

contract LiquidityUserModuleYieldTests is LiquidityUserModuleBaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_operate_ExchangePriceSupplyWithInterestOnly() public {
        // alice supplies liquidity
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // at 1% utilization, for default values of 4% at 0% utilization and 10% at 80% utilization.
        // so over the range of 80%, the rate grows 6% linearly.
        // 80 = 6, 1 = x => x = 6 / 80 * 1 = 0,075
        // so 4% + 0.075% = 4.075%
        // but borrow rate precision in Liquidity is only 0.01% so it becomes 4.07%.
        // with supplyExchangePrice increasing 1% of that because only 1% of supply is borrowed out

        uint256 expectedBorrowExchangePrice = 1040700000000;
        uint256 expectedSupplyExchangePrice = 1000407000000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceSupplyInterestFreeOnly() public {
        // alice supplies liquidity
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        // with supplyExchangePrice staying the same as no suppliers that earn any interest
        uint256 expectedSupplyExchangePrice = 1e12;
        uint256 expectedBorrowExchangePrice = 1040700000000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceNumberUpOnlyWhenNoStorageUpdate() public {
        // alice supplies liquidity
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // set storage update threshold to 5%
        AdminModuleStructs.TokenConfig[] memory tokenConfigs = new AdminModuleStructs.TokenConfig[](1);
        tokenConfigs[0] = AdminModuleStructs.TokenConfig({
            token: address(USDC),
            fee: 0, // no fee for simplicity
            threshold: DEFAULT_STORAGE_UPDATE_THRESHOLD * 5 // 5%
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateTokenConfigs(tokenConfigs);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME / 1000);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        // just divided by 1000 to be below forced storage update if time diff > 1 day
        // 407000000 / 1000 = 407000
        uint256 expectedSupplyExchangePrice = 1000000407000; // increased 1% of borrow exchange price (because 1% of supply is borrowed out)
        uint256 expectedBorrowExchangePrice = 1000040700000;

        uint256 exchangePricesAndConfigBefore = resolver.getExchangePricesAndConfig(address(USDC));

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);

        // no storage update happening but that must not cause any issue with supplyExchangePrice

        // assert exchangePricesAndConfig had no storage update
        assertEq(exchangePricesAndConfigBefore, resolver.getExchangePricesAndConfig(address(USDC)));

        vm.prank(alice);
        (uint256 supplyExchangePrice2, uint256 borrowExchangePrice2) = mockProtocolWithInterest.operate(
            address(USDC),
            int256(DEFAULT_SUPPLY_AMOUNT),
            0,
            address(0),
            address(0),
            abi.encode(alice)
        );

        assertGe(supplyExchangePrice2, expectedSupplyExchangePrice);
        assertGe(borrowExchangePrice2, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenSupplyWithInterestBigger() public {
        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 80);

        // alice supplies liquidity interest free
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 20);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 / 10 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME / 10);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        // just here we only warp 1/10 of the year so 10% of the increase.
        uint256 expectedBorrowExchangePrice = 1004070000000;
        // total earnings for suppliers are 1% of borrow increase. But only 80% of suppliers earn that.
        // so exchange price must grow 25% more to account for that: 407000000 * 1.25 = 508750000
        // only 1/10 of year has passed so 10% of that = 50875000
        uint256 expectedSupplyExchangePrice = 1000050875000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenSupplyInterestFreeBigger() public {
        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 20);

        // alice supplies liquidity interest free
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 80);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase. But only 20% of suppliers earn that.
        // so exchange price must grow 5x more to account for that: 407000000 * 5 = 2035000000
        uint256 expectedSupplyExchangePrice = 1002035000000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenSupplyWithInterestExactlySupplyInterestFree() public {
        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 50);

        // alice supplies liquidity interest free
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 50);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase. But only 50% of suppliers earn that.
        // so exchange price must grow 2x more to account for that: 407000000 * 2 = 814000000
        uint256 expectedSupplyExchangePrice = 1000814000000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenSupplyWithInterestBiggerWithRevenueFee() public {
        // set revenue fee to 10%
        AdminModuleStructs.TokenConfig[] memory tokenConfigs = new AdminModuleStructs.TokenConfig[](1);
        tokenConfigs[0] = AdminModuleStructs.TokenConfig({
            token: address(USDC),
            fee: 10 * DEFAULT_PERCENT_PRECISION,
            threshold: 0
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateTokenConfigs(tokenConfigs);

        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 80);

        // alice supplies liquidity interest free
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 20);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase MINUS the revenue fee.
        // so 40700000000 * 1% - 10% = 366300000. But only 80% of suppliers earn that.
        // so exchange price must grow 25% more to account for that: 366300000 * 1.25 = 457875000
        uint256 expectedSupplyExchangePrice = 1000457875000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenSupplyInterestFreeBiggerWithRevenueFee() public {
        // set revenue fee to 10%
        AdminModuleStructs.TokenConfig[] memory tokenConfigs = new AdminModuleStructs.TokenConfig[](1);
        tokenConfigs[0] = AdminModuleStructs.TokenConfig({
            token: address(USDC),
            fee: 10 * DEFAULT_PERCENT_PRECISION,
            threshold: 0
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateTokenConfigs(tokenConfigs);

        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 20);

        // alice supplies liquidity interest free
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 80);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase MINUS the revenue fee.
        // so 40700000000 * 1% - 10% = 366300000. But only 20% of suppliers earn that.
        // so exchange price must grow 5x more to account for that: 366300000 * 5 = 1831500000
        uint256 expectedSupplyExchangePrice = 1001831500000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceSequences() public {
        // alice supplies liquidity
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 10);

        // total supply 10 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for exchange price calculation.
        // 10% utilization borrow rate => x = 6 / 80 * 10 = 0,75. 4 + 0.75 => 4.75%
        // with 10% of supply earning yield
        uint256 expectedBorrowExchangePrice = 1047500000000;
        uint256 expectedSupplyExchangePrice = 1004750000000;

        // deposits DEFAULT_BORROW_AMOUNT
        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);

        // utilization here increased to:
        // total borrow = DEFAULT_BORROW_AMOUNT * 1047500000000 / 1e12 = 0,52375
        // total supply = 10 * DEFAULT_BORROW_AMOUNT * 1004750000000 / 1e12 + DEFAULT_BORROW_AMOUNT
        // = 5,02375 ether + 0,5 ether = 5,52375
        // utilization = 0,52375 / 5,52375 = 9,4817%; cut off precision to 0.01%-> 9,48%.
        // so borrow rate:
        // at 9,48% utilization x = 6 / 80 * 9,48% = 0.711
        // so 4% + 0.711% = 4.711% but cut off precision to 0.01%-> 4,71%.

        // simulate passing time 1 year for yield again
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        expectedBorrowExchangePrice = (1047500000000 * (1e4 + 471)) / 1e4;
        // same multiplicator here for supple exchange price as no revenue fee and only with interest suppliers.
        // only 9.48% of supply is borrowed out though so
        // increase in supplyExchangePrice = ((1004750000000 * 471 * 948) / 1e4 / 1e4) =    4486289130
        expectedSupplyExchangePrice = 1004750000000 + 4486289130; // = 1009236289130

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    // function test_operate_ExchangePriceBorrowWithInterestOnly() public {
    // already covered by tests for supply exchange prices as they use borrow with interest only
    // }

    function test_operate_ExchangePriceBorrowInterestFreeOnly() public {
        // alice supplies liquidity
        _supply(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity
        _borrow(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // both exchange prices should be initial value as there is no yield.
        uint256 expectedSupplyExchangePrice = 1e12;
        uint256 expectedBorrowExchangePrice = 1e12;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenBorrowWithInterestBigger() public {
        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity with interest
        _borrow(mockProtocolWithInterest, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 8) / 10);

        // alice borrows liquidity interest free
        _borrow(mockProtocolInterestFree, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 2) / 10);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase (1% is lent out).
        // But only 80% of the borrowers pay the yield.
        // so exchange price must grow 20% less to account for that:
        // supplyRate = 4,07% * 0,8 = 3,256%. so supplyIncrease = 325600000
        uint256 expectedSupplyExchangePrice = 1000325600000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenBorrowInterestFreeBigger() public {
        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity with interest
        _borrow(mockProtocolWithInterest, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 2) / 10);

        // alice borrows liquidity interest free
        _borrow(mockProtocolInterestFree, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 8) / 10);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase (1% is lent out).
        // But only 20% of the borrowers pay the yield.
        // so exchange price must grow 80% less to account for that: 407000000 * 0.2 = 81400000
        uint256 expectedSupplyExchangePrice = 1000081400000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenBorrowWithInterestExacltyBorrowInterestFree() public {
        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity with interest
        _borrow(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT / 2);

        // alice borrows liquidity interest free
        _borrow(mockProtocolInterestFree, address(USDC), alice, DEFAULT_BORROW_AMOUNT / 2);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for borrow exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // total earnings for suppliers are 1% of borrow increase. But only 50% of borrowers pay that.
        // so exchange price must grow half to account for that: 407000000 / 2 = 203500000
        uint256 expectedSupplyExchangePrice = 1000203500000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenBorrowWithInterestBiggerWithRevenue() public {
        // set revenue fee to 10%
        AdminModuleStructs.TokenConfig[] memory tokenConfigs = new AdminModuleStructs.TokenConfig[](1);
        tokenConfigs[0] = AdminModuleStructs.TokenConfig({
            token: address(USDC),
            fee: 10 * DEFAULT_PERCENT_PRECISION,
            threshold: 0
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateTokenConfigs(tokenConfigs);

        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity with interest
        _borrow(mockProtocolWithInterest, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 8) / 10);

        // alice borrows liquidity interest free
        _borrow(mockProtocolInterestFree, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 2) / 10);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // 10% of total earnings go to revenue so 4,07% * 0,9 = 3,663%
        // and only 1% total is lent out so 3,663% *0,01 = 0,03663%
        // But only 80% of the borrowers pay the yield. so rate must grow 20% less: 0,03663% *0,8 = 0,029304%
        // so supplyRate 0,029304%. so supplyIncrease = 293040000
        uint256 expectedSupplyExchangePrice = 1000293040000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function test_operate_ExchangePriceWhenBorrowInterestFreeBiggerWithRevenue() public {
        // set revenue fee to 10%
        AdminModuleStructs.TokenConfig[] memory tokenConfigs = new AdminModuleStructs.TokenConfig[](1);
        tokenConfigs[0] = AdminModuleStructs.TokenConfig({
            token: address(USDC),
            fee: 10 * DEFAULT_PERCENT_PRECISION,
            threshold: 0
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateTokenConfigs(tokenConfigs);

        // alice supplies liquidity with interest
        _supply(mockProtocolWithInterest, address(USDC), alice, DEFAULT_BORROW_AMOUNT * 100);

        // total supply 100 * DEFAULT_BORROW_AMOUNT.

        // alice borrows liquidity with interest
        _borrow(mockProtocolWithInterest, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 2) / 10);

        // alice borrows liquidity interest free
        _borrow(mockProtocolInterestFree, address(USDC), alice, (DEFAULT_BORROW_AMOUNT * 8) / 10);

        // simulate passing time 1 year for yield
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // see test_operate_ExchangePriceSupplyWithInterestOnly for exchange price calculation.
        uint256 expectedBorrowExchangePrice = 1040700000000;
        // 10% of total earnings go to revenue so 40700000000 * 0.9 = 36630000000
        // total earnings for suppliers are 1% of borrow increase (1% is lent out). so 366300000
        // But only 20% of the borrowers pay the yield.
        // so exchange price must grow 80% less to account for that: 366300000 * 0.2 = 73260000
        uint256 expectedSupplyExchangePrice = 1000073260000;

        _assertExchangePrices(expectedSupplyExchangePrice, expectedBorrowExchangePrice);
    }

    function _assertExchangePrices(uint256 expectedSupplyExchangePrice, uint256 expectedBorrowExchangePrice) internal {
        vm.prank(alice);
        (uint256 supplyExchangePrice, uint256 borrowExchangePrice) = mockProtocolWithInterest.operate(
            address(USDC),
            int256(DEFAULT_BORROW_AMOUNT),
            0,
            address(0),
            address(0),
            abi.encode(alice)
        );

        assertEq(supplyExchangePrice, expectedSupplyExchangePrice, "supply exchange price off");
        assertEq(borrowExchangePrice, expectedBorrowExchangePrice, "borrow exchange price off");
    }
}
