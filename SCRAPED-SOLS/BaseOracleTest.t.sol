// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "frax-std/FraxTest.sol";
import "src/interfaces/IDualOracle.sol";
import "../helpers/Helpers.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

abstract contract BaseOracleTest is TestHelper {
    address public dualOracleAddress;
    IDualOracle public dualOracle;

    function()[] internal setupFunctions;

    modifier useMultipleSetupFunctions() {
        for (uint256 i = 0; i < setupFunctions.length; i++) {
            setupFunctions[i]();
            _;
            vm.clearMockedCalls();
        }
    }

    function _selectTimelockAddress() internal returns (address) {
        if (block.chainid == 1) {
            return Constants_Mainnet.TIMELOCK_ADDRESS;
        } else if (block.chainid == 42_161) {
            return Constants_Arbitrum.TIMELOCK_ADDRESS;
        } else {
            revert("Add current chainid / timelock address");
        }
    }
}
