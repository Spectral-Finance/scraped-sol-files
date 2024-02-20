// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyCometExtension.sol";
import "forge-std/Test.sol";
import "./MainnetConstants.t.sol";

contract MyCometExtensionTest is MainnetConstants {
    function testMyCometExtension() public {
        MyCometExtension ext = deployMyCometExtension();
    }

    function deployMyCometExtension() internal returns (MyCometExtension) {
        return new MyCometExtension(
            comet
        );
    }
}
