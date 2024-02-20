// SPDX-License-Identifier: ISC
pragma solidity >=0.8.19;

import "frax-std/BaseScript.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { ApeCoinDualOracle, ConstructorParams as ApeCoinDualOracleParams } from "src/ApeCoinDualOracle.sol";

function deployApeCoinDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    ApeCoinDualOracleParams memory _params = ApeCoinDualOracleParams({
        apeErc20: Constants_Mainnet.APE_ERC20,
        wethErc20: Constants_Mainnet.WETH_ERC20,
        apeUsdChainlinkFeed: Constants_Mainnet.APE_USD_CHAINLINK_ORACLE,
        maximumOracleDelay: 86_700, // +5 minutes
        ethUsdChainlinkFeed: Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 3900, // +5 minutes
        uniV3PairAddress: Constants_Mainnet.APE_WETH_UNI_V3_POOL,
        twapDuration: 900, // 15 minutes
        timelockAddress: Constants_Mainnet.TIMELOCK_ADDRESS
    });
    _constructorParams = abi.encode(_params);
    _contractName = "ApeCoinDualOracle";
    _address = address(new ApeCoinDualOracle(_params));
}

contract DeployApeCoinDualOracle is BaseScript {
    function run() external broadcaster {
        (address _address, bytes memory _constructorArgs, string memory _contractName) = deployApeCoinDualOracle();
        _updateEnv(_address, _constructorArgs, _contractName);
    }
}
