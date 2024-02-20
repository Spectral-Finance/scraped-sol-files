// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "src/Constants.sol" as Constants;

import {
    FraxUsdcCurveLpDualOracle,
    ConstructorParams as FraxUsdcCurveLpDualOracleParams
} from "src/FraxUsdcCurveLpDualOracle.sol";

struct DeployFraxUsdcCurveLpDualOracleReturn {
    address _address;
    bytes constructorParams;
    string contractName;
}

function deployFraxUsdcCurveLpDualOracle() returns (DeployFraxUsdcCurveLpDualOracleReturn memory _return) {
    FraxUsdcCurveLpDualOracleParams memory _params = FraxUsdcCurveLpDualOracleParams({
        timelockAddress: Constants.Mainnet.TIMELOCK_ADDRESS,
        fraxErc20: Constants.Mainnet.FRAX_ERC20,
        fraxErc20Decimals: IERC20Metadata(Constants.Mainnet.FRAX_ERC20).decimals(),
        usdcErc20: Constants.Mainnet.USDC_ERC20,
        usdcErc20Decimals: IERC20Metadata(Constants.Mainnet.USDC_ERC20).decimals(),
        wethErc20: Constants.Mainnet.WETH_ERC20,
        wethErc20Decimals: IERC20Metadata(Constants.Mainnet.WETH_ERC20).decimals(),
        fraxUsdcCurveLpErc20: Constants.Mainnet.FRAX_USDC_CURVE_POOL_LP_ERC20,
        fraxUsdcCurveLpErc20Decimals: IERC20Metadata(Constants.Mainnet.FRXETH_ETH_CURVE_POOL_LP_ERC20).decimals(),
        // =
        baseToken0: Constants.Mainnet.FRAX_ERC20,
        baseToken0Decimals: 18,
        quoteToken0: Constants.Mainnet.FRAX_USDC_CURVE_POOL_LP_ERC20,
        quoteToken0Decimals: 18,
        baseToken1: Constants.Mainnet.FRAX_ERC20,
        baseToken1Decimals: 18,
        quoteToken1: Constants.Mainnet.FRAX_USDC_CURVE_POOL_LP_ERC20,
        quoteToken1Decimals: 18,
        // =
        usdcUsdChainlinkFeedAddress: Constants.Mainnet.USDC_USD_CHAINLINK_ORACLE,
        usdUsdcChainlinkMaximumOracleDelay: 1 days + 5 minutes,
        // =
        fraxUsdChainlinkFeedAddress: Constants.Mainnet.FRAX_USD_CHAINLINK_ORACLE,
        fraxUsdMaximumOracleDelay: 1 hours + 5 minutes,
        // =
        curvePoolVirtualPriceAddress: Constants.Mainnet.FRAX_USDC_CURVE_POOL_NOT_LP,
        minimumCurvePoolVirtualPrice: 1e18,
        maximumCurvePoolVirtualPrice: 12e17,
        // =
        fraxUsdcUniswapV3PairAddress: Constants.Mainnet.FRAX_USDC_V3_POOL,
        fraxUsdcTwapDuration: 15 minutes,
        fraxUsdcTwapBaseToken: Constants.Mainnet.USDC_ERC20,
        fraxUsdcTwapQuoteToken: Constants.Mainnet.FRAX_ERC20
    });

    _return.constructorParams = abi.encode(_params);
    _return.contractName = "FraxUsdcCurveLpDualOracle";
    _return._address = address(new FraxUsdcCurveLpDualOracle(_params));
}

contract DeployFraxUsdcCurveLpDualOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        DeployFraxUsdcCurveLpDualOracleReturn memory _return = deployFraxUsdcCurveLpDualOracle();
        console.log("_constructorParams:", string(abi.encode(_constructorParams)));
        console.logBytes(_return.constructorParams);
        console.log("_address:", _return._address);
        _updateEnv(_return._address, _return.constructorParams, _return.contractName);
    }
}
