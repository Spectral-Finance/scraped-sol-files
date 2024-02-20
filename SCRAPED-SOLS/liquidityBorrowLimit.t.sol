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

abstract contract LiquidityUserModuleBorrowLimitTests is LiquidityUserModuleBaseTest {
    uint256 constant BASE_BORROW_LIMIT = 1 ether;
    uint256 constant MAX_BORROW_LIMIT = 10 ether;

    // actual values for default values as read from storage for direct comparison in expected results.
    // once converting to BigMath and then back to get actual number after BigMath precision loss.
    uint256 immutable BASE_BORROW_LIMIT_AFTER_BIGMATH;
    uint256 immutable MAX_BORROW_LIMIT_AFTER_BIGMATH;

    constructor() {
        BASE_BORROW_LIMIT_AFTER_BIGMATH = BigMathMinified.fromBigNumber(
            BigMathMinified.toBigNumber(
                BASE_BORROW_LIMIT,
                SMALL_COEFFICIENT_SIZE,
                DEFAULT_EXPONENT_SIZE,
                BigMathMinified.ROUND_DOWN
            ),
            DEFAULT_EXPONENT_SIZE,
            DEFAULT_EXPONENT_MASK
        );

        MAX_BORROW_LIMIT_AFTER_BIGMATH = BigMathMinified.fromBigNumber(
            BigMathMinified.toBigNumber(
                MAX_BORROW_LIMIT,
                SMALL_COEFFICIENT_SIZE,
                DEFAULT_EXPONENT_SIZE,
                BigMathMinified.ROUND_DOWN
            ),
            DEFAULT_EXPONENT_SIZE,
            DEFAULT_EXPONENT_MASK
        );
    }

    function _getInterestMode() internal pure virtual returns (uint8);

    function setUp() public virtual override {
        super.setUp();

        // Set borrow config with actual limits
        AdminModuleStructs.UserBorrowConfig[] memory userBorrowConfigs_ = new AdminModuleStructs.UserBorrowConfig[](1);
        userBorrowConfigs_[0] = AdminModuleStructs.UserBorrowConfig({
            user: address(mockProtocol),
            token: address(USDC),
            mode: _getInterestMode(),
            expandPercent: DEFAULT_EXPAND_DEBT_CEILING_PERCENT,
            expandDuration: DEFAULT_EXPAND_DEBT_CEILING_DURATION,
            baseDebtCeiling: BASE_BORROW_LIMIT,
            maxDebtCeiling: MAX_BORROW_LIMIT
        });

        vm.prank(admin);
        AdminModule(address(liquidity)).updateUserBorrowConfigs(userBorrowConfigs_);

        // alice supplies liquidity
        _supply(mockProtocol, address(USDC), alice, DEFAULT_SUPPLY_AMOUNT);
    }

    function test_operate_BorrowExactToLimit() public {
        uint256 balanceBefore = USDC.balanceOf(alice);

        // borrow exactly to base borrow limit
        _borrow(mockProtocol, address(USDC), alice, BASE_BORROW_LIMIT_AFTER_BIGMATH);

        uint256 balanceAfter = USDC.balanceOf(alice);

        // alice should have received the borrow amount
        assertEq(balanceAfter, balanceBefore + BASE_BORROW_LIMIT_AFTER_BIGMATH);
    }

    function test_operate_RevertIfBorrowLimitReached() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLiquidityError.selector, ErrorTypes.UserModule__BorrowLimitReached)
        );
        // borrow more than base borrow limit -> should revert
        _borrow(mockProtocol, address(USDC), alice, BASE_BORROW_LIMIT_AFTER_BIGMATH + 1);
    }

    function test_operate_RevertIfBorrowLimitReachedForSupplyAndBorrow() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLiquidityError.selector, ErrorTypes.UserModule__BorrowLimitReached)
        );

        // execute operate with supply AND borrow
        vm.prank(alice);
        mockProtocol.operate(
            address(USDC),
            int256(DEFAULT_SUPPLY_AMOUNT),
            int256(BASE_BORROW_LIMIT_AFTER_BIGMATH + 1),
            address(0),
            alice,
            abi.encode(alice)
        );
    }

    function test_operate_RevertIfBorrowLimitReachedForWithdrawAndBorrow() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLiquidityError.selector, ErrorTypes.UserModule__BorrowLimitReached)
        );

        // execute operate with withdraw AND borrow
        vm.prank(alice);
        mockProtocol.operate(
            address(USDC),
            -int256(0.1 ether),
            int256(BASE_BORROW_LIMIT_AFTER_BIGMATH + 1),
            alice,
            alice,
            abi.encode(alice)
        );
    }
}

contract LiquidityUserModuleBorrowLimitTestsWithInterest is LiquidityUserModuleBorrowLimitTests {
    function _getInterestMode() internal pure virtual override returns (uint8) {
        return 1;
    }
}

contract LiquidityUserModuleBorrowLimitTestsInterestFree is LiquidityUserModuleBorrowLimitTests {
    function _getInterestMode() internal pure virtual override returns (uint8) {
        return 0;
    }
}
