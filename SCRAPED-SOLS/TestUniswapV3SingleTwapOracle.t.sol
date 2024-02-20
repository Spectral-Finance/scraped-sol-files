// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import "src/interfaces/oracles/abstracts/IUniswapV3SingleTwapOracle.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

abstract contract TestUniswapV3SingleTwapOracle is BaseOracleTest {
    function test_CanSet_TwapDuration() public useMultipleSetupFunctions {
        uint256 _duration = 100;
        startHoax(_selectTimelockAddress());
        IUniswapV3SingleTwapOracle(dualOracleAddress).setTwapDuration(uint32(_duration));
        vm.stopPrank();
        assertEq(IUniswapV3SingleTwapOracle(dualOracleAddress).twapDuration(), _duration, "Duration should be set");
    }

    function test_RevertWith_TimelockOnly_SetDuration() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        IUniswapV3SingleTwapOracle(dualOracleAddress).setTwapDuration(uint32(100));
    }
}
