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

import "./interfaces/IBaseRateProviderFactory.sol";

/**
 * @title Base Rate Provider Factory
 * @notice Base Factory for creating RateProviders
 * @dev This is a base contract for building factories that create RateProviders.
 */
contract BaseRateProviderFactory is IBaseRateProviderFactory {
    // Mapping of rate providers created by this factory.
    mapping(address => bool) private _isRateProviderFromFactory;

    event RateProviderCreated(address indexed rateProvider);

    function isRateProviderFromFactory(address rateProvider) external view returns (bool) {
        return _isRateProviderFromFactory[rateProvider];
    }

    function _onCreate(address rateProvider) internal {
        _isRateProviderFromFactory[rateProvider] = true;
        emit RateProviderCreated(rateProvider);
    }
}
