// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "src/interfaces/oracles/abstracts/IChainlinkOracleWithMaxDelay.sol";
import { AggregatorV3InterfaceStructHelper } from "frax-std/oracles/AggregatorV3InterfaceStructHelper.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";
import { IChainlinkOracleWithMaxDelay } from "src/interfaces/oracles/abstracts/IChainlinkOracleWithMaxDelay.sol";

abstract contract TestChainlinkOracleWithMaxDelay is BaseOracleTest {
    using OracleHelper for AggregatorV3Interface;
    using AggregatorV3InterfaceStructHelper for AggregatorV3Interface;

    function _mockChainlinkOracle(uint256 _priceE18) internal {
        address _address = IChainlinkOracleWithMaxDelay(dualOracleAddress).CHAINLINK_FEED_ADDRESS();
        AggregatorV3Interface _chainlinkFeed = AggregatorV3Interface(_address);
        _chainlinkFeed.setPriceWithE18Param(_priceE18, vm);
    }

    function test_ReturnsBadDataWhenChainlinkStale() public useMultipleSetupFunctions {
        address _address = IChainlinkOracleWithMaxDelay(dualOracleAddress).CHAINLINK_FEED_ADDRESS();
        uint256 _delay = IChainlinkOracleWithMaxDelay(dualOracleAddress).maximumOracleDelay();
        AggregatorV3Interface _chainlinkFeed = AggregatorV3Interface(_address);
        int256 _price = _chainlinkFeed.__latestRoundData().answer;
        _chainlinkFeed.setPrice(_price, uint256(block.timestamp - (_delay + 2)), vm);
        uint256 _lastUpdated = _chainlinkFeed.__latestRoundData().updatedAt;
        assertLt(_lastUpdated, block.timestamp - _delay, "Chainlink should be stale");
        (bool _isBadData, , ) = dualOracle.getPrices();
        assertTrue(_isBadData, "High level output should show bad data");
    }

    function test_CanSet_MaximumOracleDelay() public useMultipleSetupFunctions {
        uint256 _newDelay = 100;
        startHoax(_selectTimelockAddress());
        IChainlinkOracleWithMaxDelay(dualOracleAddress).setMaximumOracleDelay(_newDelay);
        vm.stopPrank();
        assertEq(
            IChainlinkOracleWithMaxDelay(dualOracleAddress).maximumOracleDelay(),
            _newDelay,
            "Delay should be set"
        );
    }

    function test_RevertWith_OnlyTimelock_SetMaximumOracleDelay() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        IChainlinkOracleWithMaxDelay(dualOracleAddress).setMaximumOracleDelay(100);
    }
}
