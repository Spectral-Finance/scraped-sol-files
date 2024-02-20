// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../src/mock/RocketStorageMock.sol";
import "../src/mock/RocketNetworkBalancesMock.sol";
import "../src/mock/ScrollL1CrossDomainMessengerMock.sol";

import "../src/RocketScrollPriceOracle.sol";
import "../src/RocketScrollPriceMessenger.sol";

/// @author Kane Wallmann (Rocket Pool)
contract RocketPriceOracleTest is Test {
    RocketStorageMock rocketStorage;
    RocketNetworkBalancesMock rocketNetworkBalances;
    ScrollL1CrossDomainMessengerMock scrollL1CrossDomainMessenger;

    RocketScrollPriceOracle priceOracle;
    RocketScrollPriceMessenger priceMessenger;

    // Events
    event RateUpdated(uint256 rate);

    function setUp() public {
        // Create mocks
        rocketStorage = new RocketStorageMock();
        rocketNetworkBalances = new RocketNetworkBalancesMock();
        scrollL1CrossDomainMessenger = new ScrollL1CrossDomainMessengerMock();
        // Set rocketNetworkBalances address to mock
        rocketStorage.setAddress(
            keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances")),
            address(rocketNetworkBalances)
        );
        // Set starting rate to 1:1
        rocketNetworkBalances.setTotalETHBalance(1 ether);
        rocketNetworkBalances.setTotalRETHSupply(1 ether);
        // Create the price oracle (on L2)
        priceOracle = new RocketScrollPriceOracle(address(scrollL1CrossDomainMessenger));
        // Create the messenger
        priceMessenger = new RocketScrollPriceMessenger(
            RocketStorageInterface(address(rocketStorage)),
            priceOracle,
            IScrollMessenger(scrollL1CrossDomainMessenger)
        );
        // Rate and last updated should be 0
        uint256 rate = priceOracle.rate();
        uint256 updated = priceOracle.lastUpdated();
        assertEq(updated, 0);
        assertEq(rate, 0);
    }

    function testFailOnlyOwnerCanSetOwner() public {
        vm.prank(address(0));
        priceOracle.setOwner(address(priceMessenger));
    }

    function testOnlyOwnerCanSetOwner() public {
        priceOracle.setOwner(address(priceMessenger));
        assertEq(priceOracle.owner(), address(priceMessenger));
    }

    function testRateStale() public {
        // Set owner on price oracle
        priceOracle.setOwner(address(priceMessenger));
        // Rate should be stale
        assertTrue(priceMessenger.rateStale());
        // Send the updated rate
        priceMessenger.submitRate(150000);
        // Rate should no longer be stale
        assertFalse(priceMessenger.rateStale());
        // Change rate again
        rocketNetworkBalances.setTotalETHBalance(1.5 ether);
        // Rate should be stale
        assertTrue(priceMessenger.rateStale());
    }

    function testCanSendRate() public {
        // Set owner on price oracle
        priceOracle.setOwner(address(priceMessenger));
        // Expect event
        vm.expectEmit(false, false, false, true);
        emit RateUpdated(1 ether);
        // Anyone can call submitRate
        vm.prank(address(0));
        // Send the updated rate
        priceMessenger.submitRate(150000);
        // Check rate and lastUpdated were updated
        uint256 rate = priceOracle.rate();
        uint256 updated = priceOracle.lastUpdated();
        assertGt(updated, 0);
        assertEq(rate, 1 ether);
    }

    function testNotOwner() public {
        // Send the updated rate
        priceMessenger.submitRate(150000);
        // Rate should not be updated
        uint256 rate = priceOracle.rate();
        uint256 updated = priceOracle.lastUpdated();
        assertEq(updated, 0);
        assertEq(rate, 0);
    }

    function testRates(uint256 ethTotal, uint256 rethSupply) public {
        vm.assume(ethTotal < 1_000_000 ether);
        vm.assume(rethSupply < 1_000_000 ether);
        // Set owner on price oracle
        priceOracle.setOwner(address(priceMessenger));
        // Set the rate
        rocketNetworkBalances.setTotalETHBalance(ethTotal);
        rocketNetworkBalances.setTotalRETHSupply(rethSupply);
        // Calculate expected rate
        uint256 expectedRate;
        if (rethSupply == 0) {
            expectedRate = 0;
        } else {
            expectedRate = 1 ether * ethTotal / rethSupply;
        }
        // Expect event
        vm.expectEmit(false, false, false, true);
        emit RateUpdated(expectedRate);
        // Send the updated rate
        priceMessenger.submitRate(150000);
        // Check rate and lastUpdated were updated
        uint256 rate = priceOracle.rate();
        assertEq(rate, expectedRate);
    }
}
