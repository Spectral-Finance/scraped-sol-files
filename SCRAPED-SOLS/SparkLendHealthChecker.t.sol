// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { IERC20 }    from "lib/erc20-helpers/src/interfaces/IERC20.sol";
import { SafeERC20 } from "lib/erc20-helpers/src/SafeERC20.sol";

import { IPoolDataProvider }  from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import { IPool }              from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import { IPriceOracleGetter } from "lib/aave-v3-core/contracts/interfaces/IPriceOracleGetter.sol";
import { IVariableDebtToken } from "lib/aave-v3-core/contracts/interfaces/IVariableDebtToken.sol";

import { SparkLendHealthChecker } from "../src/SparkLendHealthChecker.sol";

contract SparkLendHealthCheckerTestBase is Test {

    SparkLendHealthChecker public healthChecker;

    address constant DAI             = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant DAI_DEBT_TOKEN  = 0xf705d2B7e92B3F38e6ae7afaDAA2fEE110fE5914;
    address constant DATA_PROVIDER   = 0xFc21d6d146E6086B8359705C8b28512a983db0cb;
    address constant ORACLE          = 0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9;
    address constant POOL            = 0xC13e21B648A5Ee794902342038FF3aDAB66BE987;
    address constant SPARK_WHALE     = 0xf8dE75c7B95edB6f1E639751318f117663021Cf0;
    address constant WETH            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WETH_A_TOKEN    = 0x59cD1C87501baa753d0B5B5Ab5D8416A45cD71DB;
    address constant WETH_DEBT_TOKEN = 0x2e7576042566f8D6990e07A1B61Ad1efd86Ae70d;

    IPool             pool         = IPool(POOL);
    IPoolDataProvider dataProvider = IPoolDataProvider(DATA_PROVIDER);

    function setUp() public {
        vm.createSelectFork(getChain('mainnet').rpcUrl, 18_613_327);
        healthChecker = new SparkLendHealthChecker(POOL, DATA_PROVIDER);
    }

}

contract GetUserHeathTests is SparkLendHealthCheckerTestBase {

    // Avoid stack too deep
    uint256 startingTotalCollateralBase;
    uint256 startingTotalDebtBase;
    uint256 startingAvailableBorrowsBase;
    uint256 startingLT;
    uint256 startingLTV;
    uint256 startingHF;
    bool    startingBelowLT;

    function test_getUserHealth_existingUser() public {
        (
            startingTotalCollateralBase,
            startingTotalDebtBase,
            startingAvailableBorrowsBase,
            startingLT,
            startingLTV,
            startingHF,
            startingBelowLT
        ) = healthChecker.getUserHealth(SPARK_WHALE);

        assertEq(startingTotalCollateralBase,  159_791_364.84024427e8);
        assertEq(startingTotalDebtBase,        90_236_477.26152785e8);
        assertEq(startingAvailableBorrowsBase, 37_596_614.61066757e8);
        assertEq(startingLT,                   82_50);
        assertEq(startingLTV,                  80_00);
        assertEq(startingHF,                   1.460915585291870470 ether);
        assertEq(startingBelowLT,              false);

        uint256 daiPrice = IPriceOracleGetter(ORACLE).getAssetPrice(DAI);

        // USD formatted amount
        uint256 amountToSurpassLT
            = ((startingTotalCollateralBase * 82_50 / 1e4) - startingTotalDebtBase);

        // DAI DebtToken formatted amount
        amountToSurpassLT = amountToSurpassLT * 1e8 * 1e18 / 1e8 / daiPrice;

        // Amount is higher than startingAvailableBorrowsBase because that is based off
        // of LTV
        assertEq(amountToSurpassLT, 41_585_025.410679229301317280 ether);

        // Put the user just below the liquidation threshold
        vm.startPrank(POOL);
        IVariableDebtToken(DAI_DEBT_TOKEN).mint(
            SPARK_WHALE,
            SPARK_WHALE,
            amountToSurpassLT,
            pool.getReserveNormalizedVariableDebt(DAI)
        );
        vm.stopPrank();

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            bool    belowLiquidationThreshold
        ) = healthChecker.getUserHealth(SPARK_WHALE);

        assertEq(totalCollateralBase,         startingTotalCollateralBase);
        assertEq(totalDebtBase,               131_827_875.99320152e8);
        assertEq(availableBorrowsBase,        0);
        assertEq(currentLiquidationThreshold, startingLT);
        assertEq(ltv,                         startingLTV);
        assertEq(healthFactor,                1.000000000000000000 ether);
        assertEq(belowLiquidationThreshold,   false);

        // Mint the smallest unit of debt possible to make position change (1e-8 of a 1e18 token)
        vm.startPrank(POOL);
        IVariableDebtToken(DAI_DEBT_TOKEN).mint(
            SPARK_WHALE,
            SPARK_WHALE,
            1e10,
            pool.getReserveNormalizedVariableDebt(DAI)
        );
        vm.stopPrank();

        // Demonstrated above that these are the only values that change on mint
        (
            ,
            uint256 totalDebtBase2,
            uint256 availableBorrowsBase2,
            ,
            ,
            uint256 healthFactor2,
            bool belowLiquidationThreshold2
        ) = healthChecker.getUserHealth(SPARK_WHALE);

        assertEq(totalDebtBase2,              totalDebtBase + 0.00000001e8);
        assertEq(availableBorrowsBase2,       0);
        assertEq(healthFactor2,               0.999999999999999924 ether);
        assertEq(belowLiquidationThreshold2,  true);
    }

    function test_checkUserHealth_nonExistentUser() public {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            bool belowLiquidationThreshold
        ) = healthChecker.getUserHealth(makeAddr("non-existent-user"));

        assertEq(totalCollateralBase,         0);
        assertEq(totalDebtBase,               0);
        assertEq(availableBorrowsBase,        0);
        assertEq(currentLiquidationThreshold, 0);
        assertEq(ltv,                         0);
        assertEq(healthFactor,                type(uint256).max);
        assertEq(belowLiquidationThreshold,   false);
    }

}

contract GetReserveAssetLiabilityTests is SparkLendHealthCheckerTestBase {

    function test_getReserveAssetLiability_drainAssets() public {
        ( uint256 assets, uint256 liabilities ) = healthChecker.getReserveAssetLiability(WETH);

        assertEq(assets,      144_265.290042485761921174 ether);
        assertEq(liabilities, 144_265.272737835189649701 ether);

        assertGt(assets, liabilities);

        assertEq(assets - liabilities, 0.017304650572271473 ether);

        // Simulate bug/exploit draining WETH from aToken
        vm.startPrank(WETH_A_TOKEN);
        IERC20(WETH).transfer(makeAddr("hacker"), 10_000 ether);

        ( assets, liabilities ) = healthChecker.getReserveAssetLiability(WETH);

        assertEq(assets,      134_265.290042485761921174 ether);
        assertEq(liabilities, 144_265.272737835189649701 ether);

        assertLt(assets, liabilities);

        assertEq(liabilities - assets, 10_000 ether - 0.017304650572271473 ether);
    }

    function test_getReserveAssetLiability_badDebt() public {
        ( uint256 assets, uint256 liabilities ) = healthChecker.getReserveAssetLiability(WETH);

        assertEq(assets,      144_265.290042485761921174 ether);
        assertEq(liabilities, 144_265.272737835189649701 ether);

        assertGt(assets, liabilities);

        assertEq(assets - liabilities, 0.017304650572271473 ether);

        vm.startPrank(POOL);
        IVariableDebtToken(WETH_DEBT_TOKEN).mint(
            SPARK_WHALE, SPARK_WHALE, 100_000 ether, pool.getReserveNormalizedVariableDebt(WETH)
        );
        vm.stopPrank();

        ( assets, liabilities ) = healthChecker.getReserveAssetLiability(WETH);

        assertEq(assets,      244_265.290042485761921174 ether);
        assertEq(liabilities, 144_265.272737835189649701 ether);

        assertGt(assets, liabilities);

        assertEq(assets - liabilities, 100_000 ether + 0.017304650572271473 ether);
    }

}

contract GetAllReservesAssetLiabilityTests is SparkLendHealthCheckerTestBase {

    using SafeERC20 for IERC20;

    function _drainAssets(address asset) internal {
        ( address aToken,, ) = dataProvider.getReserveTokensAddresses(asset);

        // Simulate bug/exploit draining asset from aToken
        vm.startPrank(aToken);
        IERC20(asset).safeTransfer(makeAddr("hacker"), IERC20(asset).balanceOf(aToken));
        vm.stopPrank();
    }

    function test_getAllReservesLiability() public {
        IPoolDataProvider.TokenData[] memory tokenData = dataProvider.getAllReservesTokens();

        SparkLendHealthChecker.ReserveAssetLiability[] memory reserveData
            = healthChecker.getAllReservesAssetLiability();

        assertEq(tokenData.length, reserveData.length);

        for (uint256 i = 0; i < tokenData.length; i++) {
            address reserve = tokenData[i].tokenAddress;

            ( uint256 assets, uint256 liabilities )
                = healthChecker.getReserveAssetLiability(reserve);

            assertEq(reserveData[i].reserve,     reserve);
            assertEq(reserveData[i].assets,      assets);
            assertEq(reserveData[i].liabilities, liabilities);

            assertGe(assets, liabilities);
        }

        for (uint256 i = 0; i < tokenData.length; i++) {
            _drainAssets(tokenData[i].tokenAddress);
        }

        reserveData = healthChecker.getAllReservesAssetLiability();

        for (uint256 i = 0; i < tokenData.length; i++) {
            address reserve = tokenData[i].tokenAddress;

            ( uint256 assets, uint256 liabilities )
                = healthChecker.getReserveAssetLiability(reserve);

            assertEq(reserveData[i].reserve,     reserve);
            assertEq(reserveData[i].assets,      assets);
            assertEq(reserveData[i].liabilities, liabilities);

            // Don't check LT if market is empty
            if (liabilities == 0) continue;

            assertLt(assets, liabilities);
        }
    }

}
