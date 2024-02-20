// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "src/ChainLinkTokenDualOracle.sol";
import "./BaseOracleTest.t.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "src/interfaces/IDualOracle.sol";
import "src/interfaces/IFrxEthStableSwap.sol";
import { deployChainLinkTokenDualOracle } from "script/deploy/DeployChainLinkTokenDualOracle.s.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

contract TestChainLinkTokenDualOracle is TestHelper {
    using OracleHelper for AggregatorV3Interface;

    ChainLinkTokenDualOracle public dualOracle;
    uint256 ORACLE_PRECISION;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_URL"));

        (address _dualOracleAddress, , ) = deployChainLinkTokenDualOracle();

        dualOracle = ChainLinkTokenDualOracle(_dualOracleAddress);
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
    }

    function _assertInvariants(IDualOracle _dualOracle) internal {
        (, uint256 _priceLow, uint256 _priceHigh) = _dualOracle.getPrices();
        assertLe(_priceLow, _priceHigh, "Assert prices are in order");
    }

    function testStaleEthUsdData() public {
        address _address = dualOracle.ETH_USD_CHAINLINK_FEED_ADDRESS();
        AggregatorV3Interface _ethUsdOracle = AggregatorV3Interface(_address);
        (, int256 _price, , , ) = _ethUsdOracle.latestRoundData();
        _ethUsdOracle.setPrice(uint256(_price), uint256(block.timestamp - 4000), vm);
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();
        assertTrue(_isBadData, "High level output should show bad data");
        (bool _isBadEthUsdChainlinkData, , ) = dualOracle.getEthUsdChainlinkPrice();
        assertTrue(_isBadEthUsdChainlinkData, "EthUsdChainlink should show bad data");
        (bool _isBadChainlinkData, , ) = dualOracle.getChainlinkPrice();
        assertFalse(_isBadChainlinkData, "Regular Chainlink should not show bad data");
    }

    function testStaleChainlinkData() public {
        address _address = dualOracle.CHAINLINK_FEED_ADDRESS();
        AggregatorV3Interface _chainlinkFeed = AggregatorV3Interface(_address);
        (, int256 _price, , , ) = _chainlinkFeed.latestRoundData();
        _chainlinkFeed.setPrice(_price, uint256(block.timestamp - 90_000), vm);
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();
        assertTrue(_isBadData, "High level output should show bad data");
        (bool _isBadEthUsdChainlinkData, , ) = dualOracle.getEthUsdChainlinkPrice();
        assertFalse(_isBadEthUsdChainlinkData, "EthUsd Chainlink should show bad data after 40k blocks");
    }

    function testCanSetEthUsdDelay() public {
        uint256 _newDelay = 1000;
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        (bool _isBadDataInitial, , ) = dualOracle.getPrices();
        dualOracle.setMaximumEthUsdOracleDelay(_newDelay);
        vm.stopPrank();
        address _address = dualOracle.ETH_USD_CHAINLINK_FEED_ADDRESS();
        AggregatorV3Interface _ethUsdOracle = AggregatorV3Interface(_address);
        (, int256 _price, , , ) = _ethUsdOracle.latestRoundData();
        _ethUsdOracle.setPrice(_price, uint256(block.timestamp - 1001), vm);
        (bool _isBadDataAfterDelay, , ) = dualOracle.getPrices();
        assertFalse(_isBadDataInitial, "Initial data should not be bad");
        assertTrue(_isBadDataAfterDelay, "Data after delay should be bad");
    }

    function testCanSetChainlinkDelay() public {
        uint256 _newDelay = 1000;
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        dualOracle.setMaximumOracleDelay(_newDelay);
        vm.stopPrank();
        address _address = dualOracle.CHAINLINK_FEED_ADDRESS();
        AggregatorV3Interface _chainlinkFeed = AggregatorV3Interface(_address);
        (, int256 _price, , , ) = _chainlinkFeed.latestRoundData();
        _chainlinkFeed.setPrice(_price, uint256(block.timestamp), vm);
        (bool _isBadDataInitial, , ) = dualOracle.getPrices();
        _chainlinkFeed.setPrice(_price, uint256(block.timestamp - 1001), vm);
        (bool _isBadDataAfterDelay, , ) = dualOracle.getPrices();
        assertFalse(_isBadDataInitial, "Initial data should not be bad");
        assertTrue(_isBadDataAfterDelay, "Data after delay should be bad");
    }

    function testGetPricesChainLinkToken() public {
        (, uint256 _priceLow, uint256 _priceHigh) = dualOracle.getPrices();

        Logger.decimal("_priceHigh", _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceHigh (inverted)", 1e36 / _priceHigh, ORACLE_PRECISION);
        Logger.decimal("_priceLow", _priceLow, ORACLE_PRECISION);
        Logger.decimal("_priceLow (inverted)", 1e36 / _priceLow, ORACLE_PRECISION);
        _assertInvariants(IDualOracle(address(dualOracle)));
    }
}
