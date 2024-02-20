// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { SfrxEthFraxOracle, FraxOracleParams } from "src/frax-oracle/SfrxEthFraxOracle.sol";

function deploySfrxEthFraxOracle(
    address priceSource
) returns (address _address, bytes memory _constructorParams, string memory _contractName) {
    FraxOracleParams memory params = FraxOracleParams({
        timelockAddress: Constants.Mainnet.TIMELOCK_ADDRESS,
        baseErc20: Constants.Mainnet.SFRXETH_ERC20,
        quoteErc20: Constants.Mainnet.WETH_ERC20,
        priceSource: priceSource,
        maximumDeviation: 0.03e18, // 3%
        maximumOracleDelay: 25 hours
    });

    _constructorParams = abi.encode(params);
    _contractName = "SfrxEthFraxOracle";
    _address = address(new SfrxEthFraxOracle(params));
}

contract DeploySfrxEthFraxOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deploySfrxEthFraxOracle(
            Constants.Mainnet.SFRXETH_ETH_DUAL_ORACLE_ADDRESS
        );
    }
}
