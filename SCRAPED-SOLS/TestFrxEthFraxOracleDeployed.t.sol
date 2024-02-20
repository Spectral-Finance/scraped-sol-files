// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../abstracts/TestFraxOracle.sol";

contract TestFrxEthFraxOracleDeployed is TestFraxOracle {
    function _frxEthFraxOracleDeployedSetUp(uint256 _blockNumber) internal {
        console.log("scenario2: using eth mainnet deployed contract addresses");
        vm.createSelectFork(vm.envString("MAINNET_URL"), _blockNumber);

        priceSourceAddress = Constants.Mainnet.FRXETH_ETH_DUAL_ORACLE_ADDRESS;
        priceSource = IPriceSource(priceSourceAddress);

        fraxOracleAddress = Constants.Mainnet.FRXETH_FRAX_ORACLE_ADDRESS;
        fraxOracle = IFraxOracle(fraxOracleAddress);
    }

    function setUp() public virtual {
        _frxEthFraxOracleDeployedSetUp(blockNumber);
    }
}
