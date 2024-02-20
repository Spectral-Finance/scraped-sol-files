// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// Common interface for the Trove Manager.
interface ITroveManager {
    // --- Functions ---

    function setAddresses(
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _collateralTokenAddress
    ) external;

    function borrowerOperationsAddress() external view returns (address);

    function stabilityPool() external view returns (address);

    function debtToken() external view returns (address);

    function sortedTroves() external view returns (address);

    function collateralToken() external view returns (address);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingCollateralReward(address _borrower) external view returns (uint);

    function getPendingDebtReward(address _borrower) external view returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(
        address _borrower
    ) external view returns (uint debt, uint coll, uint pendingDebtReward, uint pendingCollateralReward);

    function openTrove(
        address _borrower,
        uint256 _collateralAmount,
        uint256 _compositeDebt,
        uint NICR,
        address _upperHint,
        address _lowerHint
    ) external returns (uint stake, uint arrayIndex);

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);

    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _collateralDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint debt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _debt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);

    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveCollAndDebt(address _borrower) external view returns (uint, uint);

    function updateTroveFromAdjustment(
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    ) external returns (uint, uint, uint);

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);

    function defaultedCollateral() external view returns (uint256);

    function defaultedDebt() external view returns (uint256);

    function getEntireSystemColl() external view returns (uint);

    function getEntireSystemDebt() external view returns (uint);

    function getEntireSystemBalances() external returns (uint, uint, uint);

    function sendSurplusCollateral(address _account, address _receiver) external;

    function sendCollateral(address _account, uint _amount) external;

    function increaseDebt(uint _amount) external;

    function decreaseDebt(uint _amount) external;

    function notifyReceiveCollateral(uint _amount) external;

    function collectInterests() external;

    function setParameters(
        uint _minuteDecayFactor,
        uint _redemptionFeeFloor,
        uint _maxRedemptionFee,
        uint _borrowingFeeFloor,
        uint _maxBorrowingFee,
        uint _interestRateInBPS,
        uint _maxSystemDebt
    ) external;

    function startCollateralSunset() external;

    function priceFeed() external view returns (address);

    function movePendingTroveRewardsToActiveBalances(uint _debt, uint _collateral) external;

    function updateBalances() external;

    function sunsetting() external view returns (bool);

    function fetchPrice() external returns (uint);

    function updateSystemSnapshots_excludeCollRemainder(uint _collRemainder) external;

    function addCollateralSurplus(address borrower, uint collSurplus) external;

    function redistributeDebtAndColl(uint _debt, uint _coll, uint collSurplus) external;

    function sendGasCompensation(address _liquidator, uint _debt, uint _collateral) external;

    function closeTroveByLiquidation(address _borrower) external;
}
