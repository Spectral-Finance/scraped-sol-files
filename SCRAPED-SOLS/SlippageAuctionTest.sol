// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import "./BaseTest.sol";
import { SigUtils } from "./utils/SigUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FxbFactoryFunctions } from "./FXBFactoryTest.sol";

contract SlippageAuctionTest is BaseTest, FxbFactoryFunctions {
    // Auction related

    FXB bond;
    address bondAddress;

    SlippageAuction auction;
    address auctionAddress;

    FXB fxb0;
    address fxb0Address;

    function setUp() public {
        defaultSetup();

        // BACKGROUND: deploy one bond
        (bond, bondAddress) = _fxbFactory_createBond(block.timestamp + 75 days);

        // BACKGROUND: deploy one auction
        auctionAddress = auctionFactory.createAuction({ _buyToken: address(frax), _sellToken: bondAddress });
        auction = SlippageAuction(auctionAddress);

        // Give the tester some FXS
        hoax(Constants.Mainnet.FXS_WHALE);
        fxs.transfer(tester, 10_000e18);

        // Give the tester some USDC
        hoax(Constants.Mainnet.USDC_WHALE);
        usdc.transfer(tester, 10_000e6);
    }

    function startGenericAuction() public {
        // Approve FRAX to the bond contract
        // hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        // frax.approve(fxb0Address, 1000e18);
        // Mint FXB0 to the mint redeemer AMO
        // hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        // fxb0.mint(auctioneerAmoAddress, 1000e18);
        // Initiate an auction
        // hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        // address _auctionAddress = auctioneerAmo.createFXBAuction(address(frax), fxb0Address);
        // hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        // genericAuctionNo = auctioneerAmo.auctionFXB(
        //     _auctionAddress,
        //     SlippageAuction.StartAuctionParams({
        //         sellAmount: 1000e18,
        //         startPrice: 0.95e18,
        //         minPrice: 0.85e18,
        //         priceDecay: 0.01e18,
        //         priceSlippage: 0.000025e18,
        //         expiry: uint32(block.timestamp + (30 days))
        //     })
        // );
    }

    function test_StartAuction() public {
        /// GIVEN: an auction has been deployed by tester
        /// WHEN: tester starts the auction with properly formed params
        /// THEN: auction should be started
        /// Then: the parameters should be set correctly
    }

    function test_CannotStartAuctionWhenAnotherIsLive() public {
        /// : an auction has been deployed by tester
        /// GIVEN:
        /// WHEN: tester tries to start another auction
        /// THEN: we expect the function to revert with AuctionAlreadyExists()
    }

    function testCreateE6Auction() public {
        // slippageAuctionSetup();
        // // Become the tester
        // vm.startPrank(tester);
        // // Approve tokens to the auction contract
        // fxs.approve(auctionAddress, 1000e18);
        // usdc.approve(auctionAddress, 1000e6);
        // // Try to create an auction with a non-E18 buyToken (should fail)
        // // vm.expectRevert(abi.encodeWithSelector(SlippageAuctionFactory.BuyTokenMustBe18Decimals.selector));
        // // address _auctionAddress = auctioneerAmo.createFXBAuction(address(usdc), fxb0Address);
        // // Try to create an auction with a non-E18 sellToken (should fail)
        // vm.expectRevert(abi.encodeWithSignature("SellTokenMustBe18Decimals()"));
        // auctionFactory.createAuction({ _buyToken: address(fxs), _sellToken: address(usdc) });
        // vm.stopPrank();
    }

    function testBuyFromAuctionBasic() public {
        // slippageAuctionSetup();
        // startGenericAuction();
        // // Become the bonduser
        // vm.startPrank(bonduser);
        // // Approve FRAX to the auction contract
        // frax.approve(auctionAddress, 200_000e18);
        // // Buy some FXB0
        // uint256 fxb0_before = fxb0.balanceOf(bonduser);
        // auction.buy(1e18, 0);
        // uint256 fxb0_after = fxb0.balanceOf(bonduser);
        // console.log("FXB0 Change: ", fxb0_after - fxb0_before);
        // // Try buying half of the auction (should work)
        // auction.buy(525e18, 0);
        // // Try putting too much minOut (should fail)
        // vm.expectRevert(abi.encodeWithSignature("MinAmountOut(uint256,uint128)", 10_000e18, 1_024_249_097_380_482_933));
        // auction.buy(1e18, 10_000e18);
        // // Try to buy too many bonds
        // vm.expectRevert(abi.encodeWithSignature("NotEnoughLeftInAuction()"));
        // auction.buy(100_000e18, 0);
        // // Wait until after the auction ends
        // mineBlocksBySecond(35 days);
        // // Try to buy after expiry
        // vm.expectRevert(abi.encodeWithSignature("AuctionExpired()"));
        // auction.buy(1e18, 0);
    }

    function testBuyFromAuctionDetailed() public {
        // slippageAuctionSetup();
        // startGenericAuction();
        // // Become the bonduser
        // vm.startPrank(bonduser);
        // // Approve FRAX to the auction contract
        // frax.approve(auctionAddress, 250_000e18);
        // // Fetch auction info
        // SlippageAuction.Auction memory _thisAuction = auction.getAuctionStruct(0);
        // // Buy some FXB0 at Day 0
        // uint256 fxb0_before_d0 = fxb0.balanceOf(bonduser);
        // auction.buy(1e18, 0);
        // uint256 fxb0_after_d0 = fxb0.balanceOf(bonduser);
        // // Fetch auction info (again)
        // _thisAuction = auction.getAuctionStruct(0);
        // // Exec price should have been lastPrice - (decay per day * # days) + slippage
        // assertApproxEqRel(
        //     uint256(fxb0_after_d0 - fxb0_before_d0),
        //     uint256(1e18 * 1e18) / uint256(0.95e18 + 0.000025e18),
        //     0.0025e18
        // );
        // // Wait 3 days
        // mineBlocksBySecond(3 days);
        // // Fetch auction info (again)
        // _thisAuction = auction.getAuctionStruct(0);
        // // Buy some FXB0 at Day 3
        // uint256 fxb0_before_d1 = fxb0.balanceOf(bonduser);
        // auction.buy(1e18, 0);
        // uint256 fxb0_after_d1 = fxb0.balanceOf(bonduser);
        // // Exec price should have been lastPrice - (decay per day * # days) + slippage
        // assertApproxEqRel(
        //     uint256(fxb0_after_d1 - fxb0_before_d1),
        //     uint256(1e18 * 1e18) / uint256(0.952e18 - 0.03e18 + 0.000025e18),
        //     0.0025e18
        // );
        // // Wait 10 more days. Should be at min price now
        // mineBlocksBySecond(10 days);
        // // Buy some FXB0 at Day 13
        // uint256 fxb0_before_d3 = fxb0.balanceOf(bonduser);
        // auction.buy(1e18, 0);
        // uint256 fxb0_after_d3 = fxb0.balanceOf(bonduser);
        // // Exec price should be minPrice + slippage
        // assertApproxEqRel(
        //     uint256(fxb0_after_d3 - fxb0_before_d3),
        //     uint256(1e18 * 1e18) / uint256(0.85e18 + 0.000025e18),
        //     0.0025e18
        // );
        // // Try to buy a huge amount of bonds (should fail)
        // vm.expectRevert(abi.encodeWithSignature("NotEnoughLeftInAuction()"));
        // auction.buy(100_000e18, 0);
        // // Buy a modest amount of bonds
        // auction.buy(500e18, 0);
        // // Stop being the bond user
        // vm.stopPrank();
        // // Become the timelock
        // vm.startPrank(Constants.Mainnet.TIMELOCK_ADDRESS);
        // // Timelock ends the auction
        // uint256 frax_before_mntrdmr = frax.balanceOf(auctioneerAmoAddress);
        // uint256 fxb0_before_mntrdmr = fxb0.balanceOf(auctioneerAmoAddress);
        // auctioneerAmo.exitAuction(genericAuctionNo);
        // uint256 frax_after_mntrdmr = frax.balanceOf(auctioneerAmoAddress);
        // uint256 fxb0_after_mntrdmr = fxb0.balanceOf(auctioneerAmoAddress);
        // // Fetch auction info again
        // _thisAuction = auction.getAuctionStruct(0);
        // // Make sure the proper proceeds were collected
        // assertApproxEqRel(uint256(frax_after_mntrdmr - frax_before_mntrdmr), _thisAuction.buyTokenProceeds, 0);
        // assertApproxEqRel(uint256(fxb0_after_mntrdmr - fxb0_before_mntrdmr), _thisAuction.amountLeft, 0);
        // // Stop being the timelock
        // vm.stopPrank();
        // // Try to buy after expiry
        // hoax(bonduser);
        // vm.expectRevert(abi.encodeWithSignature("AuctionAlreadyExited()"));
        // auction.buy(1e18, 0);
    }

    function testGetAmountOutNormal() public {
        // slippageAuctionSetup();
        // startGenericAuction();
        // // Become the bonduser
        // vm.startPrank(bonduser);
        // // Call getAmountOut
        // (
        //     SlippageAuction.Auction memory _thisAuction,
        //     uint128 _price,
        //     uint128 _slippagePerSellTkn,
        //     uint128 _amountOut
        // ) = auction.getAmountOut( 100e18, false);
        // // Check _slippagePerSellTkn
        // assertEq(_slippagePerSellTkn, 0.0025e18);
        // // Check price
        // assertEq(_price, 0.95e18);
        // // Check _amountOut
        // assertApproxEqRel(
        //     uint256(_amountOut),
        //     uint256(100e18 * 1e18) / uint256(0.95e18 + ((100e18 * 0.000025e18) / 1e18)),
        //     0.0025e18
        // );
    }

    function testGetAmountOutOverAmountLeft() public {
        // slippageAuctionSetup();
        // startGenericAuction();
        // // Become the bonduser
        // vm.startPrank(bonduser);
        // // Call getAmountOut and get the revert
        // vm.expectRevert(abi.encodeWithSignature("NotEnoughLeftInAuction()"));
        // auction.getAmountOut(100_000e18, true);
        // // Call getAmountOut without the revert. amountOut should be amountLeft
        // (
        //     SlippageAuction.Auction memory _thisAuction,
        //     uint128 _price,
        //     uint128 _slippagePerSellTkn,
        //     uint128 _amountOut
        // ) = auction.getAmountOut(100_000e18, false);
        // // Check _slippagePerSellTkn
        // assertEq(_slippagePerSellTkn, 2.5e18);
        // // Check price
        // assertEq(_price, 0.95e18);
        // // Check _amountOut. Should be amountLeft
        // assertApproxEqRel(uint256(_amountOut), uint256(1000e18), 0.0025e18);
    }

    function testGetAmountIn() public {
        // slippageAuctionSetup();
        // startGenericAuction();
        // // Become the bonduser
        // vm.startPrank(bonduser);
        // // Fetch auction info
        // SlippageAuction.Auction memory _thisAuction = auction.getAuctionStruct(0);
        // // Call getAmountIn
        // (uint256 _amountIn, uint256 _amountOut) = auction.getAmountIn(100e18);
        // // Fetch auction info (again)
        // _thisAuction = auction.getAuctionStruct(0);
        // // Check _amountOut. Should be 100e18
        // assertEq(_amountOut, 100e18);
        // // Check price. Exec price should have been lastPrice - (decay per day * # days) + slippage
        // assertApproxEqRel((_amountIn * 1e18) / _amountOut, 0.95e18 + ((_amountIn * 0.000025e18) / 1e18), 0.0025e18);
        // // Wait 35 days. Auction should have expired now
        // mineBlocksBySecond(35 days);
        // // Try getAmountIn (should fail)
        // vm.expectRevert(abi.encodeWithSignature("AuctionExpired()"));
        // auction.getAmountIn(100e18);
        // // Become the timelock
        // vm.stopPrank();
        // vm.startPrank(Constants.Mainnet.TIMELOCK_ADDRESS);
        // // Timelock ends the auction
        // auctioneerAmo.exitAuction(genericAuctionNo);
        // // Try getAmountIn (should fail again, but differently)
        // vm.expectRevert(abi.encodeWithSignature("AuctionAlreadyExited()"));
        // auction.getAmountIn(100e18);
    }

    function testGetAmountInMax() public {
        // slippageAuctionSetup();
        // startGenericAuction();
        // // Become the bonduser
        // vm.startPrank(bonduser);
        // // Fetch auction info
        // SlippageAuction.Auction memory _thisAuction = auction.getAuctionStruct(0);
        // // Call getAmountInMax
        // (uint256 _amountIn, uint256 _amountOut) = auction.getAmountInMax();
        // // Fetch auction info (again)
        // _thisAuction = auction.getAuctionStruct(0);
        // // Check _amountOut. Should be the 1000e18 available in the auction
        // assertEq(_amountOut, 1000e18);
        // // Check price. Exec price should have been lastPrice - (decay per day * # days) + slippage
        // assertApproxEqRel((_amountIn * 1e18) / _amountOut, 0.95e18 + ((_amountIn * 0.000025e18) / 1e18), 0.0025e18);
        // // Wait 35 days. Auction should have expired now
        // mineBlocksBySecond(35 days);
        // // Try getAmountIn (should fail)
        // vm.expectRevert(abi.encodeWithSignature("AuctionExpired()"));
        // auction.getAmountInMax();
        // // Become the timelock
        // vm.stopPrank();
        // vm.startPrank(Constants.Mainnet.TIMELOCK_ADDRESS);
        // // Timelock ends the auction
        // auctioneerAmo.exitAuction(genericAuctionNo);
        // // Try getAmountIn (should fail again, but differently)
        // vm.expectRevert(abi.encodeWithSignature("AuctionAlreadyExited()"));
        // auction.getAmountInMax();
    }
}
