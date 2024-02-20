// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../abstracts/TestFraxOracle.sol";

contract TestSfrxEthFraxOracleDeployed is TestFraxOracle {
    function setUp() public {
        console.log("scenario2: using eth mainnet deployed contract addresses");
        vm.createSelectFork(vm.envString("MAINNET_URL"), blockNumber);

        priceSourceAddress = Constants.Mainnet.SFRXETH_ETH_DUAL_ORACLE_ADDRESS;
        priceSource = IPriceSource(priceSourceAddress);

        fraxOracleAddress = Constants.Mainnet.SFRXETH_FRAX_ORACLE_ADDRESS;
        fraxOracle = IFraxOracle(fraxOracleAddress);
    }
}
