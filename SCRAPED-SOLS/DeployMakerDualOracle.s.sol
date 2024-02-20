// SPDX-License-Identifier: ISC
pragma solidity >=0.8.19;

import "frax-std/BaseScript.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

import { MakerDualOracle, ConstructorParams as MakerDualOracleParams } from "src/MakerDualOracle.sol";

function deployMakerDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    MakerDualOracleParams memory _params = MakerDualOracleParams({
        mkrErc20: Constants_Mainnet.MKR_ERC20,
        wethErc20: Constants_Mainnet.WETH_ERC20,
        mkrUsdChainlinkFeed: Constants_Mainnet.MKR_USD_CHAINLINK_ORACLE,
        maximumOracleDelay: 86_700, // +5 minutes
        ethUsdChainlinkFeed: Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 3900, // +5 minutes
        uniV3PairAddress: Constants_Mainnet.MKR_ETH_UNI_V3_POOL,
        twapDuration: 900, // 15 minutes
        timelockAddress: Constants_Mainnet.TIMELOCK_ADDRESS
    });
    _constructorParams = abi.encode(_params);
    _contractName = "MakerDualOracle";
    _address = address(new MakerDualOracle(_params));
}

contract DeployMakerDualOracle is BaseScript {
    function run() external broadcaster {
        (address _address, bytes memory _constructorArgs, string memory _contractName) = deployMakerDualOracle();
        _updateEnv(_address, _constructorArgs, _contractName);
    }
}
