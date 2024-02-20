// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import {
    console2 as console,
    Test,
    stdError,
    StdStorage,
    stdStorage,
    stdMath,
    stdJson,
    Vm,
    StdUtils,
    StdChains
} from "forge-std/Test.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IDualOracle } from "src/interfaces/IDualOracle.sol";
import { OracleHelper } from "frax-std/oracles/OracleHelper.sol";
import "src/Constants.sol" as Constants;

library DualOracleHelper {
    function setPrices(address _oracle, bool _isBadData, uint256 _price1, uint256 _price2, Vm vm) public {
        vm.mockCall(
            _oracle,
            abi.encodeWithSelector(IDualOracle.getPrices.selector),
            abi.encode(_isBadData, _price1, _price2)
        );
    }
}

contract TestHelper is Constants.Helper, Test {
    using stdStorage for StdStorage;
    using OracleHelper for AggregatorV3Interface;
    using SafeCast for uint256;
    using Strings for uint256;

    // helper to faucet funds to ERC20 contracts
    function faucetFunds(IERC20 _contract, uint256 _amount, address _user) public {
        stdstore.target(address(_contract)).sig(_contract.balanceOf.selector).with_key(_user).checked_write(_amount);
    }

    // helper to move forward one block
    function mineOneBlock() public returns (uint256 _timeElapsed, uint256 _blocksElapsed) {
        _timeElapsed = 12;
        _blocksElapsed = 1;
        vm.warp(block.timestamp + _timeElapsed);
        vm.roll(block.number + _blocksElapsed);
    }

    // helper to move forward multiple blocks
    function mineBlocks(uint256 _blocks) public returns (uint256 _timeElapsed, uint256 _blocksElapsed) {
        _timeElapsed = (12 * _blocks);
        _blocksElapsed = _blocks;
        vm.warp(block.timestamp + _timeElapsed);
        vm.roll(block.number + _blocksElapsed);
    }
}
