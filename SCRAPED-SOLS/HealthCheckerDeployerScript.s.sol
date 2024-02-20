// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import { Script, console2 } from "forge-std/Script.sol";

import { SparkLendHealthChecker } from "src/SparkLendHealthChecker.sol";

contract HealthCheckerDeployerScript is Script {

    // Deployed at: 0xfda082e00EF89185d9DB7E5DcD8c5505070F5A3B

    address constant DATA_PROVIDER = 0xFc21d6d146E6086B8359705C8b28512a983db0cb;
    address constant POOL          = 0xC13e21B648A5Ee794902342038FF3aDAB66BE987;

    function setUp() public {}

    function run() public {
        vm.broadcast();
        SparkLendHealthChecker healthChecker = new SparkLendHealthChecker(POOL, DATA_PROVIDER);
        console2.log("Health Checker: %s", address(healthChecker));
    }

}
