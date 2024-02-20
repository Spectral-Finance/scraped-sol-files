// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../abstracts/TestFraxOracle.sol";
import { deploySfrxEthEthDualOracle } from "script/deploy/DeploySfrxEthEthDualOracle.s.sol";
import { deploySfrxEthFraxOracle } from "script/deploy/DeploySfrxEthFraxOracle.s.sol";

contract TestSfrxEthFraxOracle is TestFraxOracle {
    function setUp() public {
        console.log("scenario1: using eth mainnet fork with deployment functions");
        vm.createSelectFork(vm.envString("MAINNET_URL"), blockNumber);

        (priceSourceAddress, , ) = deploySfrxEthEthDualOracle();
        priceSource = IPriceSource(priceSourceAddress);

        (fraxOracleAddress, , ) = deploySfrxEthFraxOracle(priceSourceAddress);
        fraxOracle = IFraxOracle(fraxOracleAddress);
    }
}
