// SPDX-License-Identifier: ISC
pragma solidity >=0.8.19;

import "frax-std/BaseScript.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { AaveTokenDualOracle, ConstructorParams as AaveTokenDualOracleParams } from "src/AaveTokenDualOracle.sol";

function deployAaveTokenDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    AaveTokenDualOracleParams memory _params = AaveTokenDualOracleParams({
        aaveErc20: Constants_Mainnet.AAVE_ERC20,
        wethErc20: Constants_Mainnet.WETH_ERC20,
        aaveUsdChainlinkFeed: Constants_Mainnet.AAVE_USD_CHAINLINK_ORACLE,
        maximumOracleDelay: 3900, // +5 minutes
        ethUsdChainlinkFeed: Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 3900, // +5 minutes
        uniV3PairAddress: Constants_Mainnet.AAVE_ETH_UNI_V3_POOL,
        twapDuration: 900, // 15 minutes
        timelockAddress: Constants_Mainnet.TIMELOCK_ADDRESS
    });
    _constructorParams = abi.encode(_params);
    _contractName = "AaveTokenDualOracle";
    _address = address(new AaveTokenDualOracle(_params));
}

contract DeployAaveTokenDualOracle is BaseScript {
    function run() external broadcaster {
        (address _address, bytes memory _constructorArgs, string memory _contractName) = deployAaveTokenDualOracle();
        _updateEnv(_address, _constructorArgs, _contractName);
    }
}
