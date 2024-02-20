// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import { MockPool } from "./MockPool.sol";

contract MockPoolConfigurator {

    /**********************************************************************************************/
    /*** Declarations and Constructor                                                           ***/
    /**********************************************************************************************/

    MockPool public mockPool;

    constructor(MockPool _mockPool) {
        mockPool = _mockPool;
    }

    /**********************************************************************************************/
    /*** PoolConfigurator Functions                                                             ***/
    /**********************************************************************************************/

    function setSupplyCap(address, uint256 supplyCap) external {
        mockPool.__setSupplyCap(supplyCap);
    }

    function setBorrowCap(address, uint256 borrowCap) external {
        mockPool.__setBorrowCap(borrowCap);
    }

}
