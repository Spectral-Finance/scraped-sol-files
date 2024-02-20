// SPDX-License-Identifier: ISC
pragma solidity >=0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { ArbitrumDualOracle, ConstructorParams as ArbitrumDualOracleParams } from "src/ArbitrumDualOracle.sol";

function deployArbitrumDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    ArbitrumDualOracleParams memory _params = ArbitrumDualOracleParams({
        // = Timelock2Step
        timelockAddress: Constants.Arbitrum.TIMELOCK_ADDRESS,
        // = DualOracleBase
        baseToken0: address(840),
        baseToken0Decimals: 18,
        quoteToken0: Constants.Arbitrum.ARB_ERC20,
        quoteToken0Decimals: 18,
        baseToken1: address(840),
        baseToken1Decimals: 18,
        quoteToken1: Constants.Arbitrum.ARB_ERC20,
        quoteToken1Decimals: 18,
        // = UniswapV3SingleTwapOracle
        arbErc20: Constants.Arbitrum.ARB_ERC20,
        wethErc20: Constants.Arbitrum.WETH_ERC20,
        uniV3PairAddress: Constants.Arbitrum.ARB_ETH_UNI_V3_POOL,
        twapDuration: 15 minutes,
        // = ChainlinkOracleWithMaxDelay
        arbUsdChainlinkFeedAddress: Constants.Arbitrum.ARB_USD_CHAINLINK_ORACLE,
        arbUsdChainlinkMaximumOracleDelay: 1 days + 5 minutes,
        // = EthUsdChainlinkOracleWithMaxDelay
        ethUsdChainlinkFeed: Constants.Arbitrum.ETH_USD_CHAINLINK_ORACLE,
        maxEthUsdOracleDelay: 1 days + 5 minutes
    });

    _constructorParams = abi.encode(_params);
    _contractName = "ArbitrumDualOracle";
    _address = address(new ArbitrumDualOracle(_params));
}

contract DeployArbitrumDualOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deployArbitrumDualOracle();
    }
}
