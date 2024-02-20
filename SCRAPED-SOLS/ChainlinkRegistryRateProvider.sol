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
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IRateProvider.sol";

/**
 * @title Chainlink Registry Rate Provider
 * @notice Returns a Chainlink price feed's quote for the provided currency pair
 * @dev This rate provider uses the Chainlink pricefeed registry as the source of truth
 *      while caching the underlying feed to query in order to save gas.
 */
contract ChainlinkRegistryRateProvider is IRateProvider {
    FeedRegistryInterface public immutable registry;
    address public immutable base;
    address public immutable quote;

    // We cache the price feed for the given currency pair on this contract
    // This avoids unnecessarily querying the Chainlink registry.
    AggregatorV3Interface internal _feed;

    // Rate providers are expected to respond with a fixed-point value with 18 decimals
    // We then need to scale the price feed's output to match this.
    uint256 internal _scalingFactor;

    /**
     * @param _registry - The Chainlink price feed registry contract
     * @param _base - The identifier for the currency which the quoted rate will be denominated in
     * @param _quote - The identifier for the currency for which a price will be quoted
     */
    constructor(
        FeedRegistryInterface _registry,
        address _base,
        address _quote
    ) {
        registry = _registry;
        base = _base;
        quote = _quote;

        // Initialise price feed cache
        _feed = _registry.getFeed(_base, _quote);
        _scalingFactor = 10**SafeMath.sub(18, _feed.decimals());
    }

    /**
     * @return the value of the quote currency in terms of the base currency
     */
    function getRate() external view override returns (uint256) {
        (, int256 price, , , ) = _feed.latestRoundData();
        require(price > 0, "Invalid price rate response");
        return uint256(price) * _scalingFactor;
    }

    /**
     * @notice updates cached address of Chainlink price feed used to source quotes
     * @dev The cache may fall out of sync with the canonical price feed as listed on the Chainlink registry
     *      Any address may call this function to update the cache to match the registry.
     */
    function updateCachedFeed() external {
        AggregatorV3Interface priceFeed = registry.getFeed(base, quote);

        // Price feeds with more than 18 decimals are not supported.
        _scalingFactor = 10**SafeMath.sub(18, priceFeed.decimals());
        _feed = priceFeed;
    }
}
