// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { StateRootOracle } from "src/frax-oracle/StateRootOracle.sol";
import { IBlockHashProvider } from "src/frax-oracle/interfaces/IBlockHashProvider.sol";

function deployStateRootOracle(
    IBlockHashProvider[] memory providers,
    uint256 minimumRequiredProviders
) returns (address _address, bytes memory _constructorParams, string memory _contractName) {
    _constructorParams = abi.encode(providers, minimumRequiredProviders, Constants.Arbitrum.TIMELOCK_ADDRESS);
    _contractName = "StateRootOracle";
    _address = address(new StateRootOracle(providers, minimumRequiredProviders, Constants.Arbitrum.TIMELOCK_ADDRESS));
}

contract DeployStateRootOracle is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        IBlockHashProvider[] memory providers = new IBlockHashProvider[](1);
        providers[0] = IBlockHashProvider(Constants.Arbitrum.FRAX_ORACLE_BLOCKHASH_PROVIDER);

        (_address, _constructorParams, _contractName) = deployStateRootOracle({
            providers: providers,
            minimumRequiredProviders: 1
        });
    }
}
