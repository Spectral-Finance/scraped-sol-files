// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";

import { ReserveConfiguration } from "aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import { DataTypes }            from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import { IPool }                from "aave-v3-core/contracts/interfaces/IPool.sol";
import { IPoolConfigurator }    from "aave-v3-core/contracts/interfaces/IPoolConfigurator.sol";

import { MockPoolAddressesProvider } from "./mocks/MockPoolAddressesProvider.sol";
import { MockPoolConfigurator }      from "./mocks/MockPoolConfigurator.sol";
import { MockPool }                  from "./mocks/MockPool.sol";
import { CapAutomatorHarness }       from "./harnesses/CapAutomatorHarness.sol";

import { CapAutomator } from "../src/CapAutomator.sol";

contract CapAutomatorUnitTestBase is Test {

    MockPoolAddressesProvider public mockPoolAddressesProvider;
    MockPool                  public mockPool;
    MockPoolConfigurator      public mockPoolConfigurator;

    address public owner;
    address public asset;

    CapAutomator public capAutomator;

    function setUp() public {
        owner = makeAddr("owner");
        asset = makeAddr("asset");

        mockPool                  = new MockPool();
        mockPoolConfigurator      = new MockPoolConfigurator(mockPool);
        mockPoolAddressesProvider = new MockPoolAddressesProvider(address(mockPool), address(mockPoolConfigurator));

        mockPool.__setSupplyCap(7_000);

        mockPool.aToken().__setDecimals(18);
        mockPool.__setATokenScaledTotalSupply(5_700e18);
        mockPool.__setAccruedToTreasury(50e18);
        mockPool.__setLiquidityIndex(1.2e27);
        // (aToken. scaledTotalSupply + accruedToTreasury) * liquidityIndex = 6_900e18

        mockPool.__setBorrowCap(4_000);

        mockPool.debtToken().__setDecimals(18);
        mockPool.__setTotalDebt(3_900e18);

        capAutomator = new CapAutomator(address(mockPoolAddressesProvider));

        capAutomator.transferOwnership(owner);
    }

}

contract ConstructorTests is CapAutomatorUnitTestBase {

    function test_constructor() public {
        mockPoolAddressesProvider = new MockPoolAddressesProvider(makeAddr("pool"), makeAddr("poolConfigurator"));
        capAutomator              = new CapAutomator(address(mockPoolAddressesProvider));

        assertEq(address(capAutomator.pool()),             makeAddr("pool"));
        assertEq(address(capAutomator.poolConfigurator()), makeAddr("poolConfigurator"));
        assertEq(address(capAutomator.owner()),            address(this));
    }

}

contract TransferOwnershipTests is CapAutomatorUnitTestBase {

    function test_transferOwnership_noAuth() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")));
        capAutomator.transferOwnership(makeAddr("newOwner"));
    }

    function test_transferOwnership_zeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        capAutomator.transferOwnership(address(0));
    }

    function test_transferOwnership() public {
        address newOwner = makeAddr("newOwner");
        assertEq(capAutomator.owner(), owner);

        vm.prank(owner);
        capAutomator.transferOwnership(newOwner);

        assertEq(capAutomator.owner(), newOwner);
    }

}

contract RenounceOwnershipTests is CapAutomatorUnitTestBase {

    function test_renounceOwnership_noAuth() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")));
        capAutomator.renounceOwnership();
    }

    function test_renounceOwnership() public {
        assertEq(capAutomator.owner(), owner);

        vm.prank(owner);
        capAutomator.renounceOwnership();

        assertEq(capAutomator.owner(), address(0));
    }

}

contract SetSupplyCapConfigTests is CapAutomatorUnitTestBase {

    function test_setSupplyCapConfig_noAuth() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")));
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );
    }

    function test_setSupplyCapConfig_zeroCap() public {
        vm.expectRevert("CapAutomator/zero-cap");
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            0,
            0,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            2,
            1,
            12 hours
        );
    }

    function test_setSupplyCapConfig_zeroGap() public {
        vm.expectRevert("CapAutomator/zero-gap");
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            2,
            0,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            2,
            1,
            12 hours
        );
    }

    function test_setSupplyCapConfig_invalidCap() public {
        assertEq(ReserveConfiguration.MAX_VALID_SUPPLY_CAP, 68_719_476_735);

        vm.expectRevert("CapAutomator/invalid-cap");
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            ReserveConfiguration.MAX_VALID_SUPPLY_CAP + 1,
            1_000,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            ReserveConfiguration.MAX_VALID_SUPPLY_CAP,
            1_000,
            12 hours
        );
    }

    function test_setSupplyCapConfig_invalidGap() public {
        vm.expectRevert("CapAutomator/invalid-gap");
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            10_001,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            10_000,
            12 hours
        );
    }

    function test_setSupplyCapConfig_invalidCooldown() public {
        vm.expectRevert("CapAutomator/uint48-cast");
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            uint256(type(uint48).max) + 1
        );

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            uint256(type(uint48).max)
        );
    }

    function test_setSupplyCapConfig() public {
        (
            uint48 max,
            uint48 gap,
            uint48 increaseCooldown,
            uint48 lastUpdateBlock,
            uint48 lastIncreaseTime
        ) = capAutomator.supplyCapConfigs(asset);

        assertEq(max,              0);
        assertEq(gap,              0);
        assertEq(increaseCooldown, 0);
        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        (
            max,
            gap,
            increaseCooldown,
            lastUpdateBlock,
            lastIncreaseTime
        ) = capAutomator.supplyCapConfigs(asset);

        assertEq(max,              10_000);
        assertEq(gap,              1_000);
        assertEq(increaseCooldown, 12 hours);
        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);
    }

    function test_setSupplyCapConfig_reconfigure() public {
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        (
            uint48 max,
            uint48 gap,
            uint48 increaseCooldown,
            ,
        ) = capAutomator.supplyCapConfigs(asset);

        assertEq(max,              10_000);
        assertEq(gap,              1_000);
        assertEq(increaseCooldown, 12 hours);

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            13_000,
            1_300,
            24 hours
        );

        (
            max,
            gap,
            increaseCooldown,
            ,
        ) = capAutomator.supplyCapConfigs(asset);

        assertEq(max,              13_000);
        assertEq(gap,              1_300);
        assertEq(increaseCooldown, 24 hours);
    }

    function test_setSupplyCapConfig_preserveUpdateTrackers() public {
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        ( ,,, uint48 lastUpdateBlock, uint48 lastIncreaseTime ) = capAutomator.supplyCapConfigs(asset);

        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);

        vm.roll(120_000);
        vm.warp(12 hours);
        capAutomator.exec(asset);

        ( ,,, uint48 postExecUpdateBlock, uint48 postExecIncreaseTime ) = capAutomator.supplyCapConfigs(asset);

        assertEq(postExecUpdateBlock,  120_000);
        assertEq(postExecIncreaseTime, 12 hours);

        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            20_000,
            2_000,
            24 hours
        );

        ( ,,, uint48 postReconfigUpdateBlock, uint48 postReconfigIncreaseTime ) = capAutomator.supplyCapConfigs(asset);

        assertEq(postReconfigUpdateBlock,  postExecUpdateBlock);
        assertEq(postReconfigIncreaseTime, postExecIncreaseTime);
    }

}

contract SetBorrowCapConfigTests is CapAutomatorUnitTestBase {

    function test_setBorrowCapConfig_noAuth() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")));
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );
    }

    function test_setBorrowCapConfig_zeroCap() public {
        vm.expectRevert("CapAutomator/zero-cap");
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            0,
            0,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            2,
            1,
            12 hours
        );
    }

    function test_setBorrowCapConfig_zeroGap() public {
        vm.expectRevert("CapAutomator/zero-gap");
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            2,
            0,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            2,
            1,
            12 hours
        );
    }

    function test_setBorrowCapConfig_invalidCap() public {
        assertEq(ReserveConfiguration.MAX_VALID_BORROW_CAP, 68_719_476_735);

        vm.expectRevert("CapAutomator/invalid-cap");
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            ReserveConfiguration.MAX_VALID_BORROW_CAP + 1,
            1_000,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            ReserveConfiguration.MAX_VALID_BORROW_CAP,
            1_000,
            12 hours
        );
    }

    function test_setBorrowCapConfig_invalidGap() public {
        vm.expectRevert("CapAutomator/invalid-gap");
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            10_001,
            12 hours
        );

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            10_000,
            12 hours
        );
    }

    function test_setBorrowCapConfig_invalidCooldown() public {
        vm.expectRevert("CapAutomator/uint48-cast");
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            uint256(type(uint48).max) + 1
        );

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            uint256(type(uint48).max)
        );
    }

    function test_setBorrowCapConfig() public {
        (
            uint48 max,
            uint48 gap,
            uint48 increaseCooldown,
            uint48 lastUpdateBlock,
            uint48 lastIncreaseTime
        ) = capAutomator.borrowCapConfigs(asset);

        assertEq(max,              0);
        assertEq(gap,              0);
        assertEq(increaseCooldown, 0);
        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        (
            max,
            gap,
            increaseCooldown,
            lastUpdateBlock,
            lastIncreaseTime
        ) = capAutomator.borrowCapConfigs(asset);

        assertEq(max,              10_000);
        assertEq(gap,              1_000);
        assertEq(increaseCooldown, 12 hours);
        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);
    }

    function test_setBorrowCapConfig_reconfigure() public {
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        (
            uint48 max,
            uint48 gap,
            uint48 increaseCooldown,
            ,
        ) = capAutomator.borrowCapConfigs(asset);

        assertEq(max,              10_000);
        assertEq(gap,              1_000);
        assertEq(increaseCooldown, 12 hours);

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            13_000,
            1_300,
            24 hours
        );

        (
            max,
            gap,
            increaseCooldown,
            ,
        ) = capAutomator.borrowCapConfigs(asset);

        assertEq(max,              13_000);
        assertEq(gap,              1_300);
        assertEq(increaseCooldown, 24 hours);
    }

    function test_setBorrowCapConfig_preserveUpdateTrackers() public {
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        ( ,,, uint48 lastUpdateBlock, uint48 lastIncreaseTime ) = capAutomator.borrowCapConfigs(asset);

        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);

        vm.roll(600);
        vm.warp(12 hours);
        capAutomator.exec(asset);

        ( ,,, uint48 postExecUpdateBlock, uint48 postExecIncreaseTime ) = capAutomator.borrowCapConfigs(asset);

        assertEq(postExecUpdateBlock,  600);
        assertEq(postExecIncreaseTime, 12 hours);

        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            20_000,
            2_000,
            24 hours
        );

        ( ,,, uint48 postReconfigUpdateBlock, uint48 postReconfigIncreaseTime ) = capAutomator.borrowCapConfigs(asset);

        assertEq(postReconfigUpdateBlock,  postExecUpdateBlock);
        assertEq(postReconfigIncreaseTime, postExecIncreaseTime);
    }

}

contract RemoveSupplyCapConfigTests is CapAutomatorUnitTestBase {

    function test_removeSupplyCapConfig_noAuth() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")));
        capAutomator.removeSupplyCapConfig(asset);
    }

    function test_removeSupplyCapConfig_nonexistentConfig() public {
        vm.prank(owner);
        vm.expectRevert("CapAutomator/nonexistent-config");
        capAutomator.removeSupplyCapConfig(asset);
    }

    function test_removeSupplyCapConfig() public {
        vm.prank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        vm.roll(24);
        vm.warp(24 hours);

        capAutomator.execSupply(asset);

        (
            uint48 max,
            uint48 gap,
            uint48 increaseCooldown,
            uint48 lastUpdateBlock,
            uint48 lastIncreaseTime
        ) = capAutomator.supplyCapConfigs(asset);

        assertEq(max,              10_000);
        assertEq(gap,              1_000);
        assertEq(increaseCooldown, 12 hours);
        assertEq(lastUpdateBlock,  24);
        assertEq(lastIncreaseTime, 24 hours);

        vm.prank(owner);
        capAutomator.removeSupplyCapConfig(asset);

        (
            max,
            gap,
            increaseCooldown,
            lastUpdateBlock,
            lastIncreaseTime
        ) = capAutomator.supplyCapConfigs(asset);

        assertEq(max,              0);
        assertEq(gap,              0);
        assertEq(increaseCooldown, 0);
        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);
    }

}

contract RemoveBorrowCapConfigTests is CapAutomatorUnitTestBase {

    function test_removeBorrowCapConfig_noAuth() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, makeAddr("notOwner")));
        capAutomator.removeBorrowCapConfig(asset);
    }

    function test_removeBorrowCapConfig_nonexistentConfig() public {
        vm.prank(owner);
        vm.expectRevert("CapAutomator/nonexistent-config");
        capAutomator.removeBorrowCapConfig(asset);
    }

    function test_removeBorrowCapConfig() public {
        vm.prank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );

        vm.roll(36);
        vm.warp(36 hours);

        capAutomator.execBorrow(asset);

        (
            uint48 max,
            uint48 gap,
            uint48 increaseCooldown,
            uint48 lastUpdateBlock,
            uint48 lastIncreaseTime
        ) = capAutomator.borrowCapConfigs(asset);

        assertEq(max,              10_000);
        assertEq(gap,              1_000);
        assertEq(increaseCooldown, 12 hours);
        assertEq(lastUpdateBlock,  36);
        assertEq(lastIncreaseTime, 36 hours);

        vm.prank(owner);
        capAutomator.removeBorrowCapConfig(asset);

        (
            max,
            gap,
            increaseCooldown,
            lastUpdateBlock,
            lastIncreaseTime
        ) = capAutomator.borrowCapConfigs(asset);

        assertEq(max,              0);
        assertEq(gap,              0);
        assertEq(increaseCooldown, 0);
        assertEq(lastUpdateBlock,  0);
        assertEq(lastIncreaseTime, 0);
    }

}

contract CalculateNewCapTests is Test {

    MockPoolAddressesProvider public mockPoolAddressesProvider;
    MockPool                  public mockPool;
    MockPoolConfigurator      public mockPoolConfigurator;

    address public owner;

    CapAutomatorHarness public capAutomator;

    function setUp() public {
        owner = makeAddr("owner");

        mockPool                  = new MockPool();
        mockPoolConfigurator      = new MockPoolConfigurator(mockPool);
        mockPoolAddressesProvider = new MockPoolAddressesProvider(address(mockPool), address(mockPoolConfigurator));

        capAutomator = new CapAutomatorHarness(address(mockPoolAddressesProvider));
    }

    function test_calculateNewCap_raiseCap() public {
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  0,
                lastIncreaseTime: 0
            }),
            1_900,
            2_000
        );
        assertEq(newCap, 2_400);
    }

    function test_calculateNewCap_notConfigured() public {
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              0,
                gap:              0,
                increaseCooldown: 0,
                lastUpdateBlock:  0,
                lastIncreaseTime: 0
            }),
            1_900,
            2_000
        );
        assertEq(newCap, 2_000);
    }

    function test_calculateNewCap_sameBlock() public {
        vm.roll(250);
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  99,
                lastIncreaseTime: 0
            }),
            1_900,
            2_000
        );
        assertEq(newCap, 2_400);

        newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  250,
                lastIncreaseTime: 0
            }),
            1_900,
            2_000
        );
        assertEq(newCap, 2_000);
    }

    function test_calculateNewCap_sameCap() public {
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  0,
                lastIncreaseTime: 0
            }),
            1_500,
            2_000
        );
        assertEq(newCap, 2_000);
    }

    function test_calculateNewCap_closeToMax() public {
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  0,
                lastIncreaseTime: 0
            }),
            4_800,
            4_900
        );
        assertEq(newCap, 5_000);
    }

    function test_calculateNewCap_aboveMax() public {
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  0,
                lastIncreaseTime: 0
            }),
            4_800,
            5_200
        );
        assertEq(newCap, 5_000);
    }

    function test_calculateNewCap_cooldown() public {
        vm.warp(12 hours);
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 12 hours,
                lastUpdateBlock:  0,
                lastIncreaseTime: 12 hours
            }),
            1_900,
            2_000
        );
        assertEq(newCap, 2_000);

        newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 12 hours,
                lastUpdateBlock:  0,
                lastIncreaseTime: 12 hours
            }),
            1_200,
            2_000
        );
        assertEq(newCap, 1_700);

        vm.warp(24 hours);
        newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              5_000,
                gap:              500,
                increaseCooldown: 12 hours,
                lastUpdateBlock:  0,
                lastIncreaseTime: 12 hours
            }),
            1_900,
            2_000
        );
        assertEq(newCap, 2_400);
    }

    function test_calculateNewCap_belowState() public {
        uint256 newCap = capAutomator._calculateNewCapExternal(
            CapAutomator.CapConfig({
                max:              4_500,
                gap:              500,
                increaseCooldown: 0,
                lastUpdateBlock:  0,
                lastIncreaseTime: 0
            }),
            4_800,
            5_200
        );
        assertEq(newCap, 4_500);
    }

}

contract ExecSupplyTests is CapAutomatorUnitTestBase {

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    function test_execSupply() public {
        vm.roll(900);
        vm.warp(900_000);

        vm.prank(owner);
        capAutomator.setSupplyCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              500,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_000);

        ( ,,, uint48 lastUpdateBlockBefore, uint48 lastIncreaseTimeBefore ) = capAutomator.supplyCapConfigs(asset);
        assertEq(lastUpdateBlockBefore,  0);
        assertEq(lastIncreaseTimeBefore, 0);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setSupplyCap, (asset, uint256(7_400))), 1);
        assertEq(capAutomator.execSupply(asset), 7_400);
        // (scaledTotalSupply + accruedToTreasury) * liquidityIndex + gap = (5700 + 50) * 1.2 + 500 = 6900 + 500 = 7400

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_400);

        ( ,,, uint48 lastUpdateBlockAfter, uint48 lastIncreaseTimeAfter ) = capAutomator.supplyCapConfigs(asset);
        assertEq(lastUpdateBlockAfter,  900);
        assertEq(lastIncreaseTimeAfter, 900_000);
    }

    function test_execSupply_differentDecimals() public {
        vm.roll(300);
        vm.warp(300_000);

        mockPool.aToken().__setDecimals(6);
        mockPool.__setATokenScaledTotalSupply(4_500e6);
        mockPool.__setAccruedToTreasury(100e6);
        mockPool.__setLiquidityIndex(1.5e27);
        // (aToken. scaledTotalSupply + accruedToTreasury) * liquidityIndex = 6_900e6

        vm.prank(owner);
        capAutomator.setSupplyCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              500,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_000);

        ( ,,, uint48 lastUpdateBlockBefore, uint48 lastIncreaseTimeBefore ) = capAutomator.supplyCapConfigs(asset);
        assertEq(lastUpdateBlockBefore,  0);
        assertEq(lastIncreaseTimeBefore, 0);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setSupplyCap, (asset, uint256(7_400))), 1);
        assertEq(capAutomator.execSupply(asset), 7_400);
        // (scaledTotalSupply + accruedToTreasury) * liquidityIndex + gap = (5700 + 50) * 1.2 + 500 = 6900 + 500 = 7400

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_400);

        ( ,,, uint48 lastUpdateBlockAfter, uint48 lastIncreaseTimeAfter ) = capAutomator.supplyCapConfigs(asset);
        assertEq(lastUpdateBlockAfter,  300);
        assertEq(lastIncreaseTimeAfter, 300_000);
    }

    function test_execSupply_sameCap() public {
        vm.prank(owner);
        capAutomator.setSupplyCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              100,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_000);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setSupplyCap, (asset, uint256(7_000))), 0);
        assertEq(capAutomator.execSupply(asset), 7_000);
        // (scaledTotalSupply + accruedToTreasury) * liquidityIndex + gap = (5700 + 50) * 1.2 + 100 = 6900 + 100 = 7000

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_000);
    }

    function test_execSupply_belowState() public {
        vm.prank(owner);
        capAutomator.setSupplyCapConfig({
            asset:            asset,
            max:              2_000,
            gap:              100,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_000);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setSupplyCap, (asset, uint256(2_000))), 1);
        assertEq(capAutomator.execSupply(asset), 2_000);

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 2_000);
    }

}

contract ExecBorrowTests is CapAutomatorUnitTestBase {

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    function test_execBorrow() public {
        vm.roll(100);
        vm.warp(100_000);

        vm.prank(owner);
        capAutomator.setBorrowCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              500,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_000);

        ( ,,, uint48 lastUpdateBlockBefore, uint48 lastIncreaseTimeBefore ) = capAutomator.borrowCapConfigs(asset);
        assertEq(lastUpdateBlockBefore,  0);
        assertEq(lastIncreaseTimeBefore, 0);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setBorrowCap, (asset, uint256(4_400))), 1);
        assertEq(capAutomator.execBorrow(asset), 4_400);
        // totalDebt + gap = 3900 + 500 = 4400

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_400);

        ( ,,, uint48 lastUpdateBlockAfter, uint48 lastIncreaseTimeAfter ) = capAutomator.borrowCapConfigs(asset);
        assertEq(lastUpdateBlockAfter,  100);
        assertEq(lastIncreaseTimeAfter, 100_000);
    }

    function test_execBorrow_differentDecimals() public {
        vm.roll(200);
        vm.warp(200_000);

        mockPool.debtToken().__setDecimals(6);
        mockPool.__setTotalDebt(3_900e6);

        vm.prank(owner);
        capAutomator.setBorrowCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              500,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_000);

        ( ,,, uint48 lastUpdateBlockBefore, uint48 lastIncreaseTimeBefore ) = capAutomator.borrowCapConfigs(asset);
        assertEq(lastUpdateBlockBefore,  0);
        assertEq(lastIncreaseTimeBefore, 0);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setBorrowCap, (asset, uint256(4_400))), 1);
        assertEq(capAutomator.execBorrow(asset), 4_400);
        // totalDebt + gap = 3900 + 500 = 4400

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_400);

        ( ,,, uint48 lastUpdateBlockAfter, uint48 lastIncreaseTimeAfter ) = capAutomator.borrowCapConfigs(asset);
        assertEq(lastUpdateBlockAfter,  200);
        assertEq(lastIncreaseTimeAfter, 200_000);
    }

    function test_execBorrow_sameCap() public {
        vm.prank(owner);
        capAutomator.setBorrowCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              100,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_000);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setBorrowCap, (asset, uint256(4_000))), 0);
        assertEq(capAutomator.execBorrow(asset), 4_000);
        // totalDebt + gap = 3900 + 100 = 4000

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_000);
    }

    function test_execBorrow_belowState() public {
        vm.prank(owner);
        capAutomator.setBorrowCapConfig({
            asset:            asset,
            max:              1_000,
            gap:              100,
            increaseCooldown: 0
        });

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_000);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setBorrowCap, (asset, uint256(1_000))), 1);
        assertEq(capAutomator.execBorrow(asset), 1_000);

        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 1_000);
    }

}

contract ExecTests is CapAutomatorUnitTestBase {

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    function test_exec() public {
        mockPool.__setSupplyCap(7_000);
        mockPool.__setBorrowCap(4_000);

        vm.roll(500);
        vm.warp(500_000);

        vm.startPrank(owner);
        capAutomator.setSupplyCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              400,
            increaseCooldown: 0
        });
        capAutomator.setBorrowCapConfig({
            asset:            asset,
            max:              8_000,
            gap:              300,
            increaseCooldown: 0
        });
        vm.stopPrank();

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_000);
        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_000);

        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setSupplyCap, (asset, uint256(7_300))), 1);
        // (scaledTotalSupply + accruedToTreasury) * liquidityIndex + gap = (5700 + 50) * 1.2 + 400 = 6900 + 400 = 7300
        vm.expectCall(address(mockPoolConfigurator), abi.encodeCall(IPoolConfigurator.setBorrowCap, (asset, uint256(4_200))), 1);
        // totalDebt + gap = 3900 + 300 = 4200

        ( uint256 newSupplyCap, uint256 newBorrowCap ) = capAutomator.exec(asset);

        assertEq(newSupplyCap, 7_300);
        assertEq(newBorrowCap, 4_200);

        assertEq(mockPool.getReserveData(asset).configuration.getSupplyCap(), 7_300);
        assertEq(mockPool.getReserveData(asset).configuration.getBorrowCap(), 4_200);
    }

}

contract EventTests is CapAutomatorUnitTestBase {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    event SetSupplyCapConfig(address indexed asset, uint256 max, uint256 gap, uint256 increaseCooldown);
    event SetBorrowCapConfig(address indexed asset, uint256 max, uint256 gap, uint256 increaseCooldown);

    event RemoveSupplyCapConfig(address indexed asset);
    event RemoveBorrowCapConfig(address indexed asset);

    event UpdateSupplyCap(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);
    event UpdateBorrowCap(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

    function test_OwnershipTransferred() public {
        address newOwner = makeAddr("newOwner");
        vm.prank(owner);
        vm.expectEmit(address(capAutomator));
        emit OwnershipTransferred(owner, newOwner);
        capAutomator.transferOwnership(newOwner);
    }

    function test_SetSupplyCapConfig() public {
        vm.prank(owner);
        vm.expectEmit(address(capAutomator));
        emit SetSupplyCapConfig(
            asset,
            20_000,
            2_000,
            24 hours
        );
        capAutomator.setSupplyCapConfig(
            asset,
            20_000,
            2_000,
            24 hours
        );
    }

    function test_SetBorrowCapConfig() public {
        vm.prank(owner);
        vm.expectEmit(address(capAutomator));
        emit SetBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );
    }

    function test_RemoveSupplyCapConfig() public {
        vm.startPrank(owner);
        capAutomator.setSupplyCapConfig(
            asset,
            20_000,
            2_000,
            24 hours
        );
        vm.expectEmit(address(capAutomator));
        emit RemoveSupplyCapConfig(asset);
        capAutomator.removeSupplyCapConfig(asset);
        vm.stopPrank();
    }

    function test_RemoveBorrowCapConfig() public {
        vm.startPrank(owner);
        capAutomator.setBorrowCapConfig(
            asset,
            10_000,
            1_000,
            12 hours
        );
        vm.expectEmit(address(capAutomator));
        emit RemoveBorrowCapConfig(asset);
        capAutomator.removeBorrowCapConfig(asset);
        vm.stopPrank();
    }

    function test_UpdateSupplyCap() public {
        vm.prank(owner);
        capAutomator.setSupplyCapConfig({
            asset:            asset,
            max:              10_000,
            gap:              400,
            increaseCooldown: 0
        });

        vm.expectEmit(address(capAutomator));
        emit UpdateSupplyCap(asset, 7_000, 7_300);
        // (scaledTotalSupply + accruedToTreasury) * liquidityIndex + gap = (5700 + 50) * 1.2 + 400 = 6900 + 400 = 7300
        capAutomator.exec(asset);
    }

    function test_UpdateBorrowCap() public {
        vm.prank(owner);
        capAutomator.setBorrowCapConfig({
            asset:            asset,
            max:              8_000,
            gap:              300,
            increaseCooldown: 0
        });

        vm.expectEmit(address(capAutomator));
        emit UpdateBorrowCap(asset, 4_000, 4_200);
        // totalDebt + gap = 3900 + 300 = 4200
        capAutomator.exec(asset);
    }

}
