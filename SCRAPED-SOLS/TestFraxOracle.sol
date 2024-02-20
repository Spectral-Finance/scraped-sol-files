// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import "frax-std/FraxTest.sol";
import { FraxOracle } from "src/frax-oracle/abstracts/FraxOracle.sol";
import "../../helpers/General.sol";
import { IFraxOracle } from "src/frax-oracle/interfaces/IFraxOracle.sol";
import { IPriceSource } from "src/frax-oracle/interfaces/IPriceSource.sol";
import { IPriceSourceReceiver } from "src/frax-oracle/interfaces/IPriceSourceReceiver.sol";

abstract contract TestFraxOracle is TestHelper {
    address public priceSourceAddress;
    IPriceSource public priceSource;

    address public fraxOracleAddress;
    IFraxOracle public fraxOracle;

    uint256 blockNumber = 17_571_401;

    function _selectTimelockAddress() internal returns (address) {
        if (block.chainid == 1) {
            return Constants.Mainnet.TIMELOCK_ADDRESS;
        } else if (block.chainid == 42_161) {
            return Constants.Arbitrum.TIMELOCK_ADDRESS;
        } else {
            revert("Add current chainid / timelock address");
        }
    }

    //==============================================================================
    // maximumOracleDelay tests
    //==============================================================================

    function testSetMaximumOracleDelay() public {
        uint256 newDelay = 100;
        startHoax(_selectTimelockAddress());
        fraxOracle.setMaximumOracleDelay(newDelay);
        vm.stopPrank();
        assertEq(fraxOracle.maximumOracleDelay(), newDelay, "New delay should be set");
    }

    function testSameMaximumOracleDelayRevertsSameValue() public {
        uint256 originalDelay = fraxOracle.maximumOracleDelay();
        startHoax(_selectTimelockAddress());
        vm.expectRevert(FraxOracle.SameMaximumOracleDelay.selector);
        fraxOracle.setMaximumOracleDelay(originalDelay);
        vm.stopPrank();
    }

    function testSetMaximumOracleDelayNotTimelockRevert() public {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        fraxOracle.setMaximumOracleDelay(100);
    }

    // priceSource tests
    function testSetPriceSource() public {
        address newPriceSource = address(0xb0b);
        startHoax(_selectTimelockAddress());
        fraxOracle.setPriceSource(newPriceSource);
        vm.stopPrank();
        assertEq(fraxOracle.priceSource(), newPriceSource, "New price source should be set");
    }

    function testSamePriceSourceRevertsSameValue() public {
        address originalPriceSource = fraxOracle.priceSource();
        startHoax(_selectTimelockAddress());
        vm.expectRevert(FraxOracle.SamePriceSource.selector);
        fraxOracle.setPriceSource(originalPriceSource);
        vm.stopPrank();
    }

    function testSetPriceSourceNotTimelockRevert() public {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        fraxOracle.setPriceSource(address(0xb0b));
    }

    //==============================================================================
    // maximumDeviation tests
    //==============================================================================

    function testSetMaximumDeviation() public {
        uint256 newDeviation = 100;
        startHoax(_selectTimelockAddress());
        fraxOracle.setMaximumDeviation(newDeviation);
        vm.stopPrank();
        assertEq(fraxOracle.maximumDeviation(), newDeviation, "New deviation should be set");
    }

    function testSameMaximumDeviationRevertsSameValue() public {
        uint256 originalDeviation = fraxOracle.maximumDeviation();
        startHoax(_selectTimelockAddress());
        vm.expectRevert(FraxOracle.SameMaximumDeviation.selector);
        fraxOracle.setMaximumDeviation(originalDeviation);
        vm.stopPrank();
    }

    function testSetMaximumDeviationNotTimelockRevert() public {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        fraxOracle.setMaximumDeviation(100);
    }

    //==============================================================================
    // addRoundData tests
    //==============================================================================
    function testAddRoundData() public {
        priceSource.addRoundData(IPriceSourceReceiver(fraxOracleAddress));
    }

    function testAddRoundDataLastRoundIdUpdated() public virtual {
        uint256 initialTimestamp = block.timestamp;
        vm.startPrank(priceSourceAddress);
        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.971e18,
            _priceHigh: 1e18,
            _timestamp: uint40(initialTimestamp)
        });

        assertEq(fraxOracle.lastCorrectRoundId(), 0, "Last round id set to 0, within deviation");
        uint256 priceLow0;
        uint256 priceHigh0;
        {
            bool isBadData0;
            (isBadData0, priceLow0, priceHigh0) = fraxOracle.getPrices();
            assertFalse(isBadData0);
        }
        vm.warp(initialTimestamp + 1);

        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.99e18,
            _priceHigh: 1e18,
            _timestamp: uint40(block.timestamp)
        });

        vm.stopPrank();

        uint256 priceLow1;
        uint256 priceHigh1;
        {
            bool isBadData1;
            (isBadData1, priceLow1, priceHigh1) = fraxOracle.getPrices();
            assertFalse(isBadData1);
        }

        assertEq(fraxOracle.lastCorrectRoundId(), 1, "Last round id set to 1, within deviation");

        int256 answer0;
        {
            uint80 roundId0;
            uint256 startedAt0;
            uint256 updatedAt0;
            uint80 answeredInRound0;
            (roundId0, answer0, startedAt0, updatedAt0, answeredInRound0) = fraxOracle.getRoundData(0);
            assertEq(0, roundId0);
            assertEq(roundId0, answeredInRound0);
            assertEq(initialTimestamp, startedAt0);
            assertEq(startedAt0, updatedAt0);
            assertGt(priceHigh0, uint256(answer0));
            assertLt(priceLow0, uint256(answer0));
        }

        int256 answer1;
        {
            uint80 roundId1;
            uint256 startedAt1;
            uint256 updatedAt1;
            uint80 answeredInRound1;
            (roundId1, answer1, startedAt1, updatedAt1, answeredInRound1) = fraxOracle.getRoundData(1);
            assertEq(1, roundId1);
            assertEq(roundId1, answeredInRound1);
            assertEq(initialTimestamp + 1, startedAt1);
            assertEq(startedAt1, updatedAt1);
            assertGt(priceHigh1, uint256(answer1));
            assertLt(priceLow1, uint256(answer1));
        }
        assertGt(answer1, answer0);
        (, int256 answerLatest, , , ) = fraxOracle.latestRoundData();
        assertEq(answerLatest, answer1);
    }

    function testAddRoundDataLastRoundIdNotUpdated() public virtual {
        uint256 initialTimestamp = block.timestamp;
        vm.startPrank(priceSourceAddress);
        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.971e18,
            _priceHigh: 1e18,
            _timestamp: uint40(initialTimestamp)
        });

        assertEq(fraxOracle.lastCorrectRoundId(), 0, "Last round id set to 0, within deviation");

        vm.warp(initialTimestamp + 1);

        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.969e18,
            _priceHigh: 1e18,
            _timestamp: uint40(initialTimestamp + 1)
        });

        assertEq(fraxOracle.lastCorrectRoundId(), 0, "Not updated, deviation too large");

        vm.warp(initialTimestamp + 2);

        fraxOracle.addRoundData({
            _isBadData: true,
            _priceLow: 0.971e18,
            _priceHigh: 1e18,
            _timestamp: uint40(initialTimestamp + 2)
        });

        vm.stopPrank();

        assertEq(fraxOracle.lastCorrectRoundId(), 0, "Not updated, isBadData is true");

        (, int256 answer0, , , ) = fraxOracle.getRoundData(0);
        (, int256 answer1, , , ) = fraxOracle.getRoundData(1);

        assertGt(answer0, answer1);

        (, int256 answerLatest, , , ) = fraxOracle.latestRoundData();
        assertEq(answerLatest, answer0, "Getting data from first call to addRoundData");
    }

    function testAddRoundDataNotPriceSourceRevert() public {
        vm.expectRevert(FraxOracle.OnlyPriceSource.selector);
        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.9e18,
            _priceHigh: 1e18,
            _timestamp: uint40(block.timestamp)
        });
    }

    function testAddRoundDataCalledWithFutureTimestampRevert() public {
        vm.startPrank(priceSourceAddress);
        vm.expectRevert(FraxOracle.CalledWithFutureTimestamp.selector);
        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.9e18,
            _priceHigh: 1e18,
            _timestamp: uint40(block.timestamp + 1)
        });
        vm.stopPrank();
    }

    function testAddRoundDataCalledWithTimestampBeforePreviousRoundRevert() public virtual {
        testAddRoundDataLastRoundIdUpdated();
        (, , uint40 prevTimestamp, ) = fraxOracle.rounds(0);

        vm.startPrank(priceSourceAddress);
        vm.expectRevert(FraxOracle.CalledWithTimestampBeforePreviousRound.selector);
        fraxOracle.addRoundData({ _isBadData: false, _priceLow: 0.9e18, _priceHigh: 1e18, _timestamp: prevTimestamp });

        vm.expectRevert(FraxOracle.CalledWithTimestampBeforePreviousRound.selector);
        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: 0.9e18,
            _priceHigh: 1e18,
            _timestamp: prevTimestamp - 1
        });
        vm.stopPrank();
    }

    //==============================================================================
    // getPrices tests
    //==============================================================================

    function testGetPricesHitMaximumOracleDelay() public virtual {
        uint104 _priceLow = 0.971e18;
        uint104 _priceHigh = 1e18;
        uint256 initialTimestamp = block.timestamp;

        vm.startPrank(priceSourceAddress);
        fraxOracle.addRoundData({
            _isBadData: false,
            _priceLow: _priceLow,
            _priceHigh: _priceHigh,
            _timestamp: uint40(initialTimestamp)
        });

        assertEq(fraxOracle.lastCorrectRoundId(), 0, "Set to 0");

        vm.warp(initialTimestamp + fraxOracle.maximumOracleDelay());

        (bool isBadData, uint256 priceLow, uint256 priceHigh) = fraxOracle.getPrices();
        assertFalse(isBadData, "Right before price goes stale");
        assertEq(priceLow, _priceLow);
        assertEq(priceHigh, _priceHigh);

        vm.warp(initialTimestamp + fraxOracle.maximumOracleDelay() + 1);

        (isBadData, priceLow, priceHigh) = fraxOracle.getPrices();
        assertTrue(isBadData, "Too long since fresh price");
        assertEq(priceLow, _priceLow);
        assertEq(priceHigh, _priceHigh);
    }

    function testGetPricesNoPriceDataRevert() public virtual {
        vm.expectRevert(FraxOracle.NoPriceData.selector);
        fraxOracle.getPrices();
    }

    //==============================================================================
    // getRoundData tests
    //==============================================================================
    function testGetRoundDataNoPriceDataRevert() public virtual {
        vm.expectRevert(FraxOracle.NoPriceData.selector);
        fraxOracle.getRoundData(0);
    }

    //==============================================================================
    // latestRoundData tests
    //==============================================================================

    function testGetLatestRoundDataNoPriceDataRevert() public virtual {
        vm.expectRevert(FraxOracle.NoPriceData.selector);
        fraxOracle.latestRoundData();
    }
}
