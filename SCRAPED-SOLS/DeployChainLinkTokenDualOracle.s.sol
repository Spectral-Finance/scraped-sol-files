// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";
import {
    ChainLinkTokenDualOracle,
    ConstructorParams as ChainLinkTokenDualOracleParams
} from "src/ChainLinkTokenDualOracle.sol";

function deployChainLinkTokenDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    ChainLinkTokenDualOracleParams memory _params = ChainLinkTokenDualOracleParams({
        linkErc20: Constants_Mainnet.LINK_ERC20,
        wethErc20: Constants_Mainnet.WETH_ERC20,
        linkUsdChainlinkFeed: Constants_Mainnet.LINK_USD_CHAINLINK_ORACLE,
        maximumOracleDelay: 3900,
        ethUsdChainlinkFeed: Constants_Mainnet.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 3900,
        uniV3PairAddress: Constants_Mainnet.LINK_ETH_UNI_V3_POOL,
        twapDuration: 900,
        timelockAddress: Constants_Mainnet.TIMELOCK_ADDRESS
    });

    _constructorParams = abi.encode(_params);
    _contractName = "ChainLinkTokenDualOracle";
    _address = address(new ChainLinkTokenDualOracle(_params));
}

contract DeployChainLinkTokenDualOracle is BaseScript {
    function run() external {
        deploy(deployChainLinkTokenDualOracle);
    }
}
