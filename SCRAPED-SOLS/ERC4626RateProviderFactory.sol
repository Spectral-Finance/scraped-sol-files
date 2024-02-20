// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "./BaseRateProviderFactory.sol";
import "./ERC4626RateProvider.sol";

/**
 * @title ERC4626 Rate Provider Factory
 * @notice Factory for creating ERC4626RateProviders
 * @dev This contract is used to create ERC4626RateProvider contracts.
 */
contract ERC4626RateProviderFactory is BaseRateProviderFactory {
    /**
     * @notice Deploys a new ERC4626RateProvider contract using an ERC4626 contract.
     * @param erc4626 - The ERC4626 contract.
     */
    function create(IERC4626 erc4626) external returns (ERC4626RateProvider) {
        ERC4626RateProvider rateProvider = new ERC4626RateProvider(erc4626);
        _onCreate(address(rateProvider));
        return rateProvider;
    }
}
