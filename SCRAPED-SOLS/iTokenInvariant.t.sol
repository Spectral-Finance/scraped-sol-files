//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// import "forge-std/Test.sol";

// import "forge-std/console2.sol";

// import { iToken } from "../../../contracts/protocols/lending/iToken/main.sol";
// import { ErrorTypes } from "../../../contracts/protocols/lending/errorTypes.sol";
// import { ILiquidity } from "../../../contracts/liquidity/interfaces/iLiquidity.sol";
// import { ILendingFactory } from "../../../contracts/protocols/lending/interfaces/iLendingFactory.sol";
// import { Structs as AdminModuleStructs } from "../../../contracts/liquidity/adminModule/structs.sol";

// import { iTokenBaseSetUp } from "./iToken.t.sol";
// import { TestERC20 } from "../testERC20.sol";

// contract iTokenInvariantHandler is Test {
//     iToken internal erc4626;
//     ILiquidity internal liquidityProxy;

//     TestERC20 internal underlying;

//     address[] public actors;

//     uint256 public ghost_sumBalanceOf;

//     address internal currentActor;

//     uint256 internal maxWithdrawDenominator;

//     // track last liquidity exchange prices at last action execution to make sure yield only goes up
//     uint256 internal lastLiquiditySafeExchangePrice;
//     uint256 internal lastLiquidityRiskyExchangePrice;
//     uint256 internal lastLiquidityBorrowExchangePrice;

//     modifier useActor(uint256 actorIndexSeed) {
//         currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
//         vm.startPrank(currentActor);
//         _;
//         vm.stopPrank();
//     }

//     constructor(
//         iToken erc4626_,
//         address[] memory actors_,
//         TestERC20 underlying_,
//         ILiquidity liquidityProxy_,
//         uint256 maxWithdrawDenominator_
//     ) {
//         erc4626 = erc4626_;
//         actors = actors_;
//         underlying = underlying_;
//         liquidityProxy = liquidityProxy_;
//         maxWithdrawDenominator = maxWithdrawDenominator_;
//     }

//     function deposit(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
//         amount = bound(amount, erc4626.minDeposit(), 1e28);

//         uint256 balanceBefore = erc4626.balanceOf(currentActor);
//         uint256 underlyingBalanceBefore = underlying.balanceOf(currentActor);

//         uint256 shares = erc4626.deposit(amount, currentActor);

//         assertEq(underlying.balanceOf(currentActor), underlyingBalanceBefore - amount);
//         assertEq(erc4626.balanceOf(currentActor), balanceBefore + shares);

//         _assertLiquidityExchangePrices();

//         ghost_sumBalanceOf += shares;
//     }

//     function withdraw(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
//         amount = bound(amount, 1, 1e28);

//         // can not withdraw more than currently present in liquidity...
//         // todo: should this be part of maxWithdraw?
//         amount = bound(amount, 0, _availableInLiquidity() / maxWithdrawDenominator);
//         // todo: how are rewards made available? deposit with some address and burn received shares?

//         amount = bound(amount, 0, erc4626.maxWithdraw(currentActor) / maxWithdrawDenominator);

//         uint256 balanceBefore = erc4626.balanceOf(currentActor);
//         uint256 underlyingBalanceBefore = underlying.balanceOf(currentActor);

//         uint256 shares;
//         try erc4626.withdraw(amount, currentActor, currentActor, 0) returns (uint256 shares_) {
//             shares = shares_;

//             // expected inaccuracy 1e12
//             assertApproxEqAbs(underlying.balanceOf(currentActor), underlyingBalanceBefore + amount, amount / 1e12 + 1);

//             assertEq(erc4626.balanceOf(currentActor), balanceBefore - shares);

//             _assertLiquidityExchangePrices();

//             ghost_sumBalanceOf -= shares;
//         } catch (bytes memory reason) {
//             // catch rounding error
//             // if (bytes(reason) != bytes(ErrorTypes.iToken__RoundingError.selector) {
//             //     assembly {
//             //         revert(add(reason, 32), reason)
//             //     }
//             // }
//         }
//     }

//     /// @dev simulate passing time to generate yield in liquidity or accrue rewards in iToken
//     function simulatePassingTime(uint256 timeForward) public {
//         timeForward = bound(timeForward, 1 days, 100 days);

//         // jump into future
//         vm.warp(block.timestamp + timeForward);

//         _assertLiquidityExchangePrices();
//     }

//     function _availableInLiquidity() internal view returns (uint256 availableInLiquidity) {
//         uint256 totalSupply = liquidityProxy.totalSupply(address(underlying));
//         uint256 totalBorrow = liquidityProxy.totalBorrow(address(underlying));

//         if (totalBorrow > totalSupply) {
//             return 0;
//         }

//         availableInLiquidity = totalSupply - totalBorrow;

//         if (availableInLiquidity > 1e12) {
//             availableInLiquidity -= availableInLiquidity / 12 + 1; // tolerance for expected 1e12 inaccuracy
//         }
//     }

//     function _assertLiquidityExchangePrices() internal {
//         (
//             uint256 newLiquiditySafeExchangePrice,
//             uint256 newLiquidityRiskyExchangePrice,
//             uint256 newLiquidityBorrowExchangePrice
//         ) = liquidityProxy.exchangePrice(address(underlying));

//         if (lastLiquiditySafeExchangePrice != 0) {
//             assertGe(newLiquiditySafeExchangePrice, lastLiquiditySafeExchangePrice);
//             assertGe(newLiquidityRiskyExchangePrice, lastLiquidityRiskyExchangePrice);
//             assertGe(newLiquidityBorrowExchangePrice, lastLiquidityBorrowExchangePrice);
//         }
//     }
// }

// contract iTokenInvariantHandlerWithBorrow is iTokenInvariantHandler {
//     constructor(
//         iToken erc4626_,
//         address[] memory actors_,
//         TestERC20 underlying_,
//         ILiquidity liquidityProxy_,
//         uint256 maxWithdrawDenominator_
//     ) iTokenInvariantHandler(erc4626_, actors_, underlying_, liquidityProxy_, maxWithdrawDenominator_) {}

//     function borrow(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
//         amount = bound(amount, 1, 1e28);
//         amount = bound(amount, 0, _availableInLiquidity());

//         liquidityProxy.borrow(address(underlying), amount, currentActor);

//         _assertLiquidityExchangePrices();
//     }
// }

// contract iTokenInvariantHandlerWithRepay is iTokenInvariantHandlerWithBorrow {
//     constructor(
//         iToken erc4626_,
//         address[] memory actors_,
//         TestERC20 underlying_,
//         ILiquidity liquidityProxy_,
//         uint256 maxWithdrawDenominator_
//     ) iTokenInvariantHandlerWithBorrow(erc4626_, actors_, underlying_, liquidityProxy_, maxWithdrawDenominator_) {}

//     function repay(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
//         amount = bound(amount, 1, 1e28);

//         (, , uint256 actorBorrow) = liquidityProxy.balancesOf(address(underlying), currentActor);
//         amount = bound(amount, 0, actorBorrow);

//         liquidityProxy.repay(address(underlying), amount, currentActor);

//         _assertLiquidityExchangePrices();
//     }
// }

// /// @dev tests random interactions with liquidity incl. borrow without iToken rewards
// abstract contract iTokenBaseInvariantTestCore is iTokenBaseSetUp {
//     iTokenInvariantHandler public handler;
//     iTokenInvariantHandlerWithBorrow public handlerWithBorrow;
//     iTokenInvariantHandlerWithRepay public handlerWithRepay;

//     iToken erc4626;

//     function setUp() public virtual override {
//         super.setUp();

//         erc4626 = iToken(factory.createToken(address(USDC), ILendingFactory.ITokenType.EIP2612Deposits));

//         // withdraw direct supply into liquidity from alice executed in setUp()
//         vm.prank(alice);
//         liquidityProxy.withdrawSafe(address(underlying), DEFAULT_AMOUNT, alice);

//         _setDefaultRateDataV1(address(liquidityProxy), admin, address(USDC));
//         // set 0% a year rewards rate
//         rewards.setRate(0);

//         address[] memory actors_ = new address[](2);
//         actors_[0] = alice;
//         actors_[1] = bob;

//         // setting maxWithdrawDenominator to 5 so that only 1/5 of what user has deposited can be withdrawn
//         // this has the effect that deposits are likely to outgrow withdraws, thus creating yield and surplus
//         handler = new iTokenInvariantHandler(erc4626, actors_, underlying, liquidityProxy, 5);

//         // setting maxWithdrawDenominator to 5 so that only 1/5 of what user has deposited can be withdrawn
//         // this has the effect that deposits are likely to outgrow withdraws, thus creating yield and surplus
//         handlerWithBorrow = new iTokenInvariantHandlerWithBorrow(erc4626, actors_, underlying, liquidityProxy, 5);

//         // setting maxWithdrawDenominator to 1, this test is supposed to simulate actions more broadly
//         handlerWithRepay = new iTokenInvariantHandlerWithRepay(erc4626, actors_, underlying, liquidityProxy, 1);

//         _setTargetContract();

//         // set unlimited borrow amount limits for bob and alice
//         // AdminModuleStructs.TokenAllowancesConfig[] memory tokenConfigs = new AdminModuleStructs.TokenAllowancesConfig[](
//         //     1
//         // );
//         // tokenConfigs[0] = AdminModuleStructs.TokenAllowancesConfig({
//         //     token: address(underlying),
//         //     supplySafe: true,
//         //     supplyRisky: true,
//         //     baseDebtCeiling: 1e30 ether,
//         //     maxDebtCeiling: 1e30 ether,
//         //     expandDebtCeilingPercentage: DEFAULT_EXPAND_DEBT_CEILING_PERCENT,
//         //     expandDebtCeilingDuration: DEFAULT_EXPAND_DEBT_CEILING_DURATION,
//         //     shrinkDebtCeilingDuration: DEFAULT_SHRINK_DEBT_CEILING_DURATION
//         // });

//         // vm.prank(admin);
//         // liquidityProxy.setUserAllowances(alice, tokenConfigs);
//         // vm.prank(admin);
//         // liquidityProxy.setUserAllowances(bob, tokenConfigs);
//     }

//     function _setTargetContract() internal virtual {
//         targetContract(address(handlerWithBorrow));
//     }

//     function invariant_totalAssetsVsLiquiditySupply() public {
//         uint256 aliceBalance = erc4626.previewRedeem(erc4626.balanceOf(alice));
//         uint256 bobBalance = erc4626.previewRedeem(erc4626.balanceOf(bob));
//         uint256 allUserAssets = aliceBalance + bobBalance;

//         uint256 totalAssets = erc4626.totalAssets();

//         uint256 liquidityTotalSupply = liquidityProxy.totalSupply(address(underlying));

//         // tolerance for expected 1e12 inaccuracy
//         liquidityTotalSupply -= (liquidityTotalSupply / 1e12);

//         // all user assets should always be less or equal total assets of iToken vault
//         assertLe(allUserAssets, totalAssets);

//         // totalAssets is always liquiditySupply or more because of rewards.
//         // rewards must be added via `rebalance` by owner, which will deposit into Liquidity without minting shares.
//         assertGe(totalAssets, liquidityTotalSupply);

//         // after funding enough rewards, liquidityTotalSupply should cover totalAssets
//         uint256 rewardsDifference = totalAssets - liquidityTotalSupply;
//         if (rewardsDifference > 0) {
//             vm.prank(admin);
//             erc4626.rebalance();

//             liquidityTotalSupply = liquidityProxy.totalSupply(address(underlying));
//             // tolerance for expected 1e12 inaccuracy
//             liquidityTotalSupply += (liquidityTotalSupply / 1e12);

//             assertLe(totalAssets, liquidityTotalSupply);
//         }
//     }

//     function invariant_totalSupplyAlwaysSumOfUserShares() public {
//         uint256 aliceBalance = erc4626.balanceOf(alice);
//         uint256 bobBalance = erc4626.balanceOf(bob);

//         assertEq(aliceBalance + bobBalance, erc4626.totalSupply());

//         assertEq(iTokenInvariantHandler(targetContracts()[0]).ghost_sumBalanceOf(), erc4626.totalSupply());
//     }

//     function invariant_liquidityBorrowAlwaysLessThanSupply() public {
//         uint256 totalBorrow = liquidityProxy.totalBorrow(address(underlying));
//         if (totalBorrow > 1) {
//             totalBorrow -= 1; // rounding down
//         }
//         if (totalBorrow > 1e12) {
//             // tolerance for expected 1e12 inaccuracy
//             uint256 totalBorrowTolerance = totalBorrow / 1e12 + 1;
//             totalBorrow -= totalBorrowTolerance;
//         }

//         uint256 liquidityTotalSupply = liquidityProxy.totalSupply(address(underlying)) + 1; // rounding up

//         assertLt(totalBorrow, liquidityTotalSupply);
//     }
// }

// /// @dev tests random interactions with liquidity incl. borrow with iToken rewards active
// abstract contract iTokenBaseInvariantTestRewards is iTokenBaseInvariantTestCore {
//     function setUp() public virtual override {
//         super.setUp();

//         // set 200% a year rewards rate
//         rewards.setRate(EXCHANGE_PRICES_PRECISION * 2);
//     }
// }

// /// @dev tests random interactions with liquidity incl. borrow with iToken rewards active but no yield in liquidity itself
// abstract contract iTokenBaseInvariantTestRewardsNoBorrowers is iTokenBaseInvariantTestCore {
//     function setUp() public virtual override {
//         super.setUp();

//         // set 200% a year rewards rate
//         rewards.setRate(EXCHANGE_PRICES_PRECISION * 2);

//         // start with deposit and simulate passing time to accrue rewards right away without borrowers
//         iTokenInvariantHandler(targetContracts()[0]).deposit(DEFAULT_AMOUNT, 0);
//         iTokenInvariantHandler(targetContracts()[0]).simulatePassingTime(10 days);
//     }

//     function _setTargetContract() internal virtual override {
//         targetContract(address(handler));
//     }
// }

// /// @dev tests random interactions with liquidity incl. borrow and repay and withdraw up to full amount
// abstract contract iTokenBaseInvariantTestWithRepay is iTokenBaseInvariantTestCore {
//     function setUp() public virtual override {
//         super.setUp();
//     }

//     function _setTargetContract() internal virtual override {
//         targetContract(address(handlerWithRepay));
//     }
// }
