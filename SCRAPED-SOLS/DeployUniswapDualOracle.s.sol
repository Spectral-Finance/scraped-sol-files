// SPDX-License-Identifier: ISC
pragma solidity >=0.8.19;

import "frax-std/BaseScript.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { UniswapDualOracle, ConstructorParams as UniswapDualOracleParams } from "src/UniswapDualOracle.sol";

function deployUniswapDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    UniswapDualOracleParams memory _params = UniswapDualOracleParams({
        uniErc20: Constants_Mainnet.UNI_ERC20,
        wethErc20: Constants_Mainnet.WETH_ERC20,
        uniUsdChainlinkFeed: Constants_Mainnet.UNI_USD_CHAINLINK_ORACLE,
        maximumOracleDelay: 3900, // +5 minutes
        ethUsdChainlinkFeed: Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 3900, // +5 minutes
        uniV3PairAddress: Constants_Mainnet.UNI_ETH_UNI_V3_POOL,
        twapDuration: 900, // 15 minutes
        timelockAddress: Constants_Mainnet.TIMELOCK_ADDRESS
    });
    _constructorParams = abi.encode(_params);
    _contractName = "UniswapDualOracle";
    _address = address(new UniswapDualOracle(_params));
}

contract DeployUniswapDualOracle is BaseScript {
    function run() external broadcaster {
        (address _address, bytes memory _constructorArgs, string memory _contractName) = deployUniswapDualOracle();
        _updateEnv(_address, _constructorArgs, _contractName);
    }
}
