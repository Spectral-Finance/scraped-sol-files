// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

abstract contract StakedFraxFunctions is BaseTest {
    function _stakedFrax_setMaxDistributionPerSecondPerAsset(uint256 _maxDistributionPerSecondPerAsset) internal {
        hoax(stakedFrax.timelockAddress());
        stakedFrax.setMaxDistributionPerSecondPerAsset(_maxDistributionPerSecondPerAsset);
    }
}

contract TestSetMaxDistributionPerSecondPerAsset is BaseTest, StakedFraxFunctions {
    /// FEATURE: setMaxDistributionPerSecondPerAsset

    function setUp() public {
        /// BACKGROUND: deploy the StakedFrax contract
        /// BACKGROUND: 10% APY cap
        /// BACKGROUND: frax as the underlying asset
        /// BACKGROUND: TIMELOCK_ADDRESS set as the timelock address
        defaultSetup();
    }

    function test_CannotCallIfNotTimelock() public {
        /// WHEN: non-timelock calls setMaxDistributionPerSecondPerAsset
        vm.expectRevert(
            abi.encodeWithSelector(
                Timelock2Step.AddressIsNotTimelock.selector,
                stakedFrax.timelockAddress(),
                address(this)
            )
        );
        stakedFrax.setMaxDistributionPerSecondPerAsset(1 ether);
        /// THEN: we expect a revert with the AddressIsNotTimelock error
    }

    function test_CannotSetAboveUint64() public {
        StakedFraxStorageSnapshot memory _initial_stakedFraxStorageSnapshot = stakedFraxStorageSnapshot(stakedFrax);

        /// WHEN: timelock sets maxDistributionPerSecondPerAsset to uint64.max + 1
        _stakedFrax_setMaxDistributionPerSecondPerAsset(uint256(type(uint64).max) + 1);

        DeltaStakedFraxStorageSnapshot memory _delta_stakedFraxStorageSnapshot = deltaStakedFraxStorageSnapshot(
            _initial_stakedFraxStorageSnapshot
        );

        /// THEN: values should be equal to uint64.max
        assertEq(
            _delta_stakedFraxStorageSnapshot.end.maxDistributionPerSecondPerAsset,
            type(uint64).max,
            "THEN: values should be equal to uint64.max"
        );
    }

    function test_CanSetMaxDistributionPerSecondPerAsset() public {
        StakedFraxStorageSnapshot memory _initial_stakedFraxStorageSnapshot = stakedFraxStorageSnapshot(stakedFrax);

        /// WHEN: timelock sets maxDistributionPerSecondPerAsset to 1 ether
        _stakedFrax_setMaxDistributionPerSecondPerAsset(1 ether);

        DeltaStakedFraxStorageSnapshot memory _delta_stakedFraxStorageSnapshot = deltaStakedFraxStorageSnapshot(
            _initial_stakedFraxStorageSnapshot
        );

        /// THEN: maxDistributionPerSecondPerAsset should be 1 ether
        assertEq(
            _delta_stakedFraxStorageSnapshot.end.maxDistributionPerSecondPerAsset,
            1 ether,
            "THEN: maxDistributionPerSecondPerAsset should be 1 ether"
        );
    }
}
