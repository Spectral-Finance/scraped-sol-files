// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { ArbitrumBlockHashRelay } from "src/frax-oracle/relays/ArbitrumBlockHashRelay.sol";

function deployArbitrumBlockHashRelay(
    address layer2TargetProvider,
    address inbox
) returns (address _address, bytes memory _constructorParams, string memory _contractName) {
    _constructorParams = abi.encode(layer2TargetProvider, inbox);
    _contractName = "ArbitrumBlockHashRelay";
    _address = address(new ArbitrumBlockHashRelay(layer2TargetProvider, inbox));
}

contract DeployArbitrumBlockHashRelay is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deployArbitrumBlockHashRelay({
            layer2TargetProvider: Constants.Arbitrum.FRAX_ORACLE_BLOCKHASH_PROVIDER,
            inbox: Constants.Mainnet.ARBITRUM_DELAYED_INBOX
        });
    }
}
