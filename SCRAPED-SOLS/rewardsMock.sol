//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ILendingRewardsRateModel } from "../../../../contracts/protocols/lending/interfaces/iLendingRewardsRateModel.sol";
import { Structs as LendingRewardsRateModelStructs } from "../../../../contracts/protocols/lending/lendingRewardsRateModel/structs.sol";

contract LendingRewardsRateMockModel is ILendingRewardsRateModel {
    uint256 internal _rate;
    bool internal _ended;
    uint256 internal _startTime;

    function setRate(uint256 rate_) external {
        _rate = rate_;
    }

    function setStartTime(uint256 startTime_) external {
        _startTime = startTime_;
    }

    function setEnded(bool ended_) external {
        _ended = ended_;
    }

    /// @inheritdoc ILendingRewardsRateModel
    function getRate(uint256) public view returns (uint256, bool, uint256) {
        return (_rate, _ended, _startTime);
    }

    function getConfig() external pure returns (LendingRewardsRateModelStructs.Config memory) {
        revert("Not implemented");
    }
}
