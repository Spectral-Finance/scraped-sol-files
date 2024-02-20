// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./BaseOracleTest.t.sol";
import "src/interfaces/IGOhm.sol";
import "src/_v1/GOhmOracle.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

contract TestGohmOracle is TestHelper {
    using OracleHelper for AggregatorV3Interface;
    using Strings for uint256;

    AggregatorV3Interface public ethUsdChainlinkOracle;
    AggregatorV3Interface public ohmv2EthChainlinkOracle;
    IGOhm public gOhm;

    function setUp() public {
        string memory _envKey = vm.envString("MAINNET_URL");
        vm.createSelectFork(_envKey, 16_474_174);
        ethUsdChainlinkOracle = AggregatorV3Interface(Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE);
        ohmv2EthChainlinkOracle = AggregatorV3Interface(Constants_Mainnet.OHMV2_ETH_CHAINLINK_ORACLE);
        gOhm = IGOhm(Constants_Mainnet.GOHM_ERC20);
    }

    function testDisplayCurrentGOhmPrice() public {
        string memory _envKey = vm.envString("MAINNET_URL");
        vm.createSelectFork(_envKey, 16_069_738);
        GOhmOracle _gOhmOracle = new GOhmOracle(
            Constants_Mainnet.GOHM_ERC20,
            Constants_Mainnet.OHMV2_ETH_CHAINLINK_ORACLE,
            Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE
        );
        (, int256 _answer, , , ) = _gOhmOracle.latestRoundData();
        Logger.decimal("_answer", uint256(_answer), 18);
    }

    function testGOhmOracle() public {
        // Set price of gOhmEthOracle
        ohmv2EthChainlinkOracle.setPrice(1e10, 8e10, block.timestamp, vm);

        // Set price of EthUsdOracle
        ethUsdChainlinkOracle.setPrice(2000, 1, block.timestamp, vm);
        mineOneBlock();

        // Get prices from oracles
        (, int256 _currentOhmPrice, , , ) = ohmv2EthChainlinkOracle.latestRoundData();
        (, int256 _currentEthPrice, , , ) = ethUsdChainlinkOracle.latestRoundData();

        // Get current index from index
        uint256 _gOhmIndex = gOhm.index();
        uint256 _gOhmIndexDecimals = 9;

        // Deploy gOhmOracle
        GOhmOracle _gOhmOracle = new GOhmOracle(
            Constants_Mainnet.GOHM_ERC20,
            Constants_Mainnet.OHMV2_ETH_CHAINLINK_ORACLE,
            Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE
        );

        string[] memory _inputs = new string[](9);
        _inputs[0] = "node";
        _inputs[1] = "test/utils/gOhmPriceCalculator.js";
        _inputs[2] = uint256(_gOhmIndex).toString();
        _inputs[3] = uint256(_gOhmIndexDecimals).toString();
        _inputs[4] = uint256(_currentOhmPrice).toString();
        _inputs[5] = uint256(ohmv2EthChainlinkOracle.decimals()).toString();
        _inputs[6] = uint256(_currentEthPrice).toString();
        _inputs[7] = uint256(ethUsdChainlinkOracle.decimals()).toString();
        _inputs[8] = uint256(_gOhmOracle.decimals()).toString();

        bytes memory _ret = vm.ffi(_inputs);
        int256 _expectedPrice = abi.decode(_ret, (int256));

        (, int256 _actualPrice, , , ) = _gOhmOracle.latestRoundData();

        assertEq(_expectedPrice, _actualPrice, "gOhmOracle expected == actual");
    }
}
