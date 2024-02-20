//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ILiquidity } from "../../../liquidity/interfaces/iLiquidity.sol";
import { IAllowanceTransfer } from "../../../protocols/lending/interfaces/permit2/iAllowanceTransfer.sol";
import { ILendingFactory } from "../../../protocols/lending/interfaces/iLendingFactory.sol";
import { ILendingRewardsRateModel } from "../../../protocols/lending/interfaces/iLendingRewardsRateModel.sol";
import { IIToken } from "../../../protocols/lending/interfaces/iIToken.sol";
import { Structs as LendingRewardsRateModelStructs } from "../../../protocols/lending/lendingRewardsRateModel/structs.sol";
import { Structs } from "./structs.sol";
import { ILiquidityResolver } from "../../../periphery/resolvers/liquidity/iLiquidityResolver.sol";

interface ILendingResolver {
    /// @notice returns the lending factory address
    function LENDING_FACTORY() external view returns (ILendingFactory);

    /// @notice returns the liquidity resolver address
    function LIQUIDITY_RESOLVER() external view returns (ILiquidityResolver);

    /// @notice returns all iToken types at the `LENDING_FACTORY`
    function getAllITokenTypes() external view returns (string[] memory);

    /// @notice returns all created iTokens at the `LENDING_FACTORY`
    function getAllITokens() external view returns (address[] memory);

    /// @notice reads if a certain `auth_` address is an allowed auth or not. Owner is auth by default.
    function isLendingFactoryAuth(address auth_) external view returns (bool);

    /// @notice reads if a certain `deployer_` address is an allowed deployer or not. Owner is deployer by default.
    function isLendingFactoryDeployer(address deployer_) external view returns (bool);

    /// @notice computes deterministic token address for `asset_` for a lending protocol
    /// @param  asset_      address of the asset
    /// @param  iTokenType_         type of iToken:
    /// - if underlying asset supports EIP-2612, the iToken should be type `EIP2612Deposits`
    /// - otherwise it should use `Permit2Deposits`
    /// - if it's the native token, it should use `NativeUnderlying`
    /// - could be more types available, check `iTokenTypes()`
    /// @return token_      detemrinistic address of the computed token
    function computeIToken(address asset_, string calldata iTokenType_) external view returns (address);

    /// @notice gets all public details for a certain `iToken_`, such as
    /// iToken type, name, symbol, decimals, underlying asset, total amounts, convertTo values, rewards.
    /// Note it also returns whether the iToken supports deposits / mints via EIP-2612, but it is not a 100% guarantee!
    /// To make sure, check for the underlying if it supports EIP-2612 manually.
    /// @param  iToken_     the iToken to get the details for
    /// @return iTokenDetails_  retrieved ITokenDetails struct
    function getITokenDetails(IIToken iToken_) external view returns (Structs.ITokenDetails memory iTokenDetails_);

    /// @notice returns config, rewards and exchange prices data of an iToken.
    /// @param  iToken_ the iToken to get the data for
    /// @return liquidity_ address of the Liquidity contract.
    /// @return lendingFactory_ address of the Lending factory contract.
    /// @return lendingRewardsRateModel_ address of the rewards rate model contract. changeable by LendingFactory auths.
    /// @return permit2_ address of the Permit2 contract used for deposits / mint with signature
    /// @return rebalancer_ address of the rebalancer allowed to execute `rebalance()`
    /// @return rewardsActive_ true if rewards are currently active
    /// @return liquidityBalance_ current Liquidity supply balance of `address(this)` for the underyling asset
    /// @return liquidityExchangePrice_ (updated) exchange price for the underlying assset in the liquidity protocol (without rewards)
    /// @return tokenExchangePrice_ (updated) exchange price between iToken and the underlying assset (with rewards)
    function getITokenInternalData(
        IIToken iToken_
    )
        external
        view
        returns (
            ILiquidity liquidity_,
            ILendingFactory lendingFactory_,
            ILendingRewardsRateModel lendingRewardsRateModel_,
            IAllowanceTransfer permit2_,
            address rebalancer_,
            bool rewardsActive_,
            uint256 liquidityBalance_,
            uint256 liquidityExchangePrice_,
            uint256 tokenExchangePrice_
        );

    /// @notice gets all public details for all itokens, such as
    /// iToken type, name, symbol, decimals, underlying asset, total amounts, convertTo values, rewards
    function getITokensEntireData() external view returns (Structs.ITokenDetails[] memory);

    /// @notice gets all public details for all itokens, such as
    /// iToken type, name, symbol, decimals, underlying asset, total amounts, convertTo values, rewards
    /// and user position for each token
    function getUserPositions(address user_) external view returns (Structs.ITokenDetailsUserPosition[] memory);

    /// @notice gets rewards related data: the `rewardsRateModel_` contract and the current `rewardsRate_` for the `iToken_`
    function getITokenRewards(
        IIToken iToken_
    ) external view returns (ILendingRewardsRateModel rewardsRateModel_, uint256 rewardsRate_);

    /// @notice gets rewards rate model config: the `rewardsRateModelConfig_` for the `iToken_`
    function getITokenRewardsRateModelConfig(
        IIToken iToken_
    ) external view returns (LendingRewardsRateModelStructs.Config memory rewardsRateModelConfig_);

    /// @notice gets a `user_` position for an `iToken_`.
    /// @return userPosition user position struct
    function getUserPosition(
        IIToken iToken_,
        address user_
    ) external view returns (Structs.UserPosition memory userPosition);

    /// @notice gets `iToken_` preview amounts for `assets_` or `shares_`.
    /// @return previewDeposit_ preview for deposit of `assets_`
    /// @return previewMint_ preview for mint of `shares_`
    /// @return previewWithdraw_ preview for withdraw of `assets_`
    /// @return previewRedeem_ preview for redeem of `shares_`
    function getPreviews(
        IIToken iToken_,
        uint256 assets_,
        uint256 shares_
    )
        external
        view
        returns (uint256 previewDeposit_, uint256 previewMint_, uint256 previewWithdraw_, uint256 previewRedeem_);
}
