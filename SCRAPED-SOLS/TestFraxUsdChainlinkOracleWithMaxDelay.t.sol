// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {
    IFraxUsdChainlinkOracleWithMaxDelay
} from "src/interfaces/oracles/abstracts/IFraxUsdChainlinkOracleWithMaxDelay.sol";
import { AggregatorV3InterfaceStructHelper } from "frax-std/oracles/AggregatorV3InterfaceStructHelper.sol";
import { IDualOracleStructHelper } from "test/helpers/IDualOracleStructHelper.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";

abstract contract TestFraxUsdChainlinkOracleWithMaxDelay is BaseOracleTest {
    using OracleHelper for AggregatorV3Interface;
    using AggregatorV3InterfaceStructHelper for AggregatorV3Interface;
    using IDualOracleStructHelper for IDualOracle;

    function _mockFraxUsdChainlinkOracle(uint256 _priceE18) internal {
        address _address = IFraxUsdChainlinkOracleWithMaxDelay(dualOracleAddress).FRAX_USD_CHAINLINK_FEED_ADDRESS();
        AggregatorV3Interface _chainlinkFeed = AggregatorV3Interface(_address);
        _chainlinkFeed.setPriceWithE18Param(_priceE18, vm);
    }

    function test_ReturnsBadDataWhenFraxUsdChainlinkStale() public useMultipleSetupFunctions {
        address _address = IFraxUsdChainlinkOracleWithMaxDelay(dualOracleAddress).FRAX_USD_CHAINLINK_FEED_ADDRESS();
        uint256 _delay = IFraxUsdChainlinkOracleWithMaxDelay(dualOracleAddress).maximumFraxUsdOracleDelay();
        AggregatorV3Interface _chainlinkFeed = AggregatorV3Interface(_address);
        _chainlinkFeed.setUpdatedAt(block.timestamp - (_delay + 2), vm);
        uint256 _lastUpdated = _chainlinkFeed.__latestRoundData().updatedAt;
        assertLt(_lastUpdated, block.timestamp - _delay, "Chainlink should be stale");
        bool _isBadData = IDualOracle(dualOracleAddress).__getPrices().isBadData;
        assertTrue(_isBadData, "High level output should show bad data");
    }

    function test_CanSet_MaximumFraxUsdOracleDelay() public useMultipleSetupFunctions {
        uint256 _newDelay = 100;
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        IFraxUsdChainlinkOracleWithMaxDelay(dualOracleAddress).setMaximumFraxUsdOracleDelay(_newDelay);
        vm.stopPrank();
        assertEq(
            IFraxUsdChainlinkOracleWithMaxDelay(dualOracleAddress).maximumFraxUsdOracleDelay(),
            _newDelay,
            "Delay should be set"
        );
    }

    function test_RevertWith_OnlyTimelock_SetFraxUsdMaximumOracleDelay() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        IFraxUsdChainlinkOracleWithMaxDelay(dualOracleAddress).setMaximumFraxUsdOracleDelay(100);
    }
}
