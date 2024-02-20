// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/// @notice Default proxy admin of Fluid TransparentUpgradeableProxy contracts.
/// @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
/// explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
contract FluidProxyAdmin is ProxyAdmin {
    /// @notice thrown when an unsupported method is called (e.g. renounceOwnership)
    error FluidProxyAdmin__Unsupported();

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /// @notice override renounce ownership as it could leave the contract in an unwanted state if called by mistake.
    function renounceOwnership() public view override onlyOwner {
        revert FluidProxyAdmin__Unsupported();
    }
}
