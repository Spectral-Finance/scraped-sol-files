// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";

import { UpgradeableProxy } from "../src/UpgradeableProxy.sol";

import { CounterImplementation } from "./CounterImplementation.sol";

contract ProxyBaseTest is Test {

    event Deny(address indexed usr);
    event Rely(address indexed usr);
    event SetImplementation(address indexed implementation_);
    event SetNumber(uint256 newNumber);

    CounterImplementation public implementation;
    UpgradeableProxy      public proxy;

    function setUp() public virtual {
        implementation = new CounterImplementation();

        vm.expectEmit();
        emit Rely(address(this));
        proxy = new UpgradeableProxy();
    }

}

contract ProxyConstructorTest is ProxyBaseTest {

    function test_constructor() public {
        assertEq(proxy.implementation(),     address(0));
        assertEq(proxy.wards(address(this)), 1);
    }

}

contract ProxyDenyTest is ProxyBaseTest {

    function test_deny_no_auth() public {
        address nonAdmin = makeAddr("non-admin");

        vm.prank(nonAdmin);
        vm.expectRevert("UpgradeableProxy/not-authorized");
        proxy.deny(address(this));
    }

    function test_deny_success() public {
        address existingAdmin = address(this);

        assertEq(proxy.wards(existingAdmin), 1);

        vm.expectEmit(address(proxy));
        emit Deny(existingAdmin);
        proxy.deny(existingAdmin);

        assertEq(proxy.wards(existingAdmin), 0);
    }

}

contract ProxyRelyTest is ProxyBaseTest {

    address newAdmin = makeAddr("new-admin");

    function test_rely_no_auth() public {
        address nonAdmin = makeAddr("non-admin");

        vm.prank(nonAdmin);
        vm.expectRevert("UpgradeableProxy/not-authorized");
        proxy.rely(newAdmin);
    }

    function test_rely_success() public {
        assertEq(proxy.wards(newAdmin), 0);

        vm.expectEmit(address(proxy));
        emit Rely(newAdmin);
        proxy.rely(newAdmin);

        assertEq(proxy.wards(newAdmin), 1);
    }

}

contract ProxySetImplementationTest is ProxyBaseTest {

    address newImplementation = makeAddr("new-implementation");

    function test_setImplementation_no_auth() public {
        address nonAdmin = makeAddr("non-admin");

        vm.prank(nonAdmin);
        vm.expectRevert("UpgradeableProxy/not-authorized");
        proxy.setImplementation(newImplementation);
    }

    // NOTE: Implementation can be set to no-code addresses currently.
    function test_setImplementation_success() public {
        assertEq(proxy.implementation(), address(0));

        vm.expectEmit(address(proxy));
        emit SetImplementation(newImplementation);
        proxy.setImplementation(newImplementation);

        assertEq(proxy.implementation(), newImplementation);
    }

}

contract ProxyFallbackTest is ProxyBaseTest {

    CounterImplementation public counterProxy;

    function setUp() public override {
        super.setUp();

        counterProxy = CounterImplementation(address(proxy));
    }

    function test_fallback_no_implementation() public {
        vm.expectRevert("UpgradeableProxy/no-code-at-implementation");
        counterProxy.increment();
    }

    function test_fallback_increment() public {
        proxy.setImplementation(address(implementation));

        assertEq(counterProxy.number(),   0);
        assertEq(implementation.number(), 0);

        counterProxy.increment();

        assertEq(counterProxy.number(),   1);
        assertEq(implementation.number(), 0);
    }

    function test_fallback_setNumber() public {
        proxy.setImplementation(address(implementation));

        assertEq(counterProxy.number(),   0);
        assertEq(implementation.number(), 0);

        vm.expectEmit(address(counterProxy));
        emit SetNumber(42);
        counterProxy.setNumber(42);

        assertEq(counterProxy.number(),   42);
        assertEq(implementation.number(), 0);
    }

    function test_fallback_setNumberMapping_noAuth() public {
        proxy.setImplementation(address(implementation));

        bytes32 key = "key";

        vm.prank(makeAddr("non-admin"));
        vm.expectRevert("CounterImplementation/not-authorized");
        counterProxy.setNumberMapping(key, 42);
    }

    function test_fallback_setNumberMapping() public {
        proxy.setImplementation(address(implementation));

        bytes32 key = "key";

        assertEq(counterProxy.numberMapping(key),   0);
        assertEq(implementation.numberMapping(key), 0);

        counterProxy.setNumberMapping(key, 42);

        assertEq(counterProxy.numberMapping(key),   42);
        assertEq(implementation.numberMapping(key), 0);
    }

    function test_setNumberMapping_onImplementation_noAuth() public {
        proxy.setImplementation(address(implementation));

        bytes32 key = "key";

        assertEq(counterProxy.wards(address(this)),   1);
        assertEq(implementation.wards(address(this)), 0);

        vm.expectRevert("CounterImplementation/not-authorized");
        implementation.setNumberMapping(key, 42);

        counterProxy.setNumberMapping(key, 42);
    }

}
