// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../abstracts/TestFraxOracle.sol";
import { deployFrxEthEthDualOracle } from "script/deploy/DeployFrxEthEthDualOracle.s.sol";
import { deployFrxEthFraxOracle } from "script/deploy/DeployFrxEthFraxOracle.s.sol";

contract TestFrxEthFraxOracle is TestFraxOracle {
    function setUp() public virtual {
        _testFrxEthFraxOracleSetUp(blockNumber);
    }

    function _testFrxEthFraxOracleSetUp(uint256 _blockNumber) internal {
        console.log("scenario1: using eth mainnet fork with deployment functions");
        vm.createSelectFork(vm.envString("MAINNET_URL"), _blockNumber);

        (priceSourceAddress, , ) = deployFrxEthEthDualOracle();
        priceSource = IPriceSource(priceSourceAddress);

        (fraxOracleAddress, , ) = deployFrxEthFraxOracle(priceSourceAddress);
        fraxOracle = IFraxOracle(fraxOracleAddress);
    }
}
