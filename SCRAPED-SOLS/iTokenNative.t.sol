//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { AdminModule } from "../../../contracts/liquidity/adminModule/main.sol";
import { Structs as AdminModuleStructs } from "../../../contracts/liquidity/adminModule/structs.sol";
import { iToken } from "../../../contracts/protocols/lending/iToken/main.sol";
import { iTokenNativeUnderlying, iTokenNativeUnderlyingOverrides } from "../../../contracts/protocols/lending/iToken/nativeUnderlying/iTokenNativeUnderlying.sol";
import { LendingFactory } from "../../../contracts/protocols/lending/lendingFactory/main.sol";
import { ILendingFactory } from "../../../contracts/protocols/lending/interfaces/iLendingFactory.sol";
import { IITokenNativeUnderlying, IIToken } from "../../../contracts/protocols/lending/interfaces/iIToken.sol";
import { Events as iTokenEvents } from "../../../contracts/protocols/lending/iToken/events.sol";
import { ILiquidity } from "../../../contracts/liquidity/interfaces/iLiquidity.sol";
import { Error } from "../../../contracts/protocols/lending/error.sol";
import { ErrorTypes } from "../../../contracts/protocols/lending/errorTypes.sol";
import { IERC2612 } from "../../../contracts/protocols/lending/interfaces/permit2/IERC2612.sol";

import { TestERC20 } from "../testERC20.sol";
import { iTokenBaseActionsTest, iTokenBaseSetUp } from "./iToken.t.sol";
import { iTokenPermit2DepositsTest } from "./iTokenPermit2Deposits.t.sol";

abstract contract iTokenNativeTestBase is iTokenBaseSetUp {
    function _createToken(
        LendingFactory lendingFactory_,
        IERC20 /** asset_ */
    ) internal virtual override returns (IERC4626) {
        vm.prank(admin);
        factory.setITokenCreationCode("NativeUnderlying", type(iTokenNativeUnderlying).creationCode);
        vm.prank(admin);
        return IERC4626(lendingFactory_.createToken(WETH_ADDRESS, "NativeUnderlying", true));
    }
}

contract iTokenNativePermit2Test is iTokenPermit2DepositsTest {}

contract iTokenNativeActionsTest is iTokenNativeTestBase, iTokenBaseActionsTest {
    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();

        // todo: create local mock WETH and mint instead. or update forge to use vm.deal cheatcode for ERC20s
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(alice, 1000 ether);
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(bob, 1000 ether);

        underlying = TestERC20(WETH_ADDRESS);

        // enable iToken to supply tokens of native token
        _setUserAllowancesDefault(address(liquidity), admin, NATIVE_TOKEN_ADDRESS, address(lendingIToken));

        // approve underlying to iToken
        _setApproval(IERC20(WETH_ADDRESS), address(lendingIToken), admin);
        _setApproval(IERC20(WETH_ADDRESS), address(lendingIToken), alice);
        _setApproval(IERC20(WETH_ADDRESS), address(lendingIToken), bob);
    }

    function testMetadata() public {
        assertEq(lendingIToken.name(), "Fluid Interest Wrapped Ether");
        assertEq(lendingIToken.symbol(), "fiWETH");
        assertEq(address(lendingIToken.asset()), address(underlying));
    }

    function testMaxDeposit() public virtual {
        // todo test must be adjusted, max deposit only works for WETH, but not for ETH (reverts on purpose)
    }

    function testSupplyYield() public virtual {
        // todo test must be adjusted with _borrow and _withdraw helper methods etc. for _withdrawNative for MockProtocol
    }

    function test_deposit_WithMaxAssetAmount() public override {
        uint256 underlyingBalanceBefore = underlying.balanceOf(alice);
        console2.log("underlyingBalanceBefore =========");
        console2.log(underlyingBalanceBefore);
        vm.prank(alice);
        uint256 balance = lendingIToken.deposit(UINT256_MAX, alice);

        assertEqDecimal(balance, underlyingBalanceBefore, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), underlyingBalanceBefore, DEFAULT_DECIMALS);
        assertEq(underlyingBalanceBefore - underlying.balanceOf(alice), underlyingBalanceBefore);
    }

    function test_rebalance_RevertIfMsgValueSent() public override {}

    function test_rebalance() public override {
        // make alice the rebalancer
        vm.prank(admin);
        lendingIToken.updateRebalancer(alice);
        // supply as alice to have some initial deposit
        vm.startPrank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);
        // get balance of alice before rebalance
        uint256 balanceBefore = alice.balance;
        // create a difference between Liquidity supply and totalAssets() by warping time so rewards accrue
        //  rewards rate is 20% per year.
        vm.warp(block.timestamp + 365 days);
        // expect total assets to be 1.2x DEFAULT_AMOUNT now.
        assertEq(lendingIToken.totalAssets(), (DEFAULT_AMOUNT * 12) / 10);
        // expect liquidityBalance still to be only DEFAULT_AMOUNT
        (, , , , , , uint256 liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, DEFAULT_AMOUNT);

        // execute rebalance
        lendingIToken.rebalance{ value: DEFAULT_AMOUNT }();

        // balance should be before - 20% of DEFAULT_AMOUNT as 20% of DEFAULT_AMOUNT got used to fund rewards
        uint256 balanceAfter = alice.balance;
        assertEq(balanceAfter, balanceBefore - DEFAULT_AMOUNT / 5);
        // expect total assets should still be 1.2x DEFAULT_AMOUNT now.
        assertEq(lendingIToken.totalAssets(), (DEFAULT_AMOUNT * 12) / 10);
        // expect liquidityBalance should now also be 2x DEFAULT_AMOUNT
        (, , , , , , liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, (DEFAULT_AMOUNT * 12) / 10);

        vm.stopPrank();
    }

    function test_rebalance_NativeOverfundMsgValue() public {
        // make alice the rebalancer
        vm.prank(admin);
        lendingIToken.updateRebalancer(alice);
        // supply as alice to have some initial deposit
        vm.startPrank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);
        // get balance of alice before rebalance
        uint256 balanceBefore = alice.balance;
        // create a difference between Liquidity supply and totalAssets() by warping time so rewards accrue
        //  rewards rate is 20% per year.
        vm.warp(block.timestamp + 365 days);
        // expect total assets to be 1.2x DEFAULT_AMOUNT now.
        assertEq(lendingIToken.totalAssets(), (DEFAULT_AMOUNT * 12) / 10);
        // expect liquidityBalance still to be only DEFAULT_AMOUNT
        (, , , , , , uint256 liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, DEFAULT_AMOUNT);

        // execute rebalance
        lendingIToken.rebalance{ value: DEFAULT_AMOUNT * 2 }(); // expect rest should be send back

        // balance should be before - 20% of DEFAULT_AMOUNT as 20% of DEFAULT_AMOUNT got used to fund rewards
        uint256 balanceAfter = alice.balance;
        assertEq(balanceAfter, balanceBefore - (DEFAULT_AMOUNT * 2) / 10);
        // expect total assets should still be 1.2x DEFAULT_AMOUNT now.
        assertEq(lendingIToken.totalAssets(), (DEFAULT_AMOUNT * 12) / 10);
        // expect liquidityBalance should now also be 2x DEFAULT_AMOUNT
        (, , , , , , liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, (DEFAULT_AMOUNT * 12) / 10);

        vm.stopPrank();
    }

    function test_rebalance_NativeUnderfundMsgValue() public {
        // make alice the rebalancer
        vm.prank(admin);
        lendingIToken.updateRebalancer(alice);
        // supply as alice to have some initial deposit
        vm.startPrank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);
        // get balance of alice before rebalance
        uint256 balanceBefore = alice.balance;
        // create a difference between Liquidity supply and totalAssets() by warping time so rewards accrue
        //  rewards rate is 20% per year.
        vm.warp(block.timestamp + 365 days);
        // expect total assets to be 1.2x DEFAULT_AMOUNT now.
        assertEq(lendingIToken.totalAssets(), (DEFAULT_AMOUNT * 12) / 10);
        // expect liquidityBalance still to be only DEFAULT_AMOUNT
        (, , , , , , uint256 liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, DEFAULT_AMOUNT);

        // execute rebalance
        lendingIToken.rebalance{ value: DEFAULT_AMOUNT / 20 }(); // expect at least msg.value should be used

        // balance should be before - DEFAULT_AMOUNT / 20 as DEFAULT_AMOUNT / 20 got used to fund rewards
        uint256 balanceAfter = alice.balance;
        assertEq(balanceAfter, balanceBefore - DEFAULT_AMOUNT / 20);
        // expect total assets should still be 1.2x DEFAULT_AMOUNT now.
        assertEq(lendingIToken.totalAssets(), (DEFAULT_AMOUNT * 12) / 10);
        // expect liquidityBalance should now be DEFAULT_AMOUNT + DEFAULT_AMOUNT / 20
        (, , , , , , liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, DEFAULT_AMOUNT + DEFAULT_AMOUNT / 20);

        vm.stopPrank();
    }

    function test_rebalance_EmitLogRebalance() public override {
        // make alice the rebalancer
        vm.prank(admin);
        lendingIToken.updateRebalancer(alice);
        // supply as alice to have some initial deposit
        vm.startPrank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);
        // create a difference between Liquidity supply and totalAssets() by warping time so rewards accrue
        // rewards rate is 20% per year.
        vm.warp(block.timestamp + 365 days);

        //check event
        vm.expectEmit(true, true, true, true);
        emit LogRebalance(DEFAULT_AMOUNT / 5);

        // execute rebalance
        lendingIToken.rebalance{ value: DEFAULT_AMOUNT / 5 }();
        vm.stopPrank();
    }

    function test_maxDeposit_NoDeposits() public override {
        (, , , , , , uint256 liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, 0);

        uint256 maxDeposit = lendingIToken.maxDeposit(address(0));
        assertEq(maxDeposit, uint256(uint128(type(int128).max)));
    }

    function test_maxMint_NoDeposits() public override {
        (, , , , , , uint256 liquidityBalance, , ) = lendingIToken.getData();
        assertEq(liquidityBalance, 0);

        uint256 maxMint = lendingIToken.maxMint(address(0));
        assertEq(maxMint, uint256(uint128(type(int128).max)));
    }

    function test_maxDeposit_WithDeposits() public override {
        vm.prank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);

        uint256 maxDeposit = lendingIToken.maxDeposit(address(0));
        assertEq(maxDeposit, uint256(uint128(type(int128).max)) - DEFAULT_AMOUNT);
    }

    function test_maxMint_WithDeposits() public override {
        vm.prank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);

        uint256 maxMint = lendingIToken.maxMint(address(0));
        assertEq(maxMint, uint256(uint128(type(int128).max)) - DEFAULT_AMOUNT);
    }

    function test_maxWithdraw_WithWithdrawalLimit() public override {
        // set withdrawal limit of 10% expanded at liquidity. This should then be the reported max amount.
        AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_ = new AdminModuleStructs.UserSupplyConfig[](1);
        userSupplyConfigs_[0] = AdminModuleStructs.UserSupplyConfig({
            user: address(lendingIToken),
            token: NATIVE_TOKEN_ADDRESS,
            mode: 1,
            expandPercent: 10 * DEFAULT_PERCENT_PRECISION, // 10%
            expandDuration: 1,
            baseWithdrawalLimit: 1e5 // low base withdrawal limit so not full amount is withdrawable
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateUserSupplyConfigs(userSupplyConfigs_);

        vm.prank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);
        vm.warp(block.timestamp + 10); // get to full expansion

        assertEq(lendingIToken.maxWithdraw(alice), DEFAULT_AMOUNT / 10);
    }

    function test_maxRedeem_WithWithdrawalLimit() public override {
        // set no rewards for this test
        rewards.setRate(0);

        // set withdrawal limit of 10% expanded at liquidity. This should then be the reported max amount.
        AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_ = new AdminModuleStructs.UserSupplyConfig[](1);
        userSupplyConfigs_[0] = AdminModuleStructs.UserSupplyConfig({
            user: address(lendingIToken),
            token: NATIVE_TOKEN_ADDRESS,
            mode: 1,
            expandPercent: 10 * DEFAULT_PERCENT_PRECISION, // 10%
            expandDuration: 1,
            baseWithdrawalLimit: 1e5 // low base withdrawal limit so not full amount is withdrawable
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateUserSupplyConfigs(userSupplyConfigs_);

        vm.prank(alice);
        lendingIToken.deposit(DEFAULT_AMOUNT, alice);
        vm.warp(block.timestamp + 10); // get to full expansion

        assertEq(lendingIToken.maxRedeem(alice), DEFAULT_AMOUNT / 10);
    }
}

contract iTokenNativeUnderlyingTest is iTokenNativeTestBase, iTokenEvents {
    IITokenNativeUnderlying lendingITokenNative;

    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();

        // todo: create local mock WETH and mint instead. or update forge to use vm.deal cheatcode for ERC20s
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(alice, 1000 ether);
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(bob, 1000 ether);

        lendingITokenNative = IITokenNativeUnderlying(address(lendingIToken));

        // enable iToken to supply tokens of native token
        _setUserAllowancesDefault(address(liquidity), admin, NATIVE_TOKEN_ADDRESS, address(lendingIToken));

        vm.deal(alice, 100 ether);
    }

    function test_getLiquiditySlotLinksAsset() public {
        iTokenNativeUnderlyingExposed contractWithExposedFn = new iTokenNativeUnderlyingExposed(
            ILiquidity(address(liquidity)),
            ILendingFactory(address(factory)),
            IERC20(address(underlying))
        );
        address asset = contractWithExposedFn.exposed_getLiquiditySlotLinksAsset();
        assertEq(asset, NATIVE_TOKEN_ADDRESS);
    }
}

contract iTokenNativeETHActionsTest is iTokenNativeTestBase, iTokenEvents {
    IITokenNativeUnderlying lendingITokenNative;

    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();

        // todo: create local mock WETH and mint instead. or update forge to use vm.deal cheatcode for ERC20s
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(alice, 1000 ether);
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(bob, 1000 ether);

        lendingITokenNative = IITokenNativeUnderlying(address(lendingIToken));

        // enable iToken to supply tokens of native token
        _setUserAllowancesDefault(address(liquidity), admin, NATIVE_TOKEN_ADDRESS, address(lendingIToken));

        vm.deal(alice, 1000 * DEFAULT_AMOUNT);
    }

    function test_depositNative_RevertWhenMinAmountOutIsLessThanShares() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__MinAmountOut));
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice, DEFAULT_AMOUNT + 1);
    }

    function test_depositNative_WithMinAmountOut() public {
        vm.prank(alice);
        // expect it not to fail
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice, DEFAULT_AMOUNT);
    }

    function test_depositNative() public {
        uint256 balanceBefore = alice.balance;

        vm.prank(alice);
        uint256 shares = lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);

        assertEqDecimal(shares, DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEq(balanceBefore - alice.balance, DEFAULT_AMOUNT);
    }

    function test_mintNative_RevertIfAssetAmountEqualsNativeMax() public {
        vm.expectRevert();
        vm.prank(alice);
        lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT }(type(uint256).max, alice);
    }

    function test_mintNative_RevertWhenUserSendsLessEthersThanAssetAmountArgument() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.FluidLendingError.selector,
                ErrorTypes.iTokenNativeUnderlying__TransferInsufficient
            )
        );
        vm.prank(alice);
        lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT - 1 }(DEFAULT_AMOUNT, alice);
    }

    function test_mintNative() public {
        uint256 balanceBefore = alice.balance;

        vm.prank(alice);
        uint256 assets = lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT }(DEFAULT_AMOUNT, alice);

        assertEqDecimal(assets, DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEq(balanceBefore - alice.balance, DEFAULT_AMOUNT);
    }

    function test_mintNative_WithMaxAssets_RevertWhenMaxAssetsIsSurpassed() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__MaxAmount));
        lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT }(DEFAULT_AMOUNT, alice, DEFAULT_AMOUNT - 1);
    }

    function test_mintNative_WithMaxAssets() public {
        vm.prank(alice);
        lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT }(DEFAULT_AMOUNT, alice, DEFAULT_AMOUNT);
    }

    function test_withdrawNative_WithMaxSharesBurn() public {
        vm.startPrank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);
        lendingITokenNative.withdrawNative(UINT256_MAX, alice, alice, DEFAULT_AMOUNT);
        vm.stopPrank();
    }

    function test_withdrawNative_RevertWhenMaxSharesBurnIsSurpassed() public {
        vm.startPrank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);
        vm.expectRevert(abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__MaxAmount));
        lendingITokenNative.withdrawNative(UINT256_MAX, alice, alice, DEFAULT_AMOUNT - 1);
        vm.stopPrank();
    }

    function test_withdrawNative_SenderIsNotOwnerCase() public {
        vm.deal(bob, 100 ether);
        uint256 aliceBalanceBeforeDeposit = alice.balance;
        uint256 bobBalanceBeforeDeposit = bob.balance;
        vm.prank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);
        vm.prank(bob);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(bob);
        uint256 aliceBalanceAfterDeposit = alice.balance;
        uint256 bobBalanceAfterDeposit = bob.balance;
        vm.prank(bob);
        lendingITokenNative.approve(alice, DEFAULT_AMOUNT);
        vm.prank(alice);
        lendingITokenNative.withdrawNative(UINT256_MAX, alice, bob, DEFAULT_AMOUNT);
        assertEq(aliceBalanceAfterDeposit, aliceBalanceBeforeDeposit - DEFAULT_AMOUNT);
        assertEq(bobBalanceAfterDeposit, bobBalanceBeforeDeposit - DEFAULT_AMOUNT);
        assertEq(lendingITokenNative.balanceOf(alice), DEFAULT_AMOUNT);
    }

    function test_withdrawNative() public {
        vm.startPrank(alice);

        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);

        uint256 balanceBefore = alice.balance;
        uint256 shares = lendingITokenNative.withdrawNative(DEFAULT_AMOUNT, alice, alice);

        assertEq(shares, DEFAULT_AMOUNT);
        assertEq(lendingIToken.balanceOf(alice), 0);
        assertEq(alice.balance - balanceBefore, DEFAULT_AMOUNT);

        vm.stopPrank();
    }

    function test_redeemNative() public {
        vm.startPrank(alice);

        lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT }(DEFAULT_AMOUNT, alice);

        uint256 balanceBefore = alice.balance;
        uint256 assets = lendingITokenNative.redeemNative(lendingIToken.balanceOf(alice), alice, alice);
        vm.stopPrank();

        assertEq(lendingIToken.balanceOf(alice), 0);
        assertEq(DEFAULT_AMOUNT, assets);
        assertEq(alice.balance - balanceBefore, DEFAULT_AMOUNT);
    }

    function test_redeemNative_SenderIsNotOwnerCase() public {
        vm.deal(bob, 100 ether);

        uint256 aliceBalanceBeforeDeposit = alice.balance;
        uint256 bobBalanceBeforeDeposit = bob.balance;

        vm.prank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);
        vm.prank(bob);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(bob);

        uint256 aliceBalanceAfterDeposit = alice.balance;
        uint256 bobBalanceAfterDeposit = bob.balance;

        assertEq(aliceBalanceAfterDeposit, aliceBalanceBeforeDeposit - DEFAULT_AMOUNT);
        assertEq(bobBalanceAfterDeposit, bobBalanceBeforeDeposit - DEFAULT_AMOUNT);

        vm.prank(bob);
        lendingITokenNative.approve(alice, DEFAULT_AMOUNT);
        vm.prank(alice);
        lendingITokenNative.redeemNative(UINT256_MAX, alice, bob, DEFAULT_AMOUNT);

        assertEq(lendingITokenNative.balanceOf(alice), DEFAULT_AMOUNT);
    }

    function test_redeemNative_RevertIfMinAmountOut() public {
        vm.startPrank(alice);
        lendingITokenNative.mintNative{ value: DEFAULT_AMOUNT }(DEFAULT_AMOUNT, alice);
        vm.expectRevert(abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__MinAmountOut));
        lendingITokenNative.redeemNative(UINT256_MAX, alice, alice, DEFAULT_AMOUNT * 10);
        vm.stopPrank();
    }

    function testConvertToShares() public {
        assertEq(lendingIToken.convertToShares(DEFAULT_AMOUNT), DEFAULT_AMOUNT);
    }
}

contract iTokenNativeETHEIP2612WithdrawalsTest is iTokenNativeTestBase, iTokenEvents {
    IITokenNativeUnderlying lendingITokenNative;

    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();

        // todo: create local mock WETH and mint instead. or update forge to use vm.deal cheatcode for ERC20s
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(alice, 1000 ether);
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(bob, 1000 ether);

        lendingITokenNative = IITokenNativeUnderlying(address(lendingIToken));

        // enable iToken to supply tokens of native token
        _setUserAllowancesDefault(address(liquidity), admin, NATIVE_TOKEN_ADDRESS, address(lendingIToken));

        vm.deal(alice, 100000000000000 * DEFAULT_AMOUNT);
    }

    function test_withdrawWithSignatureNative_RevertIfOwner() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__PermitFromOwnerCall)
        );
        lendingITokenNative.withdrawWithSignatureNative(1, 1, alice, admin, 1, block.timestamp, new bytes(0));
    }

    function test_withdrawWithSignatureNative_RevertWhenMaxSharesBurnIsSurpassed() public {
        vm.prank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);

        uint256 deadline = block.timestamp + 10 minutes;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePrivateKey,
            _getPermitHash(
                IERC2612(address(lendingITokenNative)),
                alice,
                bob,
                DEFAULT_AMOUNT,
                0, // Nonce is always 0 because user is a fresh address.
                deadline
            )
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__MaxAmount));
        lendingITokenNative.withdrawWithSignatureNative(
            DEFAULT_AMOUNT,
            DEFAULT_AMOUNT,
            alice,
            alice,
            DEFAULT_AMOUNT - 1,
            deadline,
            signature
        );
    }

    function test_withdrawWithSignatureNative() public {
        vm.prank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);

        uint256 deadline = block.timestamp + 10 minutes;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePrivateKey,
            _getPermitHash(
                IERC2612(address(lendingITokenNative)),
                alice,
                admin,
                DEFAULT_AMOUNT,
                0, // Nonce is always 0 because user is a fresh address.
                deadline
            )
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 aliceBalanceBefore = IERC20(address(lendingITokenNative)).balanceOf(alice);
        uint256 aliceNativeBalance = alice.balance;
        vm.prank(admin);
        lendingITokenNative.withdrawWithSignatureNative(
            DEFAULT_AMOUNT,
            DEFAULT_AMOUNT,
            alice,
            alice,
            DEFAULT_AMOUNT,
            deadline,
            signature
        );
        uint256 aliceBalanceETHAfter = alice.balance;
        assertEq(aliceNativeBalance + aliceBalanceBefore, aliceBalanceETHAfter);
    }

    function test_redeemWithSignatureNative_RevertIfOwner() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__PermitFromOwnerCall)
        );
        lendingITokenNative.redeemWithSignatureNative(1, alice, admin, 1, block.timestamp, new bytes(0));
    }

    function test_redeemWithSignatureNative_RevertWhenSharesAmountDontMeetMinAmountOut() public {
        vm.prank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.iToken__MinAmountOut));
        lendingITokenNative.redeemWithSignatureNative(
            DEFAULT_AMOUNT,
            alice,
            alice,
            DEFAULT_AMOUNT + 1,
            block.timestamp,
            new bytes(0)
        );
    }

    function test_redeemWithSignatureNative() public {
        vm.prank(alice);
        lendingITokenNative.depositNative{ value: DEFAULT_AMOUNT }(alice);

        uint256 deadline = block.timestamp + 10 minutes;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePrivateKey,
            _getPermitHash(
                IERC2612(address(lendingITokenNative)),
                alice,
                admin,
                DEFAULT_AMOUNT,
                0, // Nonce is always 0 because user is a fresh address.
                deadline
            )
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        uint256 aliceBalanceBefore = IERC20(address(lendingITokenNative)).balanceOf(alice);
        uint256 aliceNativeBalance = alice.balance;
        vm.prank(admin);
        lendingITokenNative.redeemWithSignatureNative(
            DEFAULT_AMOUNT,
            alice,
            alice,
            DEFAULT_AMOUNT,
            deadline,
            signature
        );
        uint256 aliceBalanceETHAfter = alice.balance;
        assertEq(aliceNativeBalance + aliceBalanceBefore, aliceBalanceETHAfter);
    }

    function _getPermitHash(
        IERC2612 token,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) private view returns (bytes32 h) {
        bytes32 domainHash = token.DOMAIN_SEPARATOR();
        bytes32 typeHash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        bytes32 structHash = keccak256(abi.encode(typeHash, owner, spender, value, nonce, deadline));
        return keccak256(abi.encodePacked("\x19\x01", domainHash, structHash));
    }
}

contract iTokenNativeETHTest is iTokenNativeTestBase, iTokenEvents {
    IITokenNativeUnderlying lendingITokenNative;

    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();

        // todo: create local mock WETH and mint instead. or update forge to use vm.deal cheatcode for ERC20s
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(alice, 1000 ether);
        vm.prank(0x57757E3D981446D585Af0D9Ae4d7DF6D64647806);
        IERC20(WETH_ADDRESS).transfer(bob, 1000 ether);

        lendingITokenNative = IITokenNativeUnderlying(address(lendingIToken));

        // enable iToken to supply tokens of native token
        _setUserAllowancesDefault(address(liquidity), admin, NATIVE_TOKEN_ADDRESS, address(lendingIToken));

        vm.deal(alice, 1000 * DEFAULT_AMOUNT);
    }

    function test_liquidityCallback_RevertAlways() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.FluidLendingError.selector,
                ErrorTypes.iTokenNativeUnderlying__UnexpectedLiquidityCallback
            )
        );
        lendingITokenNative.liquidityCallback(address(lendingIToken), 1, new bytes(0));
    }
}

contract iTokenNativeUnderlyingExposed is iTokenNativeUnderlyingOverrides {
    constructor(
        ILiquidity liquidity_,
        ILendingFactory lendingFactory_,
        IERC20 asset_
    ) iToken(liquidity_, lendingFactory_, asset_) {}

    function exposed_getLiquiditySlotLinksAsset() external view returns (address) {
        return _getLiquiditySlotLinksAsset();
    }

    function depositNative(address) external payable returns (uint256) {
        revert("Not implemented");
    }

    function depositNative(address, uint256) external payable returns (uint256) {
        revert("Not implemented");
    }

    function liquidityCallback(address, uint256, bytes calldata) external pure override(iToken, IIToken) {
        revert("Not implemented");
    }

    function mintNative(uint256, address) external payable returns (uint256) {
        revert("Not implemented");
    }

    function mintNative(uint256, address, uint256) external payable returns (uint256) {
        revert("Not implemented");
    }

    function redeemNative(uint256, address, address) external pure returns (uint256) {
        revert("Not implemented");
    }

    function redeemNative(uint256, address, address, uint256) external pure returns (uint256) {
        revert("Not implemented");
    }

    function redeemWithSignatureNative(
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (uint256) {
        revert("Not implemented");
    }

    function withdrawNative(uint256, address, address) external pure returns (uint256) {
        revert("Not implemented");
    }

    function withdrawNative(uint256, address, address, uint256) external pure returns (uint256) {
        revert("Not implemented");
    }

    function withdrawWithSignatureNative(
        uint256,
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (uint256) {
        revert("Not implemented");
    }
}
