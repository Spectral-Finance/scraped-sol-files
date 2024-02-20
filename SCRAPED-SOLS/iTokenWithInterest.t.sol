//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import "../testERC20.sol";
import { TestHelpers } from "../liquidity/liquidityTestHelpers.sol";
import { iToken } from "../../../contracts/protocols/lending/iToken/main.sol";
import { LendingRewardsRateModel } from "../../../contracts/protocols/lending/lendingRewardsRateModel/main.sol";
import { LendingFactory } from "../../../contracts/protocols/lending/lendingFactory/main.sol";
import { ILendingFactory } from "../../../contracts/protocols/lending/interfaces/iLendingFactory.sol";

import { ILiquidity } from "../../../contracts/liquidity/interfaces/iLiquidity.sol";

import { iToken } from "../../../contracts/protocols/lending/iToken/main.sol";
import { iTokenBaseActionsTest, iTokenBasePermitTest, iTokenBaseSetUp, iTokenGasTestFirstDeposit, iTokenGasTestSecondDeposit } from "./iToken.t.sol";
// import { iTokenBaseInvariantTestRewards, iTokenBaseInvariantTestRewardsNoBorrowers, iTokenBaseInvariantTestCore, iTokenBaseInvariantTestWithRepay } from "./iTokenInvariant.t.sol";
import { IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { Structs as AdminModuleStructs } from "../../../contracts/liquidity/adminModule/structs.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

abstract contract iTokenWithInterestTestBase is iTokenBaseSetUp {
    function _createToken(LendingFactory lendingFactory_, IERC20 asset_) internal virtual override returns (IERC4626) {
        vm.prank(admin);
        factory.setITokenCreationCode("iToken", type(iToken).creationCode);
        vm.prank(admin);
        return IERC4626(lendingFactory_.createToken(address(asset_), "iToken", false));
    }
}

contract iTokenWithInterestGasTestFirstDeposit is iTokenWithInterestTestBase, iTokenGasTestFirstDeposit {}

contract iTokenWithInterestGasTestSecondDeposit is iTokenWithInterestTestBase, iTokenGasTestSecondDeposit {
    function setUp() public virtual override(iTokenGasTestSecondDeposit, iTokenBaseSetUp) {
        super.setUp();
    }
}

contract iTokenWithInterestActionsTest is iTokenWithInterestTestBase, iTokenBaseActionsTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testMetadata(string calldata name, string calldata symbol) public {
        TestERC20 underlying = new TestERC20(name, symbol);

        // config for token must exist fur the underlying asset at liquidity before creating the iToken
        // 1. Setup rate data for USDC and DAI, must happen before token configs
        _setDefaultRateDataV1(address(liquidity), admin, address(underlying));

        // 2. Add a token configuration for USDC and DAI
        AdminModuleStructs.TokenConfig[] memory tokenConfigs_ = new AdminModuleStructs.TokenConfig[](1);
        tokenConfigs_[0] = AdminModuleStructs.TokenConfig({ token: address(underlying), fee: 0, threshold: 0 });
        vm.prank(admin);
        ILiquidity(address(liquidity)).updateTokenConfigs(tokenConfigs_);

        lendingIToken = iToken(address(_createToken(factory, IERC20(address(underlying)))));
        assertEq(lendingIToken.name(), string(abi.encodePacked("Fluid Interest ", name)));
        assertEq(lendingIToken.symbol(), string(abi.encodePacked("fi", symbol)));
        assertEq(address(lendingIToken.asset()), address(underlying));
    }

    function test_deposit_WithMaxAssetAmount() public override {
        // send out some balance of alice to get to more realistic test amunts
        // (alternatively asserts below would have to be adjusted for some minor inaccuracy)
        uint256 underlyingBalanceBeforeTransfer = underlying.balanceOf(alice);
        vm.prank(alice);
        underlying.transfer(admin, underlyingBalanceBeforeTransfer - DEFAULT_AMOUNT * 10);
        uint256 underlyingBalanceBefore = underlying.balanceOf(alice);
        vm.prank(alice);
        uint256 balance = lendingIToken.deposit(UINT256_MAX, alice);

        assertEqDecimal(balance, underlyingBalanceBefore, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), underlyingBalanceBefore, DEFAULT_DECIMALS);
        assertEq(underlyingBalanceBefore - underlying.balanceOf(alice), underlyingBalanceBefore);
    }

    function test_mint_WithMaxAssetAmount() public override {
        // send out some balance of alice to get to more realistic test amunts
        // (alternatively asserts below would have to be adjusted for some minor inaccuracy)
        uint256 underlyingBalanceBeforeTransfer = underlying.balanceOf(alice);
        vm.prank(alice);
        underlying.transfer(admin, underlyingBalanceBeforeTransfer - DEFAULT_AMOUNT * 10);
        uint256 underlyingBalanceBefore = underlying.balanceOf(alice);
        vm.prank(alice);
        uint256 balance = lendingIToken.mint(UINT256_MAX, alice);

        assertEqDecimal(balance, underlyingBalanceBefore, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), underlyingBalanceBefore, DEFAULT_DECIMALS);
        assertEq(underlyingBalanceBefore - underlying.balanceOf(alice), underlyingBalanceBefore);
    }
}

// contract iTokenWithInterestPermitTest is iTokenWithInterestTestBase, iTokenBasePermitTest {
//     function setUp() public virtual override(iTokenBaseSetUp, iTokenBasePermitTest) {
//         super.setUp();
//     }
// }

// contract iTokenWithInterestInvariantTestCore is iTokenWithInterestTestBase, iTokenBaseInvariantTestCore {
//     function setUp() public virtual override(iTokenBaseSetUp, iTokenBaseInvariantTestCore) {
//         super.setUp();
//     }
// }

// contract iTokenWithInterestInvariantTestRewards is iTokenWithInterestTestBase, iTokenBaseInvariantTestRewards {
//     function setUp() public virtual override(iTokenBaseSetUp, iTokenBaseInvariantTestRewards) {
//         super.setUp();
//     }
// }

// contract iTokenWithInterestInvariantTestRewardsNoBorrowers is
//     iTokenWithInterestTestBase,
//     iTokenBaseInvariantTestRewardsNoBorrowers
// {
//     function setUp() public virtual override(iTokenBaseSetUp, iTokenBaseInvariantTestRewardsNoBorrowers) {
//         super.setUp();
//     }
// }

// contract iTokenWithInterestInvariantTestRepay is iTokenWithInterestTestBase, iTokenBaseInvariantTestWithRepay {
//     function setUp() public virtual override(iTokenBaseSetUp, iTokenBaseInvariantTestWithRepay) {
//         super.setUp();
//     }
// }
