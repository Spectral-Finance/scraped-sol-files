// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IAuctionManager.sol";
import "./interfaces/IEtherFiNode.sol";
import "./interfaces/IEtherFiNodesManager.sol";
import "./interfaces/IProtocolRevenueManager.sol";
import "./interfaces/IStakingManager.sol";
import "./EtherFiNode.sol";
import "./TNFT.sol";
import "./BNFT.sol";

contract EtherFiNodesManager is
    Initializable,
    IEtherFiNodesManager,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------
    uint64 public numberOfValidators;
    uint64 public nonExitPenaltyPrincipal;
    uint64 public nonExitPenaltyDailyRate; // in basis points
    uint64 public SCALE;

    address public treasuryContract;
    address public stakingManagerContract;
    address public DEPRECATED_protocolRevenueManagerContract;

    // validatorId == bidId -> withdrawalSafeAddress
    mapping(uint256 => address) public etherfiNodeAddress;

    TNFT public tnft;
    BNFT public bnft;
    IAuctionManager public auctionManager;
    IProtocolRevenueManager public DEPRECATED_protocolRevenueManager;

    //Holds the data for the revenue splits depending on where the funds are received from
    RewardsSplit public stakingRewardsSplit;
    RewardsSplit public DEPRECATED_protocolRewardsSplit;

    address public DEPRECATED_admin;
    mapping(address => bool) public admins;

    IEigenPodManager public eigenPodManager;
    IDelayedWithdrawalRouter public delayedWithdrawalRouter;
    // max number of queued eigenlayer withdrawals to attempt to claim in a single tx
    uint8 public maxEigenlayerWithdrawals;

    // stack of re-usable withdrawal safes to save gas
    address[] public unusedWithdrawalSafes;

    bool public enableNodeRecycling;


    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------
    event FundsWithdrawn(uint256 indexed _validatorId, uint256 amount);
    event NodeExitRequested(uint256 _validatorId);
    event NodeExitRequestReverted(uint256 _validatorId);
    event NodeExitProcessed(uint256 _validatorId);
    event NodeEvicted(uint256 _validatorId);
    event PhaseChanged(uint256 indexed _validatorId, IEtherFiNode.VALIDATOR_PHASE _phase);
    event WithdrawalSafeReset(uint256 indexed _validatorId, address indexed withdrawalSafeAddress);

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    error InvalidParams();
    error NonZeroAddress();

    /// @dev Sets the revenue splits on deployment
    /// @dev AuctionManager, treasury and deposit contracts must be deployed first
    /// @param _treasuryContract The address of the treasury contract for interaction
    /// @param _auctionContract The address of the auction contract for interaction
    /// @param _stakingManagerContract The address of the staking contract for interaction
    /// @param _tnftContract The address of the TNFT contract for interaction
    /// @param _bnftContract The address of the BNFT contract for interaction
    function initialize(
        address _treasuryContract,
        address _auctionContract,
        address _stakingManagerContract,
        address _tnftContract,
        address _bnftContract
    ) external initializer {
        if(_treasuryContract == address(0) || _auctionContract == address(0) || _stakingManagerContract == address(0) || _tnftContract == address(0) || _bnftContract == address(0)) revert NonZeroAddress();

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        SCALE = 1_000_000;

        treasuryContract = _treasuryContract;
        stakingManagerContract = _stakingManagerContract;

        auctionManager = IAuctionManager(_auctionContract);
        tnft = TNFT(_tnftContract);
        bnft = BNFT(_bnftContract);
    }

    function initializeOnUpgrade(address _etherFiAdmin, address _eigenPodManager, address _delayedWithdrawalRouter, uint8 _maxEigenlayerWithdrawals) public onlyOwner {
        admins[_etherFiAdmin] = true;
        eigenPodManager = IEigenPodManager(_eigenPodManager);
        delayedWithdrawalRouter = IDelayedWithdrawalRouter(_delayedWithdrawalRouter);
        maxEigenlayerWithdrawals = _maxEigenlayerWithdrawals;
    }

    error NotTnftOwner();
    error ValidatorNotLive();
    error ValidatorNotExited();

    /// @notice Send the request to exit the validator node
    /// @param _validatorId ID of the validator associated
    function sendExitRequest(uint256 _validatorId) public whenNotPaused {
        if(msg.sender != tnft.ownerOf(_validatorId)) revert NotTnftOwner();
        if(phase(_validatorId) != IEtherFiNode.VALIDATOR_PHASE.LIVE) revert ValidatorNotLive();
        address etherfiNode = etherfiNodeAddress[_validatorId];
        IEtherFiNode(etherfiNode).setExitRequestTimestamp(uint32(block.timestamp));

        emit NodeExitRequested(_validatorId);
    }

    /// @notice Send the request to exit multiple nodes
    /// @param _validatorIds IDs of the validators associated
    function batchSendExitRequest(uint256[] calldata _validatorIds) external whenNotPaused {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            sendExitRequest(_validatorIds[i]);
        }
    }

    function batchRevertExitRequest(uint256[] calldata _validatorIds) external onlyAdmin whenNotPaused {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            uint256 _validatorId = _validatorIds[i];

            if (phase(_validatorId) != IEtherFiNode.VALIDATOR_PHASE.LIVE) revert ValidatorNotLive();
            address etherfiNode = etherfiNodeAddress[_validatorId];
            IEtherFiNode(etherfiNode).setExitRequestTimestamp(0);

            emit NodeExitRequestReverted(_validatorId);
        }
    }

    /// @notice Once the node's exit is observed, the protocol calls this function to process their exits.
    /// @param _validatorIds The list of validators which exited
    /// @param _exitTimestamps The list of exit timestamps of the validators
    function processNodeExit(
        uint256[] calldata _validatorIds,
        uint32[] calldata _exitTimestamps
    ) external onlyAdmin nonReentrant whenNotPaused {
        if (_validatorIds.length != _exitTimestamps.length) revert InvalidParams();
        
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            _processNodeExit(_validatorIds[i], _exitTimestamps[i]);
        }
    }

    /// @notice queue a withdrawal of eth from an eigenPod. You must wait for the queuing period
    ///         defined by eigenLayer before you can finish the withdrawal via etherFiNode.claimQueuedWithdrawals()
    /// @param _validatorId The validator Id
    function queueRestakedWithdrawal(uint256 _validatorId) public whenNotPaused {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        IEtherFiNode(etherfiNode).queueRestakedWithdrawal();
    }

    /// @notice queue a withdrawal of eth from an eigenPod. You must wait for the queuing period
    ///         defined by eigenLayer before you can finish the withdrawal via etherFiNode.claimQueuedWithdrawals()
    /// @param _validatorIds The list of validators to queue withdrawals for
    function batchQueueRestakedWithdrawal(uint256[] calldata _validatorIds) external whenNotPaused {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            queueRestakedWithdrawal(_validatorIds[i]);
        }
    }

    /// @notice Process the rewards skimming
    /// @param _validatorId The validator Id
    function partialWithdraw(uint256 _validatorId) public nonReentrant whenNotPaused {
        address etherfiNode = etherfiNodeAddress[_validatorId];

        // sweep rewards from eigenPod if any queued withdrawals are ready to be claimed
        if (IEtherFiNode(etherfiNode).isRestakingEnabled()) {
            // claim any queued withdrawals that are ready
            IEtherFiNode(etherfiNode).claimQueuedWithdrawals(maxEigenlayerWithdrawals);
            // queue up an balance currently in the contract so they are ready to be swept in the future
            IEtherFiNode(etherfiNode).queueRestakedWithdrawal();
        }

        require(
            address(etherfiNode).balance < 8 ether,
            "Balance > 8 ETH. Exit the node."
        );
        require(
            IEtherFiNode(etherfiNode).phase() == IEtherFiNode.VALIDATOR_PHASE.LIVE || IEtherFiNode(etherfiNode).phase() == IEtherFiNode.VALIDATOR_PHASE.FULLY_WITHDRAWN,
            "Must be LIVE or FULLY_WITHDRAWN."
        );

        // Retrieve all possible rewards: {Staking, Protocol} rewards and the vested auction fee reward
        // 'beaconBalance == 32 ether' means there is no accrued staking rewards and no slashing penalties  
        (uint256 toOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury ) 
            = getRewardsPayouts(_validatorId, 32 ether);

        _distributePayouts(_validatorId, toTreasury, toOperator, toTnft, toBnft);
    }

    /// @notice Batch-process the rewards skimming
    /// @param _validatorIds A list of the validator Ids
    function partialWithdrawBatch(uint256[] calldata _validatorIds) external whenNotPaused{
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            partialWithdraw( _validatorIds[i]);
        }
    }

    /// @notice process the full withdrawal
    /// @dev This fullWithdrawal is allowed only after it's marked as EXITED.
    /// @dev EtherFi will be monitoring the status of the validator nodes and mark them EXITED if they do;
    /// @dev It is a point of centralization in Phase 1
    /// @param _validatorId the validator Id to withdraw from
    function fullWithdraw(uint256 _validatorId) public nonReentrant whenNotPaused{
        address etherfiNode = etherfiNodeAddress[_validatorId];

        if (IEtherFiNode(etherfiNode).isRestakingEnabled()) {
            // sweep rewards from eigenPod
            IEtherFiNode(etherfiNode).claimQueuedWithdrawals(maxEigenlayerWithdrawals);
            // require that all pending withdrawals have cleared
            require (!IEtherFiNode(etherfiNode).hasOutstandingEigenLayerWithdrawals(), "Must Claim Restaked Withdrawals");
        }

        (uint256 toOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) 
            = getFullWithdrawalPayouts(_validatorId);
        _setPhase(etherfiNode, _validatorId, IEtherFiNode.VALIDATOR_PHASE.FULLY_WITHDRAWN);

        _distributePayouts(_validatorId, toTreasury, toOperator, toTnft, toBnft);

        // automatically recycle this node if entire execution layer balance is withdrawn
        if (IEtherFiNode(etherfiNode).totalBalanceInExecutionLayer() == 0) {
            _recycleEtherFiNode(_validatorId);
        }

        // burn the tNFT and bNFT
        tnft.burnFromWithdrawal(_validatorId);
        bnft.burnFromWithdrawal(_validatorId);
    }

    /// @notice Process the full withdrawal for multiple validators
    /// @param _validatorIds The validator Ids
    function fullWithdrawBatch(uint256[] calldata _validatorIds) external whenNotPaused {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            fullWithdraw(_validatorIds[i]);
        }
    }

    function markBeingSlashed(
        uint256[] calldata _validatorIds
    ) external whenNotPaused onlyAdmin {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            address etherfiNode = etherfiNodeAddress[_validatorIds[i]];
            IEtherFiNode(etherfiNode).markBeingSlashed();

            emit PhaseChanged(_validatorIds[i], IEtherFiNode.VALIDATOR_PHASE.BEING_SLASHED);
        }
    }

    error CannotResetNodeWithBalance();

    /// @notice reset unused withdrawal safes so that future validators can save gas creating contracts
    /// @dev Only nodes that are CANCELLED or FULLY_WITHDRAWN can be reset for reuse
    function resetWithdrawalSafes(uint256[] calldata _validatorIds) external onlyAdmin {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            IEtherFiNode node = IEtherFiNode(etherfiNodeAddress[_validatorIds[i]]);

            // don't allow the node to be recycled if it is in the withrdawn state but still has a balance.
            if (node.phase() == IEtherFiNode.VALIDATOR_PHASE.FULLY_WITHDRAWN) {
                if (node.totalBalanceInExecutionLayer() > 0) {
                    revert CannotResetNodeWithBalance();
                }
            }

            // reset safe and add to unused stack for later re-use
            _recycleEtherFiNode(_validatorIds[i]);

        }
    }

    /// @dev create a new proxy instance of the etherFiNode withdrawal safe contract.
    /// @param _createEigenPod whether or not to create an associated eigenPod contract.
    function instantiateEtherFiNode(bool _createEigenPod) internal returns (address) {
        BeaconProxy proxy = new BeaconProxy(IStakingManager(stakingManagerContract).getEtherFiNodeBeacon(), "");
        EtherFiNode node = EtherFiNode(payable(proxy));
        node.initialize(address(this));
        if (_createEigenPod) {
            node.createEigenPod();
        }

        return address(node);
    }

    /// @dev pre-create withdrawal safe contracts so that future staking operations are cheaper.
    ///   This is just pre-paying the gas cost of instantiating EtherFiNode and EigenPod proxy instances
    /// @param _count How many instances to create
    /// @param _enableRestaking Whether or not to instantiate an associated eigenPod. (This can still be done later)
    function createUnusedWithdrawalSafe(uint256 _count, bool _enableRestaking) external returns (address[] memory) {
        address[] memory createdSafes = new address[](_count);
        for (uint256 i = 0; i < _count; i++) {

            // create safe and add to pool of unused safes
            address newNode = instantiateEtherFiNode(_enableRestaking);
            unusedWithdrawalSafes.push(newNode);
            createdSafes[i] = address(newNode);
        }
        return createdSafes;
    }

    error AlreadyInstalled();
    error NotInstalled();

    /// @notice Registers the validator ID for the EtherFiNode contract
    /// @param _validatorId ID of the validator associated to the node
    function registerEtherFiNode(uint256 _validatorId, bool _enableRestaking) external onlyStakingManagerContract returns (address) {
        if(etherfiNodeAddress[_validatorId] != address(0)) revert AlreadyInstalled();

        address withdrawalSafeAddress;

        // can I re-use an existing safe
        if (unusedWithdrawalSafes.length > 0 && enableNodeRecycling) {
            // pop
            withdrawalSafeAddress = unusedWithdrawalSafes[unusedWithdrawalSafes.length-1];
            unusedWithdrawalSafes.pop();
        } else {
            // make a new one
            withdrawalSafeAddress = instantiateEtherFiNode(_enableRestaking);
        }

        IEtherFiNode(withdrawalSafeAddress).recordStakingStart(_enableRestaking);
        etherfiNodeAddress[_validatorId] = withdrawalSafeAddress;

        emit PhaseChanged(_validatorId, IEtherFiNode(withdrawalSafeAddress).phase());
        return withdrawalSafeAddress;
    }

    /// @notice Unset the EtherFiNode contract for the validator ID
    /// @param _validatorId ID of the validator associated
    function unregisterEtherFiNode(uint256 _validatorId) external onlyStakingManagerContract {
        _recycleEtherFiNode(_validatorId);
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------------  SETTER   --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Sets the staking rewards split
    /// @notice Splits must add up to the SCALE of 1_000_000
    /// @param _treasury the split going to the treasury
    /// @param _nodeOperator the split going to the nodeOperator
    /// @param _tnft the split going to the tnft holder
    /// @param _bnft the split going to the bnft holder
    function setStakingRewardsSplit(uint64 _treasury, uint64 _nodeOperator, uint64 _tnft, uint64 _bnft)
        public onlyAdmin
    {
        if (_treasury + _nodeOperator + _tnft + _bnft != SCALE) revert InvalidParams();
        stakingRewardsSplit.treasury = _treasury;
        stakingRewardsSplit.nodeOperator = _nodeOperator;
        stakingRewardsSplit.tnft = _tnft;
        stakingRewardsSplit.bnft = _bnft;
    }

    error InvalidPenaltyRate();
    /// @notice Sets the Non Exit Penalty 
    /// @param _nonExitPenaltyPrincipal the new principal amount
    /// @param _nonExitPenaltyDailyRate the new non exit daily rate
    function setNonExitPenalty(uint64 _nonExitPenaltyDailyRate, uint64 _nonExitPenaltyPrincipal) public onlyAdmin {
        if(_nonExitPenaltyDailyRate > 10000) revert InvalidPenaltyRate();
        nonExitPenaltyPrincipal = _nonExitPenaltyPrincipal;
        nonExitPenaltyDailyRate = _nonExitPenaltyDailyRate;
    }


    /// @notice Sets the phase of the validator
    /// @param _validatorId id of the validator associated to this etherfi node
    /// @param _phase phase of the validator
    function setEtherFiNodePhase(uint256 _validatorId, IEtherFiNode.VALIDATOR_PHASE _phase) public onlyStakingManagerContract {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        _setPhase(etherfiNode, _validatorId, _phase);
    }

    /// @notice Sets the ipfs hash of the validator's encrypted private key
    /// @param _validatorId id of the validator associated to this etherfi node
    /// @param _ipfs ipfs hash
    function setEtherFiNodeIpfsHashForEncryptedValidatorKey(uint256 _validatorId, string calldata _ipfs) 
        external onlyStakingManagerContract {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        IEtherFiNode(etherfiNode).setIpfsHashForEncryptedValidatorKey(_ipfs);
    }

    /// @notice set maximum number of queued eigenlayer withdrawals that can be processed in 1 tx
    /// @param _max max number of queued withdrawals
    function setMaxEigenLayerWithdrawals(uint8 _max) external onlyAdmin {
        maxEigenlayerWithdrawals = _max;
    }

    /// @notice set whether newly spun up validators should use a previously recycled node (if available) to save gas
    function setEnableNodeRecycling(bool _enabled) external onlyAdmin {
        enableNodeRecycling = _enabled;
    }

    /// @notice Increments the number of validators by a certain amount
    /// @param _count how many new validators to increment by
    function incrementNumberOfValidators(uint64 _count) external onlyStakingManagerContract {
        numberOfValidators += _count;
    }

    /// @notice Updates the address of the admin
    /// @param _address the new address to set as admin
    function updateAdmin(address _address, bool _isAdmin) external onlyOwner {
        admins[_address] = _isAdmin;
    }

    //Pauses the contract
    function pauseContract() external onlyAdmin {
        _pause();
    }

    //Unpauses the contract
    function unPauseContract() external onlyAdmin {
        _unpause();
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Once the node's exit is observed, the protocol calls this function:
    ///         - mark it EXITED
    /// @param _validatorId the validator ID
    /// @param _exitTimestamp the exit timestamp
    function _processNodeExit(uint256 _validatorId, uint32 _exitTimestamp) internal {
        address etherfiNode = etherfiNodeAddress[_validatorId];

        // Mark EXITED
        IEtherFiNode(etherfiNode).markExited(_exitTimestamp);

        numberOfValidators -= 1;

        emit PhaseChanged(_validatorId, IEtherFiNode.VALIDATOR_PHASE.EXITED);

        emit NodeExitProcessed(_validatorId);
    }

    function _setPhase(address _node, uint256 _validatorId, IEtherFiNode.VALIDATOR_PHASE _phase) internal {
        IEtherFiNode(_node).setPhase(_phase);
        emit PhaseChanged(_validatorId, _phase);
    }

    function _recycleEtherFiNode(uint256 _validatorId) internal {
        address safeAddress = etherfiNodeAddress[_validatorId];
        if(safeAddress == address(0)) revert NotInstalled();

        // recycle the node
        IEtherFiNode(safeAddress).resetWithdrawalSafe();
        unusedWithdrawalSafes.push(etherfiNodeAddress[_validatorId]);

        emit PhaseChanged(_validatorId, IEtherFiNode.VALIDATOR_PHASE.READY_FOR_DEPOSIT);
        emit WithdrawalSafeReset(_validatorId, safeAddress);

        delete etherfiNodeAddress[_validatorId];
    }

    function _distributePayouts(uint256 _validatorId, uint256 _toTreasury, uint256 _toOperator, uint256 _toTnft, uint256 _toBnft) internal {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        IEtherFiNode(etherfiNode).withdrawFunds(
            treasuryContract, _toTreasury,
            auctionManager.getBidOwner(_validatorId), _toOperator,
            tnft.ownerOf(_validatorId), _toTnft,
            bnft.ownerOf(_validatorId), _toBnft
        );
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    //--------------------------------------------------------------------------------------
    //-------------------------------------  GETTER   --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Fetches the phase a specific node is in
    /// @param _validatorId id of the validator associated to etherfi node
    /// @return validatorPhase the phase the node is in
    function phase(uint256 _validatorId) public view returns (IEtherFiNode.VALIDATOR_PHASE validatorPhase) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        validatorPhase = IEtherFiNode(etherfiNode).phase();
    }

    /// @notice Fetches the ipfs hash for the encrypted key data from a specific node
    /// @param _validatorId id of the validator associated to etherfi node
    /// @return the ifs hash associated to the node
    function ipfsHashForEncryptedValidatorKey(uint256 _validatorId) external view returns (string memory) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        return IEtherFiNode(etherfiNode).ipfsHashForEncryptedValidatorKey();
    }

    /// @notice Generates withdraw credentials for a validator
    /// @param _address associated with the validator for the withdraw credentials
    /// @return the generated withdraw key for the node
    function generateWithdrawalCredentials(address _address) public pure returns (bytes memory) {   
        return abi.encodePacked(bytes1(0x01), bytes11(0x0), _address);
    }

    /// @notice get the length of the unusedWithdrawalSafes array
    function getUnusedWithdrawalSafesLength() external view returns (uint256) {
        return unusedWithdrawalSafes.length;
    }

    function getWithdrawalSafeAddress(uint256 _validatorId) public view returns (address) {
        address etherfiNode = etherfiNodeAddress[_validatorId];

        if (IEtherFiNode(etherfiNode).isRestakingEnabled()) {
            return IEtherFiNode(etherfiNode).eigenPod();
        } else {
            return etherfiNode;
        }
    }

    /// @notice Fetches the withdraw credentials for a specific node
    /// @param _validatorId id of the validator associated to etherfi node
    /// @return the generated withdraw key for the node
    function getWithdrawalCredentials(uint256 _validatorId) external view returns (bytes memory) {
        return generateWithdrawalCredentials(getWithdrawalSafeAddress(_validatorId));
    }

    /// @notice Fetches if the node has an exit request
    /// @param _validatorId id of the validator associated to etherfi node
    /// @return bool value based on if an exit request has been sent
    function isExitRequested(uint256 _validatorId) external view returns (bool) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        return IEtherFiNode(etherfiNode).exitRequestTimestamp() > 0;
    }

    /// @notice Fetches the nodes non exit penalty amount
    /// @param _validatorId id of the validator associated to etherfi node
    /// @return nonExitPenalty the amount of the penalty
    function getNonExitPenalty(uint256 _validatorId) public view returns (uint256 nonExitPenalty) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        uint32 tNftExitRequestTimestamp = IEtherFiNode(etherfiNode).exitRequestTimestamp();
        uint32 bNftExitRequestTimestamp = IEtherFiNode(etherfiNode).exitTimestamp();
        return IEtherFiNode(etherfiNode).getNonExitPenalty(tNftExitRequestTimestamp, bNftExitRequestTimestamp);
    }

    /// @notice Fetches the nodes exit timestamp
    function getExitTimestamp(uint256 _validatorId) public view returns (uint32) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        uint32 bNftExitRequestTimestamp = IEtherFiNode(etherfiNode).exitTimestamp();
        return bNftExitRequestTimestamp;
    }

    function getStakingStartTimestamp(uint256 _validatorId) public view returns (uint32) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        return IEtherFiNode(etherfiNode).stakingStartTimestamp();
    }

    /// @notice Fetches the claimable rewards payouts based on the accrued rewards
    // 
    /// Note that since the smart contract running in the execution layer does not know the consensus layer data
    /// such as the status and balance of the validator, 
    /// the partial withdrawal assumes that the validator is in active & not being slashed + the beacon balance is 32 ether.
    /// Therefore, you need to set _beaconBalance = 32 ether to see the same payouts for the partial withdrawal
    ///
    /// @param _validatorId ID of the validator associated to etherfi node
    /// @param _beaconBalance the balance of the validator in Consensus Layer
    /// @return toNodeOperator  the TVL for the Node Operator
    /// @return toTnft          the TVL for the T-NFT holder
    /// @return toBnft          the TVL for the B-NFT holder
    /// @return toTreasury      the TVL for the Treasury
    function getRewardsPayouts(
        uint256 _validatorId,
        uint256 _beaconBalance
    ) public view returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        return
            IEtherFiNode(etherfiNode).getStakingRewardsPayouts(
                _beaconBalance + etherfiNode.balance,
                stakingRewardsSplit,
                SCALE
            );
    }

    /// @notice Fetches the full withdraw payouts
    /// @param _validatorId id of the validator associated to etherfi node
    /// @return toNodeOperator  the TVL for the Node Operator
    /// @return toTnft          the TVL for the T-NFT holder
    /// @return toBnft          the TVL for the B-NFT holder
    /// @return toTreasury      the TVL for the Treasury
    function getFullWithdrawalPayouts(uint256 _validatorId) 
        public view returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) {
        if (phase(_validatorId) != IEtherFiNode.VALIDATOR_PHASE.EXITED) revert ValidatorNotExited();

        // The full withdrawal payouts should be equal to the total withdrawable TVL of the validator
        // 'beaconBalance' should be 0 since the validator must be in 'withdrawal_done' status
        // - it will get provably verified once we have EIP 4788
        return calculateWithdrawableTVL(_validatorId, 0);
    }

    /// @notice Compute the TVLs for {node operator, t-nft holder, b-nft holder, treasury}
    /// @param _validatorId id of the validator associated to etherfi node
    /// @param _beaconBalance the balance of the validator in Consensus Layer
    ///
    /// @return toNodeOperator  the TVL for the Node Operator
    /// @return toTnft          the TVL for the T-NFT holder
    /// @return toBnft          the TVL for the B-NFT holder
    /// @return toTreasury      the TVL for the Treasury
    function calculateTVL(
        uint256 _validatorId,
        uint256 _beaconBalance
    ) public view returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        uint256 executionBalance = IEtherFiNode(etherfiNode).totalBalanceInExecutionLayer();
        return  IEtherFiNode(etherfiNode).calculateTVL(
                    _beaconBalance,
                    executionBalance,
                    stakingRewardsSplit,
                    SCALE
                );
    }

    /// @notice Compute the withdrawable TVLs for {node operator, t-nft holder, b-nft holder, treasury}
    ///         This differs from calculateTVL() in the presence of restaking, where some funds
    ///         might not be immediately withdrawable due to eigenLayer's delayed withdrawal mechanism.
    ///         This method should be used when determining full withdrawal payouts
    /// @param _validatorId id of the validator associated to etherfi node
    /// @param _beaconBalance the balance of the validator in Consensus Layer
    ///
    /// @return toNodeOperator  the TVL for the Node Operator
    /// @return toTnft          the TVL for the T-NFT holder
    /// @return toBnft          the TVL for the B-NFT holder
    /// @return toTreasury      the TVL for the Treasury
    function calculateWithdrawableTVL(
        uint256 _validatorId,
        uint256 _beaconBalance
    ) public view returns (uint256 toNodeOperator, uint256 toTnft, uint256 toBnft, uint256 toTreasury) {
        address etherfiNode = etherfiNodeAddress[_validatorId];
        uint256 executionBalance = IEtherFiNode(etherfiNode).withdrawableBalanceInExecutionLayer();
        return  IEtherFiNode(etherfiNode).calculateTVL(
                    _beaconBalance,
                    executionBalance,
                    stakingRewardsSplit,
                    SCALE
                );
    }

    /// @notice return the eigenpod associated with the etherFiNode connected to the provided validator
    /// @dev The existence of a connected eigenpod does not imply the node is currently configured for restaking.
    ///      use isRestakingEnabled() instead
    function getEigenPod(uint256 _validatorId) public view returns (address) {
        IEtherFiNode etherfiNode = IEtherFiNode(etherfiNodeAddress[_validatorId]);
        return etherfiNode.eigenPod();
    }

    /// @notice return whether the provided validator is configured for restaknig via eigenLayer
    function isRestakingEnabled(uint256 _validatorId) public view returns (bool) {
        IEtherFiNode etherfiNode = IEtherFiNode(etherfiNodeAddress[_validatorId]);
        return etherfiNode.isRestakingEnabled();
    }

    /// @notice Fetches the address of the implementation contract currently being used by the proxy
    /// @return The address of the currently used implementation contract
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _requireAdmin() internal view virtual {
        require(admins[msg.sender], "Not admin");
    }

    function _onlyStakingManagerContract() internal view virtual {
        require(msg.sender == stakingManagerContract, "Not staking manager");
    }


    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyStakingManagerContract() {
        _onlyStakingManagerContract();
        _;
    }

    modifier onlyAdmin() {
        _requireAdmin();
        _;
    }
}
