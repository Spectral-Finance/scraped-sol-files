// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { AddressAliasHelper } from "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import { ArbitrumBlockHashProvider } from "src/frax-oracle/providers/ArbitrumBlockHashProvider.sol";
import { ArbitrumBlockHashRelay } from "src/frax-oracle/relays/ArbitrumBlockHashRelay.sol";
import { StateRootOracle } from "src/frax-oracle/StateRootOracle.sol";
import { MerkleProofPriceSource } from "src/frax-oracle/MerkleProofPriceSource.sol";
import { IBlockHashProvider } from "src/frax-oracle/interfaces/IBlockHashProvider.sol";
import "./TestFrxEthFraxOracleDeployed.t.sol";
import { MockInbox } from "./MockInbox.sol";
import { deployArbitrumBlockHashProvider } from "script/deploy/arbitrum/DeployArbitrumBlockHashProvider.s.sol";
import { deployArbitrumBlockHashRelay } from "script/deploy/DeployArbitrumBlockHashRelay.s.sol";
import { deployStateRootOracle } from "script/deploy/arbitrum/DeployStateRootOracle.s.sol";
import { deployMerkleProofPriceSource } from "script/deploy/arbitrum/DeployMerkleProofPriceSource.s.sol";
import { deployFrxEthFraxOracle } from "script/deploy/DeployFrxEthFraxOracle.s.sol";
import { deploySfrxEthFraxOracle } from "script/deploy/DeploySfrxEthFraxOracle.s.sol";
import { IStateRootOracle } from "src/frax-oracle/interfaces/IStateRootOracle.sol";

contract TestArbitrumL2FrxEthFraxOracle is TestFrxEthFraxOracleDeployed {
    address public blockHashProviderAddress;
    ArbitrumBlockHashProvider public blockHashProvider;

    address public inboxAddress;
    MockInbox public inbox;

    address public blockHashRelayAddress;
    ArbitrumBlockHashRelay public blockHashRelay;

    address public stateRootOracleAddress;
    StateRootOracle public stateRootOracle;

    address public merkleProofPriceSourceAddress;
    MerkleProofPriceSource public merkleProofPriceSource;

    address public frxEthFraxOracleLayer2Address;
    IFraxOracle public frxEthFraxOracleLayer2;

    address public sfrxEthFraxOracleLayer2Address;
    IFraxOracle public sfrxEthFraxOracleLayer2;

    address public fraxOracleLayer2Address;
    IFraxOracle public fraxOracleLayer2;

    uint256 blockAfterProof = 17_661_610;

    function setUp() public virtual override {
        _frxEthFraxOracleDeployedSetUp(blockAfterProof);
        _deployL2FraxOracle();

        MerkleProofPriceSource.OraclePair[] memory ops = new MerkleProofPriceSource.OraclePair[](1);
        ops[0] = MerkleProofPriceSource.OraclePair({
            layer1FraxOracle: fraxOracleAddress,
            layer2FraxOracle: frxEthFraxOracleLayer2Address
        });
        hoax(Constants.Arbitrum.TIMELOCK_ADDRESS);
        merkleProofPriceSource.addOraclePairs(ops);
    }

    function _deployL2FraxOracle() internal {
        // deploy provider on l2
        (blockHashProviderAddress, , ) = deployArbitrumBlockHashProvider();
        blockHashProvider = ArbitrumBlockHashProvider(blockHashProviderAddress);

        // MockInbox acts as the message passing from L1 to "L2"
        inboxAddress = address(new MockInbox());
        inbox = MockInbox(inboxAddress);

        // deploy relay on l1
        (blockHashRelayAddress, , ) = deployArbitrumBlockHashRelay({
            layer2TargetProvider: blockHashProviderAddress,
            inbox: inboxAddress
        });
        blockHashRelay = ArbitrumBlockHashRelay(blockHashRelayAddress);

        // initialize on provider on "L2"
        blockHashProvider.initialize(blockHashRelayAddress);

        // deploy state root oracle on "L2"
        IBlockHashProvider[] memory providers = new IBlockHashProvider[](1);
        providers[0] = IBlockHashProvider(blockHashProviderAddress);

        (stateRootOracleAddress, , ) = deployStateRootOracle({ providers: providers, minimumRequiredProviders: 1 });
        stateRootOracle = StateRootOracle(stateRootOracleAddress);

        // deploy MerkleProofPriceSource on "L2"
        (merkleProofPriceSourceAddress, , ) = deployMerkleProofPriceSource({ stateRootOracle: stateRootOracleAddress });
        merkleProofPriceSource = MerkleProofPriceSource(merkleProofPriceSourceAddress);

        // deploy "L2" frxEth Oracle
        (frxEthFraxOracleLayer2Address, , ) = deployFrxEthFraxOracle(merkleProofPriceSourceAddress);
        frxEthFraxOracleLayer2 = IFraxOracle(frxEthFraxOracleLayer2Address);

        // deploy "L2" sfrxEth Oracle
        (sfrxEthFraxOracleLayer2Address, , ) = deploySfrxEthFraxOracle(merkleProofPriceSourceAddress);
        sfrxEthFraxOracleLayer2 = IFraxOracle(sfrxEthFraxOracleLayer2Address);

        fraxOracleLayer2Address = frxEthFraxOracleLayer2Address;
        fraxOracleLayer2 = frxEthFraxOracleLayer2;
    }

    function test_ProviderInitializeCallerNotDeployer() public {
        hoax(address(123));
        vm.expectRevert(ArbitrumBlockHashProvider.Unauthorized.selector);
        blockHashProvider.initialize(blockHashRelayAddress);
    }

    function test_ProviderAlreadyInitialized() public {
        vm.expectRevert(ArbitrumBlockHashProvider.AlreadyInitialized.selector);
        blockHashProvider.initialize(blockHashRelayAddress);
    }

    function test_ProviderReceiveBlockHashWrongSource() public {
        bytes32 _blockHash = blockhash(block.number);
        vm.expectRevert(ArbitrumBlockHashProvider.WrongSourceRelay.selector);
        blockHashProvider.receiveBlockHash(_blockHash);
    }

    function test_ProviderReceiveBlockHash() public {
        bytes32 _blockHash = blockhash(block.number);

        hoax(AddressAliasHelper.applyL1ToL2Alias(blockHashRelayAddress));
        blockHashProvider.receiveBlockHash(_blockHash);

        assertTrue(blockHashProvider.blockHashStored(_blockHash));
        assertFalse(blockHashProvider.blockHashStored(hex"1234"));
    }

    function test_RelayRelayHash() public {
        vm.warp(block.number + 256);

        uint256 _blockNumber = block.number - 256;
        bytes32 _blockHash = blockhash(_blockNumber);

        blockHashRelay.relayBlockHash{ value: 1 }({
            _blockNumber: _blockNumber,
            _maxSubmissionCost: 0,
            _gasLimit: 0,
            _maxFeePerGas: 0
        });

        assertTrue(blockHashProvider.blockHashStored(_blockHash));
    }

    function test_RelayRelayHashInvalidBlockNumber() public {
        vm.warp(block.number + 256);

        // too far back is not valid
        vm.expectRevert(ArbitrumBlockHashRelay.InvalidBlockNumber.selector);
        blockHashRelay.relayBlockHash{ value: 1 }({
            _blockNumber: block.number - 257,
            _maxSubmissionCost: 0,
            _gasLimit: 0,
            _maxFeePerGas: 0
        });

        // current block is not valid either
        vm.expectRevert(ArbitrumBlockHashRelay.InvalidBlockNumber.selector);
        blockHashRelay.relayBlockHash{ value: 1 }({
            _blockNumber: block.number,
            _maxSubmissionCost: 0,
            _gasLimit: 0,
            _maxFeePerGas: 0
        });
    }

    function test_StateRootAddProvider() public {
        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        stateRootOracle.addProvider(IBlockHashProvider(address(123)));

        assertEq(stateRootOracle.getBlockHashProvidersCount(), 2, "New provider added");
    }

    function test_StateRootAddProviderNotTimelock() public {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        stateRootOracle.addProvider(IBlockHashProvider(address(123)));
    }

    function test_StateRootAddProviderAlreadyAdded() public {
        vm.expectRevert(StateRootOracle.ProviderAlreadyAdded.selector);
        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        stateRootOracle.addProvider(IBlockHashProvider(blockHashProviderAddress));
    }

    function test_StateRootRemoveProvider() public {
        test_StateRootAddProvider();

        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        stateRootOracle.removeProvider(IBlockHashProvider(blockHashProviderAddress));

        assertEq(stateRootOracle.getBlockHashProvidersCount(), 1, "1 remaining providers");
    }

    function test_StateRootRemoveProviderNotTimelock() public {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        stateRootOracle.removeProvider(IBlockHashProvider(address(123)));
    }

    function test_StateRootRemoveProviderAlreadyRemoved() public {
        test_StateRootAddProvider();

        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        vm.expectRevert(StateRootOracle.ProviderNotFound.selector);
        stateRootOracle.removeProvider(IBlockHashProvider(address(321)));
    }

    function test_StateRootSetMinRequiredProviders() public {
        uint256 newValue = stateRootOracle.minimumRequiredProviders() + 1;

        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        stateRootOracle.setMinimumRequiredProviders(newValue);

        assertEq(newValue, stateRootOracle.minimumRequiredProviders());
    }

    function test_StateRootSetMinRequiredProvidersNotTimelock() public {
        uint256 currentValue = stateRootOracle.minimumRequiredProviders();
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        stateRootOracle.setMinimumRequiredProviders(currentValue);
    }

    function test_StateRootSetMinRequiredProvidersSameValue() public {
        uint256 currentValue = stateRootOracle.minimumRequiredProviders();

        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        vm.expectRevert(StateRootOracle.SameMinimumRequiredProviders.selector);
        stateRootOracle.setMinimumRequiredProviders(currentValue);
    }

    function test_StateRootSetMinRequiredProvidersZeroReverts() public {
        vm.prank(Constants.Arbitrum.TIMELOCK_ADDRESS);
        vm.expectRevert(StateRootOracle.MinimumRequiredProvidersTooLow.selector);
        stateRootOracle.setMinimumRequiredProviders(0);
    }

    function test_MerkleProofAddOraclePairsWrongMsgSender() public {
        MerkleProofPriceSource.OraclePair[] memory ops = new MerkleProofPriceSource.OraclePair[](1);
        ops[0] = MerkleProofPriceSource.OraclePair({ layer1FraxOracle: address(0), layer2FraxOracle: address(0) });

        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        merkleProofPriceSource.addOraclePairs(ops);
    }

    function test_MerkleProofAddOraclePairsOraclePairAlreadySet() public {
        MerkleProofPriceSource.OraclePair[] memory ops = new MerkleProofPriceSource.OraclePair[](1);
        ops[0] = MerkleProofPriceSource.OraclePair({
            layer1FraxOracle: fraxOracleAddress,
            layer2FraxOracle: fraxOracleLayer2Address
        });

        hoax(Constants.Arbitrum.TIMELOCK_ADDRESS);
        vm.expectRevert(
            abi.encodeWithSelector(
                MerkleProofPriceSource.OraclePairAlreadySet.selector,
                fraxOracleAddress,
                fraxOracleLayer2Address
            )
        );
        merkleProofPriceSource.addOraclePairs(ops);
    }

    function test_MerkleProofAddRoundDataNotInitialized() public {
        // deploy MerkleProofPriceSource on "L2"
        (address _merkleProofPriceSourceAddress, , ) = deployMerkleProofPriceSource({
            stateRootOracle: stateRootOracleAddress
        });
        MerkleProofPriceSource _merkleProofPriceSource = MerkleProofPriceSource(_merkleProofPriceSourceAddress);

        bytes[] memory a;
        bytes[] memory b;
        vm.expectRevert(MerkleProofPriceSource.WrongOracleAddress.selector);
        _merkleProofPriceSource.addRoundData(IPriceSourceReceiver(fraxOracleLayer2Address), 0, 0, a, b);
    }

    function test_MerkleProofAddRoundDataWrongOracleAddress() public {
        bytes[] memory a;
        bytes[] memory b;
        vm.expectRevert(MerkleProofPriceSource.WrongOracleAddress.selector);
        merkleProofPriceSource.addRoundData(IPriceSourceReceiver(address(122_345)), 0, 0, a, b);
    }

    function test_MerkleProofEndToEnd() public {
        uint256 _proofBlockNumber = blockAfterProof - 1;
        bytes memory _blockHeader = _getBlockByNumber(_proofBlockNumber);

        // relay to provider
        blockHashRelay.relayBlockHash{ value: 0 }({
            _blockNumber: _proofBlockNumber,
            _maxSubmissionCost: 0,
            _gasLimit: 0,
            _maxFeePerGas: 0
        });

        stateRootOracle.proveStateRoot(_blockHeader);

        // Can't overwrite existing state root proof
        vm.expectRevert(
            abi.encodeWithSelector(StateRootOracle.StateRootAlreadyProvenForBlockNumber.selector, _proofBlockNumber)
        );
        stateRootOracle.proveStateRoot(_blockHeader);

        IStateRootOracle.BlockInfo memory _blockInfo = stateRootOracle.getBlockInfo(_proofBlockNumber);
        assert(_blockInfo.stateRootHash != 0);

        (bytes32 _stateRootHash, uint40 _timestamp) = stateRootOracle.blockNumberToBlockInfo(_proofBlockNumber);
        assert(_blockInfo.stateRootHash == _stateRootHash);
        assert(_blockInfo.timestamp == _timestamp);

        (bytes[] memory _accountProof, bytes[] memory _storageProof) = _getProof(_proofBlockNumber);

        merkleProofPriceSource.addRoundData(
            IPriceSourceReceiver(fraxOracleLayer2Address),
            _proofBlockNumber,
            fraxOracle.lastCorrectRoundId(),
            _accountProof,
            _storageProof
        );

        // Assert price data equivalence between L1 and L2 Frax Oracles
        {
            (
                uint80 roundIdL1,
                int256 answerL1,
                uint256 startedAtL1,
                uint256 updatedAtL1,
                uint80 answeredInRoundL1
            ) = fraxOracle.latestRoundData();
            (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = fraxOracleLayer2.latestRoundData();

            assertTrue(
                roundIdL1 != roundId,
                "They are not equal in this test but it is possible (and unlikely) for them to be in prod"
            );
            assertTrue(
                answeredInRoundL1 != answeredInRound,
                "They are not equal in this test but it is possible (and unlikely) for them to be in prod"
            );
            assertEq(answerL1, answer, "Point of proof system is for these to be identical");
            assertEq(startedAtL1, startedAt, "Point of proof system is for these to be identical");
            assertEq(updatedAtL1, updatedAt, "Point of proof system is for these to be identical");
        }

        {
            (bool _isBadDataL1, uint256 _priceLowL1, uint256 _priceHighL1) = fraxOracle.getPrices();
            (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = fraxOracleLayer2.getPrices();

            assertEq(_isBadDataL1, _isBadData, "Point of proof system is for these to be identical");
            assertEq(_priceLowL1, _priceLow, "Point of proof system is for these to be identical");
            assertEq(_priceHighL1, _priceHigh, "Point of proof system is for these to be identical");
        }

        uint256 _roundId = fraxOracle.lastCorrectRoundId();

        // Can't add same price data twice
        vm.expectRevert(FraxOracle.CalledWithTimestampBeforePreviousRound.selector);
        merkleProofPriceSource.addRoundData(
            IPriceSourceReceiver(fraxOracleLayer2Address),
            _proofBlockNumber,
            _roundId,
            _accountProof,
            _storageProof
        );
    }

    // These tests fail because we're at a later block number than the tests we inherit.
    // These are already rigorously tested so we can just ignore them.

    function testAddRoundDataCalledWithTimestampBeforePreviousRoundRevert() public override {}

    function testAddRoundDataLastRoundIdNotUpdated() public override {}

    function testAddRoundDataLastRoundIdUpdated() public override {}

    function testGetLatestRoundDataNoPriceDataRevert() public override {}

    function testGetPricesHitMaximumOracleDelay() public override {}

    function testGetPricesNoPriceDataRevert() public override {}

    function testGetRoundDataNoPriceDataRevert() public override {}

    // ffi helpers

    function _getProof(
        uint256 _blockNumber
    ) internal returns (bytes[] memory _accountProof, bytes[] memory _storageProof) {
        string[] memory cmds = new string[](6);
        cmds[0] = "node";
        cmds[1] = "test/utils/getProof.js";
        cmds[2] = vm.toString(fraxOracleAddress);
        cmds[3] = vm.toString(_blockNumber);
        cmds[4] = vm.toString(
            merkleProofPriceSource.FRAX_ORACLE_LAYER_1_ROUNDS_STORAGE_SLOT() + fraxOracle.lastCorrectRoundId()
        );
        cmds[5] = vm.envString("MAINNET_URL");

        bytes memory res = vm.ffi(cmds);
        (_accountProof, _storageProof) = abi.decode(res, (bytes[], bytes[]));
    }

    function _getBlockByNumber(uint256 _blockNumber) internal returns (bytes memory _blockHeader) {
        string[] memory cmds = new string[](4);
        cmds[0] = "node";
        cmds[1] = "test/utils/getBlockHeaderInfo.js";
        cmds[2] = vm.toString(_blockNumber);
        cmds[3] = vm.envString("MAINNET_URL");

        _blockHeader = vm.ffi(cmds);
    }
}
