// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { ILiquidityLogic, ILiquidityAdmin } from "./interfaces/iLiquidity.sol";
import { Structs as AdminModuleStructs } from "./adminModule/structs.sol";

/// @notice Liquidity dummy implementation used for Fluid Liquidity infinite proxy.
/// @dev see https://github.com/Instadapp/infinite-proxy?tab=readme-ov-file#dummy-implementation
contract LiquidityDummyImpl is ILiquidityLogic {
    /// @inheritdoc ILiquidityAdmin
    function updateAuths(AdminModuleStructs.AddressBool[] calldata authsStatus_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateGuardians(AdminModuleStructs.AddressBool[] calldata guardiansStatus_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateRevenueCollector(address revenueCollector_) external {}

    /// @inheritdoc ILiquidityAdmin
    function changeStatus(uint256 newStatus_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateRateDataV1s(AdminModuleStructs.RateDataV1Params[] calldata tokensRateData_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateRateDataV2s(AdminModuleStructs.RateDataV2Params[] calldata tokensRateData_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateTokenConfigs(AdminModuleStructs.TokenConfig[] calldata tokenConfigs_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateUserClasses(AdminModuleStructs.AddressUint256[] calldata userClasses_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateUserSupplyConfigs(AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateUserBorrowConfigs(AdminModuleStructs.UserBorrowConfig[] memory userBorrowConfigs_) external {}

    /// @inheritdoc ILiquidityAdmin
    function pauseUser(address user_, address[] calldata supplyTokens_, address[] calldata borrowTokens_) external {}

    /// @inheritdoc ILiquidityAdmin
    function unpauseUser(address user_, address[] calldata supplyTokens_, address[] calldata borrowTokens_) external {}

    /// @inheritdoc ILiquidityAdmin
    function collectRevenue(address[] calldata tokens_) external {}

    /// @inheritdoc ILiquidityAdmin
    function updateExchangePrices(
        address[] calldata tokens_
    ) external returns (uint256[] memory supplyExchangePrices_, uint256[] memory borrowExchangePrices_) {}

    /// @inheritdoc ILiquidityLogic
    function operate(
        address token_,
        int256 supplyAmount_,
        int256 borrowAmount_,
        address withdrawTo_,
        address borrowTo_,
        bytes calldata callbackData_
    ) external payable returns (uint256 memVar3_, uint256 memVar4_) {}
}
