// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./BaseTest.sol";
import { FxbFactoryFunctions } from "./FXBFactoryTest.sol";

abstract contract SlippageAuctionFactoryFunctions is BaseTest {
    function _slippageAuctionFactory_createAuction(
        address _buyToken,
        address _sellToken
    ) public returns (SlippageAuction _slippageAuction, address _auctionAddress) {
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        _auctionAddress = auctionFactory.createAuction(_buyToken, _sellToken);
        _slippageAuction = SlippageAuction(_auctionAddress);
    }
}

contract SlippageAuctionFactoryTest is BaseTest, SlippageAuctionFactoryFunctions, FxbFactoryFunctions {
    function test_CanCreateAuction() public {
        /// BACKGROUND: Contracts are deployed
        defaultSetup();

        uint256 _initialAuctionLength = auctionFactory.auctionsLength();

        /// WHEN: a user tries to create an auction with 2 x 18 decimal tokens
        (SlippageAuction _auction, address _newAuctionAddress) = _slippageAuctionFactory_createAuction(
            address(frax),
            address(fxs)
        );

        /// THEN: the length of auctions should increase by 1
        assertEq(auctionFactory.auctionsLength() - _initialAuctionLength, 1, "Auctions length should increase by 1");

        /// THEN: the last address in the auctions array should be the address of the auction
        assertEq(
            auctionFactory.auctions(auctionFactory.auctionsLength() - 1),
            _newAuctionAddress,
            "Auction address should be the last address in the auctions array"
        );

        /// THEN: the AuctionCreated event should be emitted

        /// THEN: the auction should be created with matching parameters (buyToken, sellToken, timelockAddress)
        assertEq(_auction.BUY_TOKEN(), address(frax), "Buy token should be FRAX");
        assertEq(_auction.SELL_TOKEN(), address(fxs), "Sell token should be FXS");
        assertEq(
            _auction.timelockAddress(),
            Constants.Mainnet.TIMELOCK_ADDRESS,
            "Timelock address should be the timelock address"
        );
    }

    function test_CannotCreateAuctionWithNon18Decimals() public {
        /// BACKGROUND: Deploy the contracts
        defaultSetup();

        /// WHEN: a user tries to create an auction with a non 18 decimal BUY token
        vm.expectRevert(SlippageAuctionFactory.BuyTokenMustBe18Decimals.selector);
        auctionFactory.createAuction(address(usdc), address(frax));
        /// THEN: we expect the function to revert

        /// WHEN: a user tries to create an auction with a non 18 decimal SELL token
        vm.expectRevert(SlippageAuctionFactory.SellTokenMustBe18Decimals.selector);
        auctionFactory.createAuction(address(frax), address(usdc));
        /// THEN: we expect the function to revert
    }

    function test_CannotCreateSameAuctionTwiceWithSameSender() public {
        /// BACKGROUND: Deploy the contracts
        defaultSetup();

        vm.startPrank(address(1234));
        /// WHEN: a user tries to create an auction with the same parameters twice
        auctionFactory.createAuction(address(frax), address(fxs));

        vm.expectRevert(SlippageAuctionFactory.AuctionAlreadyExists.selector);
        auctionFactory.createAuction(address(frax), address(fxs));
        vm.stopPrank();
        /// THEN: we expect the function to revert on the second pass with AuctionAlreadyExists()
    }

    function test_GetAuctions() public {
        /// BACKGROUND: Deploy the contracts
        defaultSetup();

        /// GIVEN: 3 auctions have been created
        (, address _fxb0) = _fxbFactory_createBond(block.timestamp + 30 days);
        (, address _auction1) = _slippageAuctionFactory_createAuction(address(frax), address(_fxb0));
        (, address _fxb1) = _fxbFactory_createBond(block.timestamp + 60 days);
        (, address _auction2) = _slippageAuctionFactory_createAuction(address(frax), address(_fxb1));
        (, address _fxb2) = _fxbFactory_createBond(block.timestamp + 90 days);
        (, address _auction3) = _slippageAuctionFactory_createAuction(address(fxs), address(_fxb2));

        /// WHEN: a user calls getAuctions()
        address[] memory _auctions = auctionFactory.getAuctions();

        /// THEN: we expect the array to contain the addresses of the 3 auctions
        assertEq(_auctions[0], _auction1, "First auction should be the first auction");
        assertEq(_auctions[1], _auction2, "Second auction should be the second auction");
        assertEq(_auctions[2], _auction3, "Third auction should be the third auction");
    }

    function test_AuctionsLength() public {
        /// BACKGROUND: Deploy the contracts
        defaultSetup();

        /// GIVEN: 3 auctions have been created
        (, address _fxb0) = _fxbFactory_createBond(block.timestamp + 30 days);
        _slippageAuctionFactory_createAuction(address(frax), address(_fxb0));
        (, address _fxb1) = _fxbFactory_createBond(block.timestamp + 60 days);
        _slippageAuctionFactory_createAuction(address(frax), address(_fxb1));
        (, address _fxb2) = _fxbFactory_createBond(block.timestamp + 90 days);
        _slippageAuctionFactory_createAuction(address(fxs), address(_fxb2));

        /// WHEN: a user calls auctionsLength()
        uint256 _auctionsLength = auctionFactory.auctionsLength();

        /// THEN: we expect the function to return 3
        assertEq(_auctionsLength, 3, "Auctions length should be 3");
    }
}
