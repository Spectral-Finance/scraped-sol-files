// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import "test/helpers/Helpers.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { IDualOracle } from "src/interfaces/IDualOracle.sol";
import { ArbitrumDualOracle } from "src/ArbitrumDualOracle.sol";

contract SimulateUpdateArbUsdChainlinkOracleDelay is FraxTest {
    using ArrayHelper for *;

    TimelockController timelockController = TimelockController(payable(Constants.Arbitrum.TIMELOCK_ADDRESS));

    function run() public {
        vm.createSelectFork(vm.envString("ARBITRUM_URL"), 88_979_981);

        // Arguments for function call
        address _target = Constants.Arbitrum.ARBITRUM_DUAL_ORACLE_ADDRESS;
        uint256 _value = 0;
        bytes memory _callData = abi.encodeWithSelector(
            ArbitrumDualOracle.setMaximumEthUsdOracleDelay.selector,
            uint256(1 days + 5 minutes)
        );
        uint256 delay = 2 days;
        bytes32 salt = bytes32(0);
        bytes32 predecessor = bytes32(0);

        startHoax(Constants.Arbitrum.FRAXLEND_HOT_WALLET);
        timelockController.schedule({
            target: _target,
            value: _value,
            predecessor: bytes32(0),
            data: _callData,
            salt: salt,
            delay: delay
        });
        vm.warp(block.timestamp + 3 days);
        vm.roll(block.number + (3 days / 12));
        timelockController.execute({
            target: _target,
            value: _value,
            predecessor: predecessor,
            payload: _callData,
            salt: salt
        });
        console.log("target", _target);
        console.log("value", _value);
        console.log("salt");
        console.logBytes32(salt);
        console.log("predecessor");
        console.logBytes32(predecessor);
        console.log("data");
        console.logBytes(_callData);
        console.log("delay", delay);
        vm.stopPrank();
    }
}
