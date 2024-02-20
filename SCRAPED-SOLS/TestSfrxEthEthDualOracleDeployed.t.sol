// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./TestSfrxEthEthDualOracle.t.sol";

contract TestSfrxEthEthDualOracleDeployed is TestSfrxEthEthDualOracle {
    function setUp() public override {
        console.log("scenario2: using eth mainnet deployed contract addresses");
        vm.createSelectFork(vm.envString("MAINNET_URL"), blockNumber);
        dualOracleAddress = Constants.Mainnet.FRXETH_ETH_DUAL_ORACLE_ADDRESS;
        dualOracle = IDualOracle(dualOracleAddress);
        localOracle = FrxEthEthDualOracle(dualOracleAddress);
        ORACLE_PRECISION = dualOracle.ORACLE_PRECISION();

        sfrxEthDualOracleAddress = Constants.Mainnet.SFRXETH_ETH_DUAL_ORACLE_ADDRESS;
        sfrxEthDualOracle = IDualOracle(sfrxEthDualOracleAddress);
        sfrxEthLocalOracle = SfrxEthEthDualOracle(dualOracleAddress);
        SFRXETH_ORACLE_PRECISION = sfrxEthDualOracle.ORACLE_PRECISION();
    }
}
