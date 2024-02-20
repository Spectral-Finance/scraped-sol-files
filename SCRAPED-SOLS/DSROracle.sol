// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { DSROracleBase, IDSROracle } from './DSROracleBase.sol';

interface IPot {
    function dsr() external view returns (uint256);
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
}

/**
 * @title  DSROracle
 * @notice DSR Oracle that sits on the same chain as MCD.
 */
contract DSROracle is DSROracleBase {

    IPot public immutable pot;

    constructor(address _pot) {
        pot = IPot(_pot);

        refresh();
    }

    /**
    * @notice Will refresh the local storage with the updated values.
    * @dev    This does not need to be called that frequently as the values provide complete precision if needed.
    *         `refresh()` should be called immediately whenever the `dsr` value changes.
    */
    function refresh() public {
        _data = IDSROracle.PotData({
            dsr: uint96(pot.dsr()),
            chi: uint120(pot.chi()),
            rho: uint40(pot.rho())
        });
    }

}
