// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "src/_v1/SfrxEthOracle.sol";
import "src/SfrxEthDualOracleChainlinkUniV3.sol";
import "src/interfaces/IFrxEthStableSwap.sol";
import "./BaseOracleTest.t.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

contract SfrxEthDualOracle is TestHelper {
    using OracleHelper for AggregatorV3Interface;

    SfrxEthDualOracleChainlinkUniV3 internal dualOracle;

    uint128 internal ORACLE_PRECISION;
    address internal BASE_TOKEN;
    address internal QUOTE_TOKEN;

    // Chainlink Config
    address internal CHAINLINK_MULTIPLY_ADDRESS;
    address internal CHAINLINK_DIVIDE_ADDRESS;
    uint256 internal CHAINLINK_NORMALIZATION;
    uint256 internal maxOracleDelay;

    // Uni V3 Data
    address internal UNI_V3_PAIR_ADDRESS;
    uint32 internal TWAP_DURATION;

    // Config Data
    uint8 internal DECIMALS;
    string internal name;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_URL"), 16_460_440);

        dualOracle = new SfrxEthDualOracleChainlinkUniV3(
            Constants_Mainnet.FRAX_ERC20,
            Constants_Mainnet.FRXETH_ERC20,
            address(0),
            Constants_Mainnet.SFRXETH_ORACLE_V2,
            86400,
            Constants_Mainnet.FRXETH_FRAX_V3_POOL,
            1800,
            Constants_Mainnet.TIMELOCK_ADDRESS,
            "test sfrxEth dual oracle"
        );
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();
        BASE_TOKEN = dualOracle.BASE_TOKEN();
        QUOTE_TOKEN = dualOracle.QUOTE_TOKEN();
        CHAINLINK_MULTIPLY_ADDRESS = dualOracle.CHAINLINK_MULTIPLY_ADDRESS();
        CHAINLINK_DIVIDE_ADDRESS = dualOracle.CHAINLINK_DIVIDE_ADDRESS();
        CHAINLINK_NORMALIZATION = dualOracle.CHAINLINK_NORMALIZATION();
        maxOracleDelay = dualOracle.maxOracleDelay();
        UNI_V3_PAIR_ADDRESS = dualOracle.UNI_V3_PAIR_ADDRESS();
        TWAP_DURATION = dualOracle.TWAP_DURATION();
        DECIMALS = dualOracle.decimals();
        name = dualOracle.name();
    }

    function testGetDualPrices() public {
        (bool _isBadData, uint256 _lowPrice, uint256 _highPrice) = dualOracle.getPrices();
        assertApproxEqRelDecimal(
            _lowPrice,
            _highPrice,
            5e17,
            18,
            "low and high prices should be within 5% of each other"
        );
    }

    function testBadData() public {
        AggregatorV3Interface chainlinkOracle = AggregatorV3Interface(CHAINLINK_DIVIDE_ADDRESS);
        chainlinkOracle.setPrice(1, 1685, block.timestamp - 100_000, vm);
        (bool _isBadData, uint256 _lowPrice, uint256 _highPrice) = dualOracle.getPrices();
        assertTrue(_isBadData, "should be bad data");
    }
}
