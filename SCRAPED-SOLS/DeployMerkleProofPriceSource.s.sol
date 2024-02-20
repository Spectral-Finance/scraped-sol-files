// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { MerkleProofPriceSource } from "src/frax-oracle/MerkleProofPriceSource.sol";

function deployMerkleProofPriceSource(
    address stateRootOracle
) returns (address _address, bytes memory _constructorParams, string memory _contractName) {
    _constructorParams = abi.encode(stateRootOracle, Constants.Arbitrum.TIMELOCK_ADDRESS);
    _contractName = "MerkleProofPriceSource";
    _address = address(new MerkleProofPriceSource(stateRootOracle, Constants.Arbitrum.TIMELOCK_ADDRESS));
}

contract DeployMerkleProofPriceSource is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        (_address, _constructorParams, _contractName) = deployMerkleProofPriceSource(
            Constants.Arbitrum.FRAX_ORACLE_STATE_ROOT_ORACLE
        );
    }
}
