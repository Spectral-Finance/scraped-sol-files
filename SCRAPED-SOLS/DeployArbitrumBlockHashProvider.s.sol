// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { ArbitrumBlockHashProvider } from "src/frax-oracle/providers/ArbitrumBlockHashProvider.sol";

function deployArbitrumBlockHashProvider()
    returns (address _address, bytes memory _constructorParams, string memory _contractName)
{
    _contractName = "ArbitrumBlockHashProvider";
    _address = address(new ArbitrumBlockHashProvider());
}

contract DeployArbitrumBlockHashProvider is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deployArbitrumBlockHashProvider();
    }
}
