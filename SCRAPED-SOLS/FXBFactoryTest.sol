// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./BaseTest.sol";
import { SigUtils } from "./utils/SigUtils.sol";

abstract contract FxbFactoryFunctions is BaseTest {
    function _fxbFactory_createBond(uint256 _maturityTimestamp) public returns (FXB _fxb, address _fxbAddress) {
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        (_fxbAddress, ) = factory.createBond(_maturityTimestamp);
        _fxb = FXB(_fxbAddress);
    }
}

contract FXBFactoryTest is BaseTest, FxbFactoryFunctions {
    function setUp() public {
        /// BACKGROUND: Contracts are deployed
        defaultSetup();
    }

    function test_AllBondsLength() public {
        // Make sure there are 2 bonds
        /// GIVEN: There are 2 bonds deployed
        _fxbFactory_createBond(block.timestamp + 75 days);
        _fxbFactory_createBond(block.timestamp + 99 days);

        /// WHEN: we check the length of allBonds
        /// THEN: we expect the length to be 2
        assertEq(factory.allBondsLength(), 2, "There should be 2 bonds");
    }

    function test_CreateBond() public {
        // Create bonds with various dates
        /// WHEN: we create bonds with various dates
        _fxbFactory_createBond(block.timestamp + 30 days);
        _fxbFactory_createBond(block.timestamp + 75 days);
        _fxbFactory_createBond(block.timestamp + 99 days);
        _fxbFactory_createBond(block.timestamp + 141 days);
        _fxbFactory_createBond(block.timestamp + 150 days);
        _fxbFactory_createBond(block.timestamp + 180 days);
        _fxbFactory_createBond(block.timestamp + 237 days);
        _fxbFactory_createBond(block.timestamp + 240 days);
        _fxbFactory_createBond(block.timestamp + 270 days);
        _fxbFactory_createBond(block.timestamp + 325 days);
        _fxbFactory_createBond(block.timestamp + 336 days);
        _fxbFactory_createBond(block.timestamp + 360 days);

        /// THEN: there is no revert
    }

    function test_CannotCreateDuplicateMaturity() public {
        /// GIVEN: a bond with a maturity of 90 days is created
        _fxbFactory_createBond(block.timestamp + 90 days);

        /// WHEN: we try to create a bond with a maturity of 90 days
        startHoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        vm.expectRevert(FXBFactory.BondMaturityAlreadyExists.selector);
        factory.createBond(block.timestamp + 90 days);
        vm.stopPrank();

        /// THEN: we expect the function to revert with BondMaturityAlreadyExists()
    }
}
