// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./TestArbitrumL2FrxEthFraxOracle.t.sol";

contract TestArbitrumL2SfrxEthFraxOracle is TestArbitrumL2FrxEthFraxOracle {
    function setUp() public virtual override {
        console.log("scenario2: using eth mainnet deployed contract addresses");
        vm.createSelectFork(vm.envString("MAINNET_URL"), blockAfterProof);

        priceSourceAddress = Constants.Mainnet.SFRXETH_ETH_DUAL_ORACLE_ADDRESS;
        priceSource = IPriceSource(priceSourceAddress);

        fraxOracleAddress = Constants.Mainnet.SFRXETH_FRAX_ORACLE_ADDRESS;
        fraxOracle = IFraxOracle(fraxOracleAddress);

        _deployL2FraxOracle();

        MerkleProofPriceSource.OraclePair[] memory ops = new MerkleProofPriceSource.OraclePair[](1);
        ops[0] = MerkleProofPriceSource.OraclePair({
            layer1FraxOracle: fraxOracleAddress,
            layer2FraxOracle: sfrxEthFraxOracleLayer2Address
        });
        hoax(Constants.Arbitrum.TIMELOCK_ADDRESS);
        merkleProofPriceSource.addOraclePairs(ops);

        // override from _deployL2FraxOracle;
        fraxOracleLayer2Address = sfrxEthFraxOracleLayer2Address;
        fraxOracleLayer2 = sfrxEthFraxOracleLayer2;
    }
}
