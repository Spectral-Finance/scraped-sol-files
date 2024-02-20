// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseOracleTest.t.sol";
import {
    IFraxUsdcUniswapV3SingleTwapOracle
} from "src/interfaces/oracles/abstracts/IFraxUsdcUniswapV3SingleTwapOracle.sol";
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { Mainnet as Constants_Mainnet } from "src/Constants.sol";

abstract contract TestFraxUsdcUniswapV3SingleTwapOracle is BaseOracleTest {
    function test_CanSet_FraxUsdcTwapDuration() public useMultipleSetupFunctions {
        uint256 _duration = 100;
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        IFraxUsdcUniswapV3SingleTwapOracle(dualOracleAddress).setFraxUsdcTwapDuration(uint32(_duration));
        vm.stopPrank();
        assertEq(
            IFraxUsdcUniswapV3SingleTwapOracle(dualOracleAddress).fraxUsdcTwapDuration(),
            _duration,
            "Duration should be set"
        );
    }

    function test_RevertWith_TimelockOnly_FraxUsdcSetDuration() public useMultipleSetupFunctions {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        IFraxUsdcUniswapV3SingleTwapOracle(dualOracleAddress).setFraxUsdcTwapDuration(uint32(100));
    }
}
