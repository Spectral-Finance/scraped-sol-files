// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import {
    FrxEthEthDualOracle,
    ConstructorParams as FrxEthEthDualOracleParams
} from "src/frax-oracle/FrxEthEthDualOracle.sol";

function generateFrxEthEthDualOracleParams() returns (FrxEthEthDualOracleParams memory params) {
    params = FrxEthEthDualOracleParams({
        // = DualOracleBase
        baseToken0: Constants.Mainnet.FRXETH_ERC20,
        baseToken0Decimals: 18,
        quoteToken0: Constants.Mainnet.WETH_ERC20,
        quoteToken0Decimals: 18,
        baseToken1: Constants.Mainnet.FRXETH_ERC20,
        baseToken1Decimals: 18,
        quoteToken1: Constants.Mainnet.WETH_ERC20,
        quoteToken1Decimals: 18,
        // = UniswapV3SingleTwapOracle
        frxEthErc20: Constants.Mainnet.FRXETH_ERC20,
        fraxErc20: Constants.Mainnet.FRAX_ERC20,
        uniV3PairAddress: Constants.Mainnet.FRXETH_FRAX_V3_POOL,
        twapDuration: 15 minutes,
        // = FraxUsdChainlinkOracleWithMaxDelay
        fraxUsdChainlinkFeedAddress: Constants.Mainnet.FRAX_USD_CHAINLINK_ORACLE,
        fraxUsdMaximumOracleDelay: 1 hours + 5 minutes,
        // = EthUsdChainlinkOracleWithMaxDelay
        ethUsdChainlinkFeed: Constants.Mainnet.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 3900,
        // = CurvePoolEmaPriceOracleWithMinMax
        curvePoolEmaPriceOracleAddress: Constants.Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
        minimumCurvePoolEma: 7e17, // .7
        maximumCurvePoolEma: 1e18, // 1
        // = Timelock2Step
        timelockAddress: Constants.Mainnet.TIMELOCK_ADDRESS
    });
}

function deployFrxEthEthDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    FrxEthEthDualOracleParams memory params = generateFrxEthEthDualOracleParams();

    _constructorParams = abi.encode(params);
    _contractName = "FrxEthEthDualOracle";
    _address = address(new FrxEthEthDualOracle(params));
}

contract DeployFrxEthEthDualOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deployFrxEthEthDualOracle();
    }
}
