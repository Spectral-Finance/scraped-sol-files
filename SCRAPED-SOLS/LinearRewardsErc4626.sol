// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== LinearRewardsErc4626 ======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

import { ERC20, ERC4626 } from "solmate/mixins/ERC4626.sol";
import { SafeCastLib } from "solmate/utils/SafeCastLib.sol";

/// @title LinearRewardsErc4626
/// @notice An ERC4626 Vault implementation with linear rewards
contract LinearRewardsErc4626 is ERC4626 {
    using SafeCastLib for *;

    /// @notice The precision of all integer calculations
    uint256 public constant PRECISION = 1e18;

    /// @notice The rewards cycle length in seconds
    uint256 public immutable REWARDS_CYCLE_LENGTH;

    /// @notice Information about the current rewards cycle
    struct RewardsCycleData {
        uint40 cycleEnd; // Timestamp of the end of the current rewards cycle
        uint40 lastSync; // Timestamp of the last time the rewards cycle was synced
        uint216 rewardCycleAmount; // Amount of rewards to be distributed in the current cycle
    }

    /// @notice The rewards cycle data, stored in a single word to save gas
    RewardsCycleData public rewardsCycleData;

    /// @notice The timestamp of the last time rewards were distributed
    uint256 public lastRewardsDistribution;

    /// @notice The total amount of assets that have been distributed and deposited
    uint256 public storedTotalAssets;

    /// @param _underlying The erc20 asset deposited
    /// @param _name The name of the vault
    /// @param _symbol The symbol of the vault
    /// @param _rewardsCycleLength The length of the rewards cycle in seconds
    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol,
        uint256 _rewardsCycleLength
    ) ERC4626(_underlying, _name, _symbol) {
        REWARDS_CYCLE_LENGTH = _rewardsCycleLength;

        // initialize rewardsCycleEnd value
        // NOTE: normally distribution of rewards should be done prior to _syncRewards but in this case we know there are no users or rewards yet.
        _syncRewards();

        // initialize lastRewardsDistribution value
        distributeRewards();
    }

    /// @notice The ```calculateRewardsToDistribute``` function calculates the amount of rewards to distribute based on the rewards cycle data and the time elapsed
    /// @param _rewardsCycleData The rewards cycle data
    /// @param _deltaTime The time elapsed since the last rewards distribution
    /// @return _rewardToDistribute The amount of rewards to distribute
    function calculateRewardsToDistribute(
        RewardsCycleData memory _rewardsCycleData,
        uint256 _deltaTime
    ) public view virtual returns (uint256 _rewardToDistribute) {
        _rewardToDistribute =
            (_rewardsCycleData.rewardCycleAmount * _deltaTime) /
            (_rewardsCycleData.cycleEnd - _rewardsCycleData.lastSync);
    }

    /// @notice The ```previewDistributeRewards``` function is used to preview the rewards distributed at the top of the block
    /// @return _rewardToDistribute The amount of underlying to distribute
    function previewDistributeRewards() public view virtual returns (uint256 _rewardToDistribute) {
        // Cache state for gas savings
        RewardsCycleData memory _rewardsCycleData = rewardsCycleData;
        uint256 _lastRewardsDistribution = lastRewardsDistribution;
        uint40 _timestamp = block.timestamp.safeCastTo40();

        // Calculate the delta time, but only include up to the cycle end in case we are passed it
        uint256 _deltaTime = _timestamp > _rewardsCycleData.cycleEnd
            ? _rewardsCycleData.cycleEnd - _lastRewardsDistribution
            : _timestamp - _lastRewardsDistribution;

        // Calculate the rewards to distribute
        _rewardToDistribute = calculateRewardsToDistribute({
            _rewardsCycleData: _rewardsCycleData,
            _deltaTime: _deltaTime
        });
    }

    /// @notice The ```distributeRewards``` function distributes the rewards once per block
    /// @return _rewardToDistribute The amount of underlying to distribute
    function distributeRewards() public virtual returns (uint256 _rewardToDistribute) {
        _rewardToDistribute = previewDistributeRewards();

        // Only write to state if we need to update
        if (_rewardToDistribute != 0) {
            storedTotalAssets += _rewardToDistribute;
        }

        lastRewardsDistribution = block.timestamp;

        emit DistributeRewards({ rewardsToDistribute: _rewardToDistribute });
    }

    /// @notice The ```previewSyncRewards``` function returns the updated rewards cycle data without updating the state
    /// @return _newRewardsCycleData The updated rewards cycle data
    function previewSyncRewards() public view virtual returns (RewardsCycleData memory _newRewardsCycleData) {
        RewardsCycleData memory _rewardsCycleData = rewardsCycleData;

        uint256 _timestamp = block.timestamp;

        // Only sync if the previous cycle has ended
        if (_timestamp <= _rewardsCycleData.cycleEnd) return _rewardsCycleData;

        // Calculate rewards for next cycle
        uint256 _newRewards = asset.balanceOf(address(this)) - storedTotalAssets;

        // Calculate the next cycle end, this keeps cycles at the same time regardless of when sync is called
        uint40 _cycleEnd = (((_timestamp + REWARDS_CYCLE_LENGTH) / REWARDS_CYCLE_LENGTH) * REWARDS_CYCLE_LENGTH)
            .safeCastTo40();

        // This block prevents big jumps in rewards rate in case the sync happens near the end of the cycle
        if (_cycleEnd - _timestamp < REWARDS_CYCLE_LENGTH / 20) {
            _cycleEnd += REWARDS_CYCLE_LENGTH.safeCastTo40();
        }

        // Write return values
        _rewardsCycleData.rewardCycleAmount = _newRewards.safeCastTo216();
        _rewardsCycleData.lastSync = _timestamp.safeCastTo40();
        _rewardsCycleData.cycleEnd = _cycleEnd;

        return _rewardsCycleData;
    }

    /// @notice The ```_syncRewards``` function is used to update the rewards cycle data
    function _syncRewards() internal virtual {
        RewardsCycleData memory _rewardsCycleData = previewSyncRewards();

        if (
            block
                .timestamp
                // If true, then preview shows a rewards should be processed
                .safeCastTo40() ==
            _rewardsCycleData.lastSync &&
            // Ensures that we don't write to state twice in the same block
            rewardsCycleData.lastSync != _rewardsCycleData.lastSync
        ) {
            rewardsCycleData = _rewardsCycleData;
            emit SyncRewards({
                cycleEnd: _rewardsCycleData.cycleEnd,
                lastSync: _rewardsCycleData.lastSync,
                rewardCycleAmount: _rewardsCycleData.rewardCycleAmount
            });
        }
    }

    /// @notice The ```syncRewardsAndDistribution``` function is used to update the rewards cycle data and distribute rewards
    /// @dev rewards must be distributed before the cycle is synced
    function syncRewardsAndDistribution() public virtual {
        distributeRewards();
        _syncRewards();
    }

    /// @notice The ```totalAssets``` function returns the total assets available in the vault
    /// @dev This function simulates the rewards that will be distributed at the top of the block
    /// @return _totalAssets The total assets available in the vault
    function totalAssets() public view virtual override returns (uint256 _totalAssets) {
        uint256 _rewardToDistribute = previewDistributeRewards();
        _totalAssets = storedTotalAssets + _rewardToDistribute;
    }

    function afterDeposit(uint256 amount, uint256 shares) internal virtual override {
        storedTotalAssets += amount;
    }

    /// @notice The ```deposit``` function allows a user to mint shares by depositing underlying
    /// @param _assets The amount of underlying to deposit
    /// @param _receiver The address to send the shares to
    /// @return _shares The amount of shares minted
    function deposit(uint256 _assets, address _receiver) public override returns (uint256 _shares) {
        distributeRewards();
        _syncRewards();
        _shares = super.deposit({ assets: _assets, receiver: _receiver });
    }

    /// @notice The ```mint``` function allows a user to mint a given number of shares
    /// @param _shares The amount of shares to mint
    /// @param _receiver The address to send the shares to
    /// @return _assets The amount of underlying deposited
    function mint(uint256 _shares, address _receiver) public override returns (uint256 _assets) {
        distributeRewards();
        _syncRewards();
        _assets = super.mint({ shares: _shares, receiver: _receiver });
    }

    function beforeWithdraw(uint256 amount, uint256 shares) internal virtual override {
        storedTotalAssets -= amount;
    }

    /// @notice The ```withdraw``` function allows a user to withdraw a given amount of underlying
    /// @param _assets The amount of underlying to withdraw
    /// @param _receiver The address to send the underlying to
    /// @param _owner The address of the owner of the shares
    /// @return _shares The amount of shares burned
    function withdraw(uint256 _assets, address _receiver, address _owner) public override returns (uint256 _shares) {
        distributeRewards();
        _syncRewards();
        _shares = super.withdraw({ assets: _assets, receiver: _receiver, owner: _owner });
    }

    /// @notice The ```redeem``` function allows a user to redeem their shares for underlying
    /// @param _shares The amount of shares to redeem
    /// @param _receiver The address to send the underlying to
    /// @param _owner The address of the owner of the shares
    /// @return _assets The amount of underlying redeemed
    function redeem(uint256 _shares, address _receiver, address _owner) public override returns (uint256 _assets) {
        distributeRewards();
        _syncRewards();
        _assets = super.redeem({ shares: _shares, receiver: _receiver, owner: _owner });
    }

    /// @notice The ```depositWithSignature``` function allows a user to use signed approvals to deposit
    /// @param _assets The amount of underlying to deposit
    /// @param _receiver The address to send the shares to
    /// @param _deadline The deadline for the signature
    /// @param _approveMax Whether or not to approve the maximum amount
    /// @param _v The v value of the signature
    /// @param _r The r value of the signature
    /// @param _s The s value of the signature
    /// @return _shares The amount of shares minted
    function depositWithSignature(
        uint256 _assets,
        address _receiver,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _shares) {
        uint256 _amount = _approveMax ? type(uint256).max : _assets;
        asset.permit({
            owner: msg.sender,
            spender: address(this),
            value: _amount,
            deadline: _deadline,
            v: _v,
            r: _r,
            s: _s
        });
        _shares = (deposit({ _assets: _assets, _receiver: _receiver }));
    }

    //==============================================================================
    // Events
    //==============================================================================

    /// @notice The ```SyncRewards``` event is emitted when the rewards cycle is synced
    /// @param cycleEnd The timestamp of the end of the current rewards cycle
    /// @param lastSync The timestamp of the last time the rewards cycle was synced
    /// @param rewardCycleAmount The amount of rewards to be distributed in the current cycle
    event SyncRewards(uint40 cycleEnd, uint40 lastSync, uint216 rewardCycleAmount);

    /// @notice The ```DistributeRewards``` event is emitted when rewards are distributed to storedTotalAssets
    /// @param rewardsToDistribute The amount of rewards that were distributed
    event DistributeRewards(uint256 rewardsToDistribute);
}
