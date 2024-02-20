//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Structs as LendingRewardsRateModelStructs } from "../lendingRewardsRateModel/structs.sol";

interface ILendingRewardsRateModel {
    /// @notice Calculates the current rewards rate (APR)
    /// @param totalAssets_ amount of assets in the lending
    /// @return rate_ rewards rate percentage per year with 1e12 RATE_PRECISION, e.g. 1e12 = 1%, 1e14 = 100%
    /// @return ended_ flag to signal that rewards have ended (always 0 going forward)
    /// @return startTime_ start time of rewards to compare against last update timestamp
    function getRate(uint256 totalAssets_) external view returns (uint256 rate_, bool ended_, uint256 startTime_);

    /// @notice Returns current config for rewards rate model
    /// @return config_ represented by 'Config' struct
    function getConfig() external view returns (LendingRewardsRateModelStructs.Config memory config_);
}
