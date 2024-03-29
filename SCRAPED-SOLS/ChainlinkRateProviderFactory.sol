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

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./BaseRateProviderFactory.sol";
import "./ChainlinkRateProvider.sol";

/**
 * @title Chainlink Rate Provider Factory
 * @notice Factory for creating ChainlinkRateProviders
 * @dev This contract is used to create ChainlinkRateProvider contracts.
 *      RateProviders created by this factory are to be used in environments
 *      where the Chainlink registry is not available.
 */
contract ChainlinkRateProviderFactory is BaseRateProviderFactory {
    /**
     * @notice Deploys a new ChainlinkRateProvider contract using a price feed.
     * @param feed - The Chainlink price feed contract.
     */
    function create(AggregatorV3Interface feed) external returns (ChainlinkRateProvider) {
        ChainlinkRateProvider rateProvider = new ChainlinkRateProvider(feed);
        _onCreate(address(rateProvider));
        return rateProvider;
    }
}
