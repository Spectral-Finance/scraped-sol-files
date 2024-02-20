//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IAllowanceTransfer } from "../../../../contracts/protocols/lending/interfaces/permit2/iAllowanceTransfer.sol";
import { MockERC20Permit } from "../../utils/mocks/MockERC20Permit.sol";
import { iToken } from "../../../../contracts/protocols/lending/iToken/main.sol";
import { iTokenNativeUnderlying } from "../../../../contracts/protocols/lending/iToken/nativeUnderlying/iTokenNativeUnderlying.sol";
import { iTokenWithInterestTestBase } from "../../lending/iTokenWithInterest.t.sol";
import { LendingResolver } from "../../../../contracts/periphery/resolvers/lending/main.sol";
import { ILendingFactory } from "../../../../contracts/protocols/lending/interfaces/iLendingFactory.sol";
import { ILendingRewardsRateModel } from "../../../../contracts/protocols/lending/interfaces/iLendingRewardsRateModel.sol";
import { LendingRewardsRateModel } from "../../../../contracts/protocols/lending/lendingRewardsRateModel/main.sol";
import { IIToken } from "../../../../contracts/protocols/lending/interfaces/iIToken.sol";
import { Structs as LendingResolverStructs } from "../../../../contracts/periphery/resolvers/lending/structs.sol";
import { Structs as LiquidityResolverStructs } from "../../../../contracts/periphery/resolvers/liquidity/structs.sol";
import { LiquidityResolver } from "../../../../contracts/periphery/resolvers/liquidity/main.sol";
import { ILiquidityResolver } from "../../../../contracts/periphery/resolvers/liquidity/iLiquidityResolver.sol";
import { Structs as AdminModuleStructs } from "../../../../contracts/liquidity/adminModule/structs.sol";
import { AdminModule } from "../../../../contracts/liquidity/adminModule/main.sol";
import { ILiquidity } from "../../../../contracts/liquidity/interfaces/iLiquidity.sol";
import { Structs as LendingRewardsRateModelStructs } from "../../../../contracts/protocols/lending/lendingRewardsRateModel/structs.sol";
import { LendingRewardsRateMockModel } from "../../lending/mocks/rewardsMock.sol";

abstract contract LendingResolverTestBase is iTokenWithInterestTestBase {
    LendingResolver lendingResolver;

    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();
        LiquidityResolver liquidityResolver = new LiquidityResolver(ILiquidity(address(liquidity)));
        lendingResolver = new LendingResolver(
            ILendingFactory(address(factory)),
            ILiquidityResolver(address(liquidityResolver))
        );

        // setting configs in order to make LiquidityCalcs working

        _setDefaultRateDataV2(address(liquidity), admin, address(USDC));
        _setDefaultRateDataV2(address(liquidity), admin, address(WETH_ADDRESS));
        AdminModuleStructs.TokenConfig[] memory tokenConfigs_ = new AdminModuleStructs.TokenConfig[](2);
        tokenConfigs_[0] = AdminModuleStructs.TokenConfig({
            token: address(USDC),
            fee: 1000, // 10%
            threshold: 100 // 1%
        });
        tokenConfigs_[1] = AdminModuleStructs.TokenConfig({
            token: address(WETH_ADDRESS),
            fee: 1000, // 10%
            threshold: 100 // 1%
        });
        vm.prank(admin);
        AdminModule(address(liquidity)).updateTokenConfigs(tokenConfigs_);

        vm.prank(admin);
        factory.setITokenCreationCode("iToken", type(iToken).creationCode);
        vm.prank(admin);
        factory.setITokenCreationCode("NativeUnderlying", type(iTokenNativeUnderlying).creationCode);

        _setUserAllowancesDefault(address(liquidity), admin, address(USDC), address(lendingIToken));
        _setUserAllowancesDefault(address(liquidity), admin, address(WETH_ADDRESS), address(lendingIToken));
    }
}

contract LendingResolverTest is LendingResolverTestBase {
    function test_deployment() public {
        assertEq(address(lendingResolver.LENDING_FACTORY()), address(factory));
    }

    function test_getAllITokens() public {
        address[] memory iTokens_ = lendingResolver.getAllITokens();

        assertEq(iTokens_.length, 1);
        assertEq(iTokens_[0], address(lendingIToken));
    }

    function test_getAllITokensMultiple() public {
        address token1 = address(lendingIToken);
        vm.prank(admin);
        address token2 = factory.createToken(address(WETH_ADDRESS), "NativeUnderlying", true);

        address[2] memory createdTokens = [token1, token2];
        address[] memory allTokens = lendingResolver.getAllITokens();

        assertEq(createdTokens.length, allTokens.length);

        for (uint256 i = 0; i < createdTokens.length; i++) {
            assertEq(createdTokens[i], allTokens[i]);
        }
    }

    function test_computeIToken() public {
        address underlying = lendingIToken.asset();
        address expectedAddress = lendingResolver.computeIToken(underlying, "iToken");

        assertEq(expectedAddress, address(lendingIToken));
    }

    function test_getITokenDetails() public {
        LendingResolverStructs.ITokenDetails memory details = lendingResolver.getITokenDetails(lendingIToken);
        (, uint256 rewardsRate_) = lendingResolver.getITokenRewards(lendingIToken);

        LendingResolverStructs.ITokenDetails memory expectedDetails = LendingResolverStructs.ITokenDetails({
            eip2612Deposits: false,
            isNativeUnderlying: false,
            name: "Fluid Interest USDC",
            symbol: "fiUSDC",
            decimals: 6,
            asset: address(USDC),
            totalAssets: 0,
            totalSupply: 0,
            convertToShares: 1e6,
            convertToAssets: 1e6,
            tokenAddress: address(lendingIToken),
            rewardsRate: rewardsRate_,
            supplyRate: 0,
            rebalanceDifference: 0,
            liquidityUserSupplyData: LiquidityResolverStructs.UserSupplyData({
                modeWithInterest: true,
                supply: 0,
                withdrawalLimit: 0,
                withdrawableUntilLimit: 0,
                withdrawable: 0,
                expandPercent: DEFAULT_EXPAND_WITHDRAWAL_LIMIT_PERCENT,
                expandDuration: DEFAULT_EXPAND_WITHDRAWAL_LIMIT_DURATION,
                baseWithdrawalLimit: DEFAULT_BASE_WITHDRAWAL_LIMIT_AFTER_BIGMATH,
                lastUpdateTimestamp: 0
            })
        });

        assertITokenDetails(details, expectedDetails);

        // do a deposit to get total supply up etc.
        uint256 usdcBalanceBefore = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 shares = lendingIToken.deposit(DEFAULT_AMOUNT, alice);

        assertEqDecimal(shares, DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEq(usdcBalanceBefore - underlying.balanceOf(alice), DEFAULT_AMOUNT);

        // assert values change as expected
        details = lendingResolver.getITokenDetails(lendingIToken);
        LendingResolverStructs.ITokenDetails memory expectedDetailsAfterDeposit = LendingResolverStructs.ITokenDetails({
            eip2612Deposits: false,
            isNativeUnderlying: false,
            name: "Fluid Interest USDC",
            symbol: "fiUSDC",
            decimals: 6,
            asset: address(USDC),
            totalAssets: DEFAULT_AMOUNT,
            totalSupply: DEFAULT_AMOUNT,
            convertToShares: 1e6,
            convertToAssets: 1e6,
            tokenAddress: address(lendingIToken),
            rewardsRate: rewardsRate_,
            supplyRate: 0,
            rebalanceDifference: 0,
            liquidityUserSupplyData: LiquidityResolverStructs.UserSupplyData({
                modeWithInterest: true,
                supply: DEFAULT_AMOUNT,
                withdrawalLimit: 0,
                withdrawableUntilLimit: DEFAULT_AMOUNT,
                withdrawable: DEFAULT_AMOUNT,
                expandPercent: DEFAULT_EXPAND_WITHDRAWAL_LIMIT_PERCENT,
                expandDuration: DEFAULT_EXPAND_WITHDRAWAL_LIMIT_DURATION,
                baseWithdrawalLimit: DEFAULT_BASE_WITHDRAWAL_LIMIT_AFTER_BIGMATH,
                lastUpdateTimestamp: block.timestamp
            })
        });

        assertITokenDetails(details, expectedDetailsAfterDeposit);
    }

    function test_getITokenInternalData() public {
        (
            ILiquidity liquidity_,
            ILendingFactory lendingFactory_,
            ILendingRewardsRateModel lendingRewardsRateModel_,
            IAllowanceTransfer permit2_,
            address rebalancer_,
            bool rewardsActive_,
            uint256 liquidityBalance_,
            uint256 liquidityExchangePrice_,
            uint256 tokenExchangePrice_
        ) = lendingResolver.getITokenInternalData(lendingIToken);

        assertEq(address(liquidity_), address(liquidity));
        assertEq(address(lendingFactory_), address(factory));
        assertEq(address(lendingRewardsRateModel_), address(rewards));
        assertEq(address(permit2_), address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
        assertEq(address(rebalancer_), admin);
        assertEq(rewardsActive_, true);
        assertEq(liquidityBalance_, 0);
        assertEq(liquidityExchangePrice_, EXCHANGE_PRICES_PRECISION);
        assertEq(tokenExchangePrice_, EXCHANGE_PRICES_PRECISION);

        {
            // do a deposit to get total supply up etc.
            uint256 usdcBalanceBefore = underlying.balanceOf(alice);
            vm.prank(alice);
            uint256 shares = lendingIToken.deposit(DEFAULT_AMOUNT, alice);
            assertEqDecimal(shares, DEFAULT_AMOUNT, DEFAULT_DECIMALS);
            assertEqDecimal(lendingIToken.balanceOf(alice), DEFAULT_AMOUNT, DEFAULT_DECIMALS);
            assertEq(usdcBalanceBefore - underlying.balanceOf(alice), DEFAULT_AMOUNT);
        }

        // assert values change as expected
        (
            ,
            ,
            ,
            ,
            rebalancer_,
            rewardsActive_,
            liquidityBalance_,
            liquidityExchangePrice_,
            tokenExchangePrice_
        ) = lendingResolver.getITokenInternalData(lendingIToken);

        assertEq(address(rebalancer_), admin);
        assertEq(rewardsActive_, true);
        assertEq(liquidityBalance_, DEFAULT_AMOUNT);
        assertEq(liquidityExchangePrice_, EXCHANGE_PRICES_PRECISION);
        assertEq(tokenExchangePrice_, EXCHANGE_PRICES_PRECISION);

        vm.prank(alice);
        lendingIToken.withdraw(DEFAULT_AMOUNT, alice, alice);
    }

    function test_getITokenDetailsTypeNativeUnderlying() public {
        vm.prank(admin);
        address token = factory.createToken(address(WETH_ADDRESS), "NativeUnderlying", true);

        LendingResolverStructs.ITokenDetails memory details = lendingResolver.getITokenDetails(IIToken(token));

        assertEq(details.eip2612Deposits, false);
        assertEq(details.isNativeUnderlying, true);
    }

    function test_getITokenDetailsWithYield() public {
        // todo
    }

    function test_getITokensEntireData() public {
        vm.prank(admin);
        factory.createToken(address(WETH_ADDRESS), "NativeUnderlying", true);
        vm.prank(admin);
        factory.createToken(address(DAI), "iToken", false);

        LendingResolverStructs.ITokenDetails[] memory allDetails = lendingResolver.getITokensEntireData();

        address[] memory allTokens = lendingResolver.getAllITokens();
        assertEq(allTokens.length, allDetails.length);

        for (uint256 i = 0; i < allDetails.length; i++) {
            LendingResolverStructs.ITokenDetails memory tokenDetails = lendingResolver.getITokenDetails(
                IIToken(allTokens[i])
            );
            LendingResolverStructs.ITokenDetails memory expectedTokenDetails = LendingResolverStructs.ITokenDetails({
                eip2612Deposits: allDetails[i].eip2612Deposits,
                isNativeUnderlying: allDetails[i].isNativeUnderlying,
                name: allDetails[i].name,
                symbol: allDetails[i].symbol,
                decimals: allDetails[i].decimals,
                asset: allDetails[i].asset,
                totalAssets: allDetails[i].totalAssets,
                totalSupply: allDetails[i].totalSupply,
                convertToShares: allDetails[i].convertToShares,
                convertToAssets: allDetails[i].convertToAssets,
                tokenAddress: allDetails[i].tokenAddress,
                rewardsRate: allDetails[i].rewardsRate,
                supplyRate: allDetails[i].supplyRate,
                rebalanceDifference: allDetails[i].rebalanceDifference,
                liquidityUserSupplyData: allDetails[i].liquidityUserSupplyData
            });

            assertITokenDetails(tokenDetails, expectedTokenDetails);
        }
    }

    function test_getITokenRewards() public {
        (ILendingRewardsRateModel rewardsRateModel_, uint256 rewardsRate_) = lendingResolver.getITokenRewards(
            lendingIToken
        );
        assertEq(address(rewardsRateModel_), address(rewards));
        assertEq(rewardsRate_, 20 * 1e12); // 20%
    }

    function test_getITokenRewardsRateModelConfig() public {
        uint256 decimals_ = block.timestamp + 10 days;
        uint256 startTime_ = block.timestamp + 10 days;
        uint256 endTime_ = startTime_ + 365 days;

        uint256 PERCENT_PRECISION = 1e2;

        uint256 kink1 = 10_000 * decimals_;
        uint256 kink2 = 50_000 * decimals_;
        uint256 kink3 = 350_000 * decimals_;
        uint256 rateZeroAtTVL = 1_000_000 * decimals_;
        uint256 rateAtTVLZero = 20 * PERCENT_PRECISION;
        uint256 rateAtTVLKink1 = 10 * PERCENT_PRECISION;
        uint256 rateAtTVLKink2 = 5 * PERCENT_PRECISION;
        uint256 rateAtTVLKink3 = 2 * PERCENT_PRECISION;

        LendingRewardsRateModelStructs.RateDataParams memory rateData_ = LendingRewardsRateModelStructs.RateDataParams({
            kink1: kink1,
            kink2: kink2,
            kink3: kink3,
            rateZeroAtTVL: rateZeroAtTVL,
            rateAtTVLZero: rateAtTVLZero,
            rateAtTVLKink1: rateAtTVLKink1,
            rateAtTVLKink2: rateAtTVLKink2,
            rateAtTVLKink3: rateAtTVLKink3
        });

        LendingRewardsRateModel rateModel = new LendingRewardsRateModel(decimals_, startTime_, endTime_, rateData_);

        vm.prank(admin);
        factory.setAuth(alice, true);
        vm.prank(alice);
        lendingIToken.updateRewards(rateModel);

        LendingRewardsRateModelStructs.Config memory config = lendingResolver.getITokenRewardsRateModelConfig(
            lendingIToken
        );

        LendingRewardsRateModelStructs.Config memory expectedConfig = ILendingRewardsRateModel(rateModel).getConfig();

        assertEq(expectedConfig.assetDecimals, config.assetDecimals);
        assertEq(expectedConfig.maxRate, config.maxRate);
        assertEq(expectedConfig.startTime, config.startTime);
        assertEq(expectedConfig.endTime, config.endTime);
        assertEq(expectedConfig.kink1, config.kink1);
        assertEq(expectedConfig.kink2, config.kink2);
        assertEq(expectedConfig.kink3, config.kink3);
        assertEq(expectedConfig.rateZeroAtTVL, config.rateZeroAtTVL);
        assertEq(expectedConfig.slope1, config.slope1);
        assertEq(expectedConfig.slope2, config.slope2);
        assertEq(expectedConfig.slope3, config.slope3);
        assertEq(expectedConfig.slope4, config.slope4);
        assertEq(expectedConfig.constant1, config.constant1);
        assertEq(expectedConfig.constant2, config.constant2);
        assertEq(expectedConfig.constant3, config.constant3);
        assertEq(expectedConfig.constant4, config.constant4);
    }

    function test_getUserPosition() public {
        LendingResolverStructs.UserPosition memory userPosition = lendingResolver.getUserPosition(lendingIToken, alice);

        // alice expected balance after executing actions in setup (we are minting twice 1e50 and supplying once 1000 * 1e6)
        uint256 aliceBalance = 199999999999999999999999999999999999999999999999999999999999000000000;
        LendingResolverStructs.UserPosition memory expectedPosition = LendingResolverStructs.UserPosition({
            iTokenShares: 0,
            underlyingAssets: 0,
            underlyingBalance: aliceBalance,
            allowance: type(uint256).max
        });

        assertUserPosition(userPosition, expectedPosition);

        // do a deposit to get supply of alice up etc.
        uint256 usdcBalanceBefore = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 shares = lendingIToken.deposit(DEFAULT_AMOUNT, alice);

        assertEqDecimal(shares, DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEq(usdcBalanceBefore - underlying.balanceOf(alice), DEFAULT_AMOUNT);

        // assert values change as expected
        userPosition = lendingResolver.getUserPosition(lendingIToken, alice);

        LendingResolverStructs.UserPosition memory expectedPositionAfter = LendingResolverStructs.UserPosition({
            iTokenShares: shares,
            underlyingAssets: DEFAULT_AMOUNT,
            underlyingBalance: aliceBalance - DEFAULT_AMOUNT,
            allowance: type(uint256).max
        });

        assertUserPosition(userPosition, expectedPositionAfter);
    }

    function test_getUserPositions() public {
        address user = address(alice);
        address[] memory allTokens = lendingResolver.getAllITokens();
        LendingResolverStructs.ITokenDetailsUserPosition[] memory positions = lendingResolver.getUserPositions(
            address(alice)
        );
        LendingResolverStructs.ITokenDetails[] memory allDetails = lendingResolver.getITokensEntireData();

        assertEq(allTokens.length, allDetails.length);
        assertEq(positions.length, allDetails.length);

        for (uint256 i = 0; i < allDetails.length; i++) {
            LendingResolverStructs.UserPosition memory userPosition = lendingResolver.getUserPosition(
                IIToken(allTokens[i]),
                user
            );

            LendingResolverStructs.ITokenDetails memory expectedTokenDetails = LendingResolverStructs.ITokenDetails({
                eip2612Deposits: allDetails[i].eip2612Deposits,
                isNativeUnderlying: allDetails[i].isNativeUnderlying,
                name: allDetails[i].name,
                symbol: allDetails[i].symbol,
                decimals: allDetails[i].decimals,
                asset: allDetails[i].asset,
                totalAssets: allDetails[i].totalAssets,
                totalSupply: allDetails[i].totalSupply,
                convertToShares: allDetails[i].convertToShares,
                convertToAssets: allDetails[i].convertToAssets,
                tokenAddress: allDetails[i].tokenAddress,
                rewardsRate: allDetails[i].rewardsRate,
                supplyRate: allDetails[i].supplyRate,
                rebalanceDifference: allDetails[i].rebalanceDifference,
                liquidityUserSupplyData: allDetails[i].liquidityUserSupplyData
            });

            assertITokenDetails(positions[i].iTokenDetails, expectedTokenDetails);

            assertUserPosition(positions[i].userPosition, userPosition);
        }
    }

    function test_getPreviews() public {
        (
            uint256 previewDeposit_,
            uint256 previewMint_,
            uint256 previewWithdraw_,
            uint256 previewRedeem_
        ) = lendingResolver.getPreviews(lendingIToken, DEFAULT_AMOUNT, DEFAULT_AMOUNT);

        assertEq(previewDeposit_, DEFAULT_AMOUNT);
        assertEq(previewMint_, DEFAULT_AMOUNT);
        assertEq(previewWithdraw_, DEFAULT_AMOUNT);
        assertEq(previewRedeem_, DEFAULT_AMOUNT);

        // do a deposit to get rates to change
        uint256 usdcBalanceBefore = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 shares = lendingIToken.deposit(DEFAULT_AMOUNT, alice);

        assertEqDecimal(shares, DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEqDecimal(lendingIToken.balanceOf(alice), DEFAULT_AMOUNT, DEFAULT_DECIMALS);
        assertEq(usdcBalanceBefore - underlying.balanceOf(alice), DEFAULT_AMOUNT);

        // warp 1 year time to get rewards to increase value of shares
        // shares will be worth 1.2 times now because rewards rate is 20%
        vm.warp(block.timestamp + PASS_1YEAR_TIME);

        // assert values change as expected
        (previewDeposit_, previewMint_, previewWithdraw_, previewRedeem_) = lendingResolver.getPreviews(
            lendingIToken,
            DEFAULT_AMOUNT,
            DEFAULT_AMOUNT
        );
        assertEq(previewMint_, (DEFAULT_AMOUNT * 12) / 10);
        assertEq(previewRedeem_, (DEFAULT_AMOUNT * 12) / 10);

        // token deposit is worth 20% less in shares. so DEFAULT_AMOUNT = 120% of x
        // so x = 1000000000 / 120% = 833333333
        assertEq(previewDeposit_, 833333333);
        assertEq(previewWithdraw_, 833333334); // rounded up
    }

    // Utility function to assert ITokenDetails

    function assertITokenDetails(
        LendingResolverStructs.ITokenDetails memory details,
        LendingResolverStructs.ITokenDetails memory expectedDetails
    ) internal {
        assertEq(details.eip2612Deposits, expectedDetails.eip2612Deposits);
        assertEq(details.isNativeUnderlying, expectedDetails.isNativeUnderlying);
        assertEq(details.name, expectedDetails.name);
        assertEq(details.symbol, expectedDetails.symbol);
        assertEq(details.decimals, expectedDetails.decimals);
        assertEq(details.asset, expectedDetails.asset);
        assertEq(details.totalAssets, expectedDetails.totalAssets);
        assertEq(details.totalSupply, expectedDetails.totalSupply);
        assertEq(details.convertToShares, expectedDetails.convertToShares);
        assertEq(details.convertToAssets, expectedDetails.convertToAssets);
        assertEq(details.tokenAddress, expectedDetails.tokenAddress);
        assertEq(details.rewardsRate, expectedDetails.rewardsRate);
        assertEq(details.supplyRate, expectedDetails.supplyRate);
        assertEq(details.rebalanceDifference, expectedDetails.rebalanceDifference);
        assertEq(details.liquidityUserSupplyData.supply, expectedDetails.liquidityUserSupplyData.supply);
        assertEq(
            details.liquidityUserSupplyData.withdrawalLimit,
            expectedDetails.liquidityUserSupplyData.withdrawalLimit
        );
        assertEq(details.liquidityUserSupplyData.withdrawable, expectedDetails.liquidityUserSupplyData.withdrawable);
        assertEq(details.liquidityUserSupplyData.expandPercent, expectedDetails.liquidityUserSupplyData.expandPercent);
        assertEq(
            details.liquidityUserSupplyData.expandDuration,
            expectedDetails.liquidityUserSupplyData.expandDuration
        );
        assertEq(
            details.liquidityUserSupplyData.baseWithdrawalLimit,
            expectedDetails.liquidityUserSupplyData.baseWithdrawalLimit
        );
        assertEq(
            details.liquidityUserSupplyData.lastUpdateTimestamp,
            expectedDetails.liquidityUserSupplyData.lastUpdateTimestamp
        );
    }

    // Utility function to assert UserPosition
    function assertUserPosition(
        LendingResolverStructs.UserPosition memory actualPosition,
        LendingResolverStructs.UserPosition memory expectedPosition
    ) internal {
        assertEq(actualPosition.iTokenShares, expectedPosition.iTokenShares);
        assertEq(actualPosition.underlyingAssets, expectedPosition.underlyingAssets);
        assertEq(actualPosition.underlyingBalance, expectedPosition.underlyingBalance);
        assertEq(actualPosition.allowance, expectedPosition.allowance);
    }
}

contract LendingResolverEIP2612Test is LendingResolverTestBase {
    function _createUnderlying() internal virtual override returns (address) {
        MockERC20Permit mockERC20 = new MockERC20Permit("TestPermitToken", "TestPRM");

        return address(mockERC20);
    }

    function test_getITokenDetailsTypeEIP2612Deposits() public {
        LendingResolverStructs.ITokenDetails memory details = lendingResolver.getITokenDetails(lendingIToken);

        assertEq(details.eip2612Deposits, true);
    }
}
