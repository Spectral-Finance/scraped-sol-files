// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyCometExtension.sol";
import "forge-std/Test.sol";
import "../test/MainnetConstants.t.sol";
import "forge-std/console2.sol";

contract Playground is Script, Test, MainnetConstants {
    address public constant caller = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        console.log("Deploying My Comet Extension");
        MyCometExtension ext = deployMyCometExtension();
        console.log("Deployed My Comet Extension", address(ext));

        console.log("Proceed.");
    }

    function deployMyCometExtension() internal returns (MyCometExtension) {
        return new MyCometExtension(
            comet
        );
    }
}
