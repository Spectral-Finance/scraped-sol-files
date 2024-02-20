//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ILiquidity } from "../../../liquidity/interfaces/iLiquidity.sol";

interface ILendingFactoryAdmin {
    /// @notice reads if a certain `auth_` address is an allowed auth or not. Owner is auth by default.
    function isAuth(address auth_) external view returns (bool);

    /// @notice              Sets an address as allowed auth or not. Only callable by owner.
    /// @param auth_         address to set auth value for
    /// @param allowed_      bool flag for whether address is allowed as auth or not
    function setAuth(address auth_, bool allowed_) external;

    /// @notice reads if a certain `deployer_` address is an allowed deployer or not. Owner is deployer by default.
    function isDeployer(address deployer_) external view returns (bool);

    /// @notice              Sets an address as allowed deployer or not. Only callable by owner.
    /// @param deployer_     address to set deployer value for
    /// @param allowed_      bool flag for whether address is allowed as deployer or not
    function setDeployer(address deployer_, bool allowed_) external;

    /// @notice              Sets the `creationCode_` bytecode for a certain `iTokenType_`. Only callable by auths.
    /// @param iTokenType_   the iToken Type used to refer the creation code
    /// @param creationCode_ contract creation code. can be set to bytes(0) to remove a previously available `iTokenType_`
    function setITokenCreationCode(string memory iTokenType_, bytes calldata creationCode_) external;

    /// @notice creates token for `asset_` for a lending protocol with interest. Only callable by deployers.
    /// @param  asset_              address of the asset
    /// @param  iTokenType_         type of iToken:
    /// - if it's the native token, it should use `NativeUnderlying`
    /// - otherwise it should use `iToken`
    /// - could be more types available, check `iTokenTypes()`
    /// @param  isNativeUnderlying_ flag to signal iToken type that uses native underlying at Liquidity
    /// @return token_              address of the created token
    function createToken(
        address asset_,
        string calldata iTokenType_,
        bool isNativeUnderlying_
    ) external returns (address token_);
}

interface ILendingFactory is ILendingFactoryAdmin {
    /// @notice list of all created tokens
    function allTokens() external view returns (address[] memory);

    /// @notice list of all iToken types that can be deployed
    function iTokenTypes() external view returns (string[] memory);

    /// @notice returns the creation code for a certain `iTokenType_`
    function iTokenCreationCode(string memory iTokenType_) external view returns (bytes memory);

    /// @notice address of the Liquidity contract.
    function LIQUIDITY() external view returns (ILiquidity);

    /// @notice computes deterministic token address for `asset_` for a lending protocol
    /// @param  asset_      address of the asset
    /// @param  iTokenType_         type of iToken:
    /// - if it's the native token, it should use `NativeUnderlying`
    /// - otherwise it should use `iToken`
    /// - could be more types available, check `iTokenTypes()`
    /// @return token_      detemrinistic address of the computed token
    function computeToken(address asset_, string calldata iTokenType_) external view returns (address token_);
}
