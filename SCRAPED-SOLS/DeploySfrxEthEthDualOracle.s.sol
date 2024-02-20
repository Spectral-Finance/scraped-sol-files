// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import {
    FrxEthEthDualOracle,
    ConstructorParams as FrxEthEthDualOracleParams
} from "src/frax-oracle/FrxEthEthDualOracle.sol";
import { generateFrxEthEthDualOracleParams } from "./DeployFrxEthEthDualOracle.s.sol";
import {
    SfrxEthEthDualOracle,
    ConstructorParams as SfrxEthEthDualOracleParams
} from "src/frax-oracle/SfrxEthEthDualOracle.sol";

function deploySfrxEthEthDualOracle()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    SfrxEthEthDualOracleParams memory params = SfrxEthEthDualOracleParams({
        frxEthEthDualOracleParams: generateFrxEthEthDualOracleParams(),
        sfrxEthErc4626: Constants.Mainnet.SFRXETH_ERC20
    });

    _constructorParams = abi.encode(params);
    _contractName = "SfrxEthEthDualOracle";
    _address = address(new SfrxEthEthDualOracle(params));
}

contract DeploySfrxEthEthDualOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deploySfrxEthEthDualOracle();
    }
}
