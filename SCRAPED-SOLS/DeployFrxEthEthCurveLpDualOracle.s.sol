// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import {
    FrxEthEthCurveLpDualOracle,
    ConstructorParams as FrxEthEthCurveLpDualOracleParams
} from "src/FrxEthEthCurveLpDualOracle.sol";
import {
    ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams
} from "src/abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import {
    ConstructorParams as CurvePoolEmaPriceOracleWithMinMaxParams
} from "src/abstracts/CurvePoolEmaPriceOracleWithMinMax.sol";
import {
    ConstructorParams as CurvePoolVirtualPriceOracleWithMinMaxParams
} from "src/abstracts/CurvePoolVirtualPriceOracleWithMinMax.sol";
import { ConstructorParams as UniswapV3SingleTwapOracleParams } from "src/abstracts/UniswapV3SingleTwapOracle.sol";
import { ConstructorParams as ChainlinkOracleWithMaxDelayParams } from "src/abstracts/ChainlinkOracleWithMaxDelay.sol";

struct DeployFrxEthEthCurveLpDualOracleReturn {
    address _address;
    bytes constructorParams;
    string contractName;
}

function deployFrxEthEthCurveLpDualOracle() returns (DeployFrxEthEthCurveLpDualOracleReturn memory _return) {
    FrxEthEthCurveLpDualOracleParams memory _params = FrxEthEthCurveLpDualOracleParams({
        timelockAddress: Constants_Mainnet.TIMELOCK_ADDRESS,
        frxEthEthCurveLp: Constants_Mainnet.FRXETH_ETH_CURVE_POOL_LP_ERC20,
        frxEthFraxUniswapV3SingleTwapOracleParams: UniswapV3SingleTwapOracleParams({
            uniswapV3PairAddress: Constants_Mainnet.FRXETH_FRAX_V3_POOL,
            twapDuration: 1800,
            baseToken: Constants_Mainnet.FRAX_ERC20,
            quoteToken: Constants_Mainnet.FRXETH_ERC20
        }),
        ethUsdChainlinkOracleWithMaxDelayParams: EthUsdChainlinkOracleWithMaxDelayParams({
            ethUsdChainlinkFeedAddress: Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE,
            maxEthUsdOracleDelay: 3900
        }),
        frxEthEthCurvePoolEmaPriceOracleWithMinMaxParams: CurvePoolEmaPriceOracleWithMinMaxParams({
            curvePoolEmaPriceOracleAddress: Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            minimumCurvePoolEma: 7e17,
            maximumCurvePoolEma: 1e18
        }),
        frxEthEthCurvePoolVirtualPriceOracleWithMinMaxParams: CurvePoolVirtualPriceOracleWithMinMaxParams({
            curvePoolVirtualPriceAddress: Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            minimumCurvePoolVirtualPrice: 1e18,
            maximumCurvePoolVirtualPrice: 12e17
        }),
        fraxUsdChainlinkOracleWithMaxDelayParams: ChainlinkOracleWithMaxDelayParams({
            chainlinkFeedAddress: Constants_Mainnet.FRAX_USD_CHAINLINK_ORACLE,
            maximumOracleDelay: 3900
        })
    });
    _return.constructorParams = abi.encode(_params);
    _return.contractName = "FrxEthEthCurveLpDualOracle";
    _return._address = address(new FrxEthEthCurveLpDualOracle(_params));
}

contract DeployFrxEthEthCurveLpDualOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        DeployFrxEthEthCurveLpDualOracleReturn memory _return = deployFrxEthEthCurveLpDualOracle();
        _address = _return._address;
        _constructorParams = _return.constructorParams;
        _contractName = _return.contractName;
        console.log("_constructorParams:");
        console.logBytes(_return.constructorParams);
        console.log(_return.contractName, "deployed to _address:", _return._address);
        _updateEnv(_return._address, _return.constructorParams, _return.contractName);
    }
}
