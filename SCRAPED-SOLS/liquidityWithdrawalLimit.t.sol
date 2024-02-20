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

abstract contract LiquidityUserModuleWithdrawLimitTests is LiquidityUserModuleBaseTest {
    uint256 constant BASE_WITHDRAW_LIMIT = 0.5 ether;

    // actual values for default values as read from storage for direct comparison in expected results.
    // once converting to BigMath and then back to get actual number after BigMath precision loss.
    uint256 immutable BASE_WITHDRAW_LIMIT_AFTER_BIGMATH;

    constructor() {
        BASE_WITHDRAW_LIMIT_AFTER_BIGMATH = BigMathMinified.fromBigNumber(
            BigMathMinified.toBigNumber(
                BASE_WITHDRAW_LIMIT,
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

        // Set withdraw config with actual limits
        AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_ = new AdminModuleStructs.UserSupplyConfig[](1);
        userSupplyConfigs_[0] = AdminModuleStructs.UserSupplyConfig({
            user: address(mockProtocol),
            token: address(USDC),
            mode: _getInterestMode(),
            expandPercent: DEFAULT_EXPAND_WITHDRAWAL_LIMIT_PERCENT,
            expandDuration: DEFAULT_EXPAND_WITHDRAWAL_LIMIT_DURATION,
            baseWithdrawalLimit: BASE_WITHDRAW_LIMIT
        });

        vm.prank(admin);
        AdminModule(address(liquidity)).updateUserSupplyConfigs(userSupplyConfigs_);

        // alice supplies liquidity
        _supply(mockProtocol, address(USDC), alice, DEFAULT_SUPPLY_AMOUNT);
    }

    function test_operate_WithdrawExactToLimit() public {
        uint256 balanceBefore = USDC.balanceOf(alice);

        // withdraw exactly to withdraw limit. It is not base withdraw limit but actually the fully expanded
        // limit from supplied amount of 1 ether so 1 ether - 20% = 0.8 ether
        // so we can withdraw exactly 0.2 ether
        uint256 withdrawAmount = 0.2 ether;

        _withdraw(mockProtocol, address(USDC), alice, withdrawAmount);

        uint256 balanceAfter = USDC.balanceOf(alice);

        // alice should have received the withdraw amount
        assertEq(balanceAfter, balanceBefore + withdrawAmount);
    }

    function test_operate_RevertIfWithdrawLimitReached() public {
        (ResolverStructs.UserSupplyData memory userSupplyData_, ) = resolver.getUserSupplyData(
            address(mockProtocol),
            address(USDC)
        );
        assertEq(userSupplyData_.withdrawalLimit, 0.8 ether);
        // withdraw limit is not base withdraw limit but actually the fully expanded
        // limit from supplied amount of 1 ether so 1 ether - 20% = 0.8 ether.
        // so we can withdraw exactly 0.2 ether
        uint256 withdrawAmount = 0.2 ether + 1;

        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLiquidityError.selector, ErrorTypes.UserModule__WithdrawalLimitReached)
        );
        // withdraw more than base withdraw limit -> should revert
        _withdraw(mockProtocol, address(USDC), alice, withdrawAmount);
    }

    function test_operate_RevertIfWithdrawLimitReachedForWithdrawAndBorrow() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLiquidityError.selector, ErrorTypes.UserModule__WithdrawalLimitReached)
        );
        uint256 withdrawAmount = 0.2 ether + 1;

        // execute operate with withdraw AND borrow
        vm.prank(alice);
        mockProtocol.operate(
            address(USDC),
            -int256(withdrawAmount),
            int256(0.1 ether),
            alice,
            alice,
            abi.encode(alice)
        );
    }

    function test_operate_RevertIfWithdrawLimitReachedForWithdrawAndPayback() public {
        _borrow(mockProtocol, address(USDC), alice, DEFAULT_BORROW_AMOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLiquidityError.selector, ErrorTypes.UserModule__WithdrawalLimitReached)
        );
        uint256 withdrawAmount = 0.2 ether + 1;

        // execute operate with supply AND borrow
        vm.prank(alice);
        mockProtocol.operate(
            address(USDC),
            -int256(withdrawAmount),
            -int256(0.1 ether),
            alice,
            address(0),
            abi.encode(alice)
        );
    }
}

contract LiquidityUserModuleWithdrawLimitTestsWithInterest is LiquidityUserModuleWithdrawLimitTests {
    function _getInterestMode() internal pure virtual override returns (uint8) {
        return 1;
    }
}

contract LiquidityUserModuleWithdrawLimitTestsInterestFree is LiquidityUserModuleWithdrawLimitTests {
    function _getInterestMode() internal pure virtual override returns (uint8) {
        return 0;
    }
}
