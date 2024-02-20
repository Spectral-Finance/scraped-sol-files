// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IEtherFiNode.sol";
import "../eigenlayer-interfaces/IEigenPodManager.sol";
import "../eigenlayer-interfaces/IDelayedWithdrawalRouter.sol";

interface IEtherFiNodesManager {

    struct RewardsSplit {
        uint64 treasury;
        uint64 nodeOperator;
        uint64 tnft;
        uint64 bnft;
    }

    enum ValidatorRecipientType {
        TNFTHOLDER,
        BNFTHOLDER,
        TREASURY,
        OPERATOR
    }

    // VIEW functions
    function calculateTVL(uint256 _validatorId, uint256 _beaconBalance) external view returns (uint256, uint256, uint256, uint256);
    function calculateWithdrawableTVL(uint256 _validatorId, uint256 _beaconBalance) external view returns (uint256, uint256, uint256, uint256);
    function delayedWithdrawalRouter() external view returns (IDelayedWithdrawalRouter);
    function eigenPodManager() external view returns (IEigenPodManager);
    function generateWithdrawalCredentials(address _address) external view returns (bytes memory);
    function getFullWithdrawalPayouts(uint256 _validatorId) external view returns (uint256, uint256, uint256, uint256);
    function getNonExitPenalty(uint256 _validatorId) external view returns (uint256);
    function getRewardsPayouts(uint256 _validatorId, uint256 _beaconBalance) external view returns (uint256, uint256, uint256, uint256);
    function getWithdrawalCredentials(uint256 _validatorId) external view returns (bytes memory);
    function ipfsHashForEncryptedValidatorKey(uint256 _validatorId) external view returns (string memory);
    function nonExitPenaltyDailyRate() external view returns (uint64);
    function nonExitPenaltyPrincipal() external view returns (uint64);
    function numberOfValidators() external view returns (uint64);
    function phase(uint256 _validatorId) external view returns (IEtherFiNode.VALIDATOR_PHASE phase);

    // Non-VIEW functions
    function initialize(
        address _treasuryContract,
        address _auctionContract,
        address _stakingManagerContract,
        address _tnftContract,
        address _bnftContract
    ) external;

    function batchQueueRestakedWithdrawal(uint256[] calldata _validatorIds) external;
    function batchSendExitRequest(uint256[] calldata _validatorIds) external;
    function fullWithdrawBatch(uint256[] calldata _validatorIds) external;
    function fullWithdraw(uint256 _validatorId) external;
    function getUnusedWithdrawalSafesLength() external view returns (uint256);
    function incrementNumberOfValidators(uint64 _count) external;
    function markBeingSlashed(uint256[] calldata _validatorIds) external;
    function partialWithdrawBatch(uint256[] calldata _validatorIds) external;
    function partialWithdraw(uint256 _validatorId) external;
    function processNodeExit(uint256[] calldata _validatorIds, uint32[] calldata _exitTimestamp) external;
    function registerEtherFiNode(uint256 _validatorId, bool _enableRestaking) external returns (address);
    function sendExitRequest(uint256 _validatorId) external;
    function setEtherFiNodeIpfsHashForEncryptedValidatorKey(uint256 _validatorId, string calldata _ipfs) external;
    function setEtherFiNodePhase(uint256 _validatorId, IEtherFiNode.VALIDATOR_PHASE _phase) external;
    function setNonExitPenalty(uint64 _nonExitPenaltyDailyRate, uint64 _nonExitPenaltyPrincipal) external;
    function setStakingRewardsSplit(uint64 _treasury, uint64 _nodeOperator, uint64 _tnft, uint64 _bnf) external;
    function unregisterEtherFiNode(uint256 _validatorId) external;
    function updateAdmin(address _address, bool _isAdmin) external;
    function admins(address _address) external view returns (bool);
    function pauseContract() external;
    function unPauseContract() external;

    function treasuryContract() external view returns (address);
    function maxEigenlayerWithdrawals() external view returns (uint8);
}
