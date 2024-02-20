// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import "./BaseTest.sol";
import { FxbFactoryFunctions } from "./FXBFactoryTest.sol";

contract FXBTest is BaseTest, FxbFactoryFunctions {
    FXB fxb0;
    address fxb0Address;

    function setUp() public {
        /// BACKGROUND: Contracts are deployed
        defaultSetup();

        /// BACKGROUND: a bond is created with now + 90 days maturity
        (fxb0, fxb0Address) = _fxbFactory_createBond(block.timestamp + 90 days);
    }

    function testMint() public {
        /// GIVEN: a user has not approved FRAX
        /// WHEN: a user tries to mint a bond
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        fxb0.mint(tester, 1e18);
        /// THEN: we expect the function to revert with ERC20: transfer amount exceeds allowance

        // GIVEN: a user has approved FRAX
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        frax.approve(fxb0Address, 2e18);

        // WHEN: a user tries to mint a bond with 1e18 FRAX
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        fxb0.mint(tester, 1e18);

        // THEN: we expect the user to have 1e18 FXB0

        /// GIVEN: 6 months have passed (and we are passed maturity)
        mineBlocksBySecond(6 * (30 days));

        /// WHEN: a user tries to mint a bond with 1e18 FRAX
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        fxb0.mint(tester, 1e18);

        /// THEN: we expect the user to have 1e18 FXB0
    }

    function testRedeem() public {
        // Set the redeem amount
        uint256 redeem_amt = 100e18;

        // Get some FXB0 first
        // =================================
        /// GIVEN: Approve FRAX to the bond contract (as the operator)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        frax.approve(fxb0Address, redeem_amt);

        /// GIVEN: Operator has minted the FXB0 to the bonduser
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        fxb0.mint(bonduser, redeem_amt);

        // Now go through the redeem flow
        // =================================
        // Switch to the bonduser
        vm.startPrank(bonduser);

        /// GIVEN: the maturity date has not passed
        // WHEN: the user tries to redeem
        vm.expectRevert(FXB.BondNotRedeemable.selector);
        fxb0.burn(bonduser, redeem_amt);
        /// THEN: we expect the function to revert with BondNotRedeemable()

        // GIVEN: 6 months have passed (and we are passed maturity)
        mineBlocksBySecond(6 * (30 days));

        // GIVEN: isBondRedeemable returns true
        assertEq(fxb0.isRedeemable(), true, "Make sure the bond is redeemable");

        // WHEN: the user tries to redeem their full balance
        uint256 frax_before = frax.balanceOf(bonduser);
        fxb0.burn(bonduser, redeem_amt);

        /// THEN: we expect the user to have 0 FXB0
        assertEq(fxb0.balanceOf(bonduser), 0, "bonduser should have 0 FXB0 after redeeming");

        /// THEN: we expect the user to have gained 100 FRAX
        assertEq(
            frax.balanceOf(bonduser) - frax_before,
            100e18,
            "bonduser should have gained 100 FRAX after redeeming"
        );
    }

    function testBondInfoNameVersionMaturity() public {
        /// GIVEN: Get the bond name
        string memory symbol = fxb0.symbol();

        /// GIVEN: Get the bond symbol
        string memory name = fxb0.name();

        /// GIVEN: Get the bond maturity
        uint256 maturity = fxb0.MATURITY_TIMESTAMP();

        /// WHEN: we get the bond info struct
        FXB.BondInfo memory bondInfo = fxb0.bondInfo();

        /// THEN: we expect the bond info struct to match the name, symbol, and maturity
        assertEq(symbol, bondInfo.symbol, "symbol() doesn't match that in the BondInfo struct");
        assertEq(name, bondInfo.name, "name() doesn't match that in the BondInfo struct");
        assertEq(maturity, bondInfo.maturityTimestamp, "maturityTimestamp() doesn't match that in the BondInfo struct");
    }
}
