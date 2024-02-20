// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { UpgradeableProxied } from "../src/UpgradeableProxied.sol";

contract CounterImplementation is UpgradeableProxied {

    event SetNumber(uint256 newNumber);

    uint256 public number;

    mapping(bytes32 => uint256) public numberMapping;

    modifier auth {
        require(wards[msg.sender] == 1, "CounterImplementation/not-authorized");
        _;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit SetNumber(newNumber);  // Test events are emitted correctly from proxy
    }

    function setNumberMapping(bytes32 key, uint256 newNumber) public auth {
        numberMapping[key] = newNumber;
    }

    function increment() public {
        number++;
    }

}
