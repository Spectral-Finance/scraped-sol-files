// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Channel {
    bytes32 public trustee;

    string public name;

    string public metaURI;

    uint256 public BTCBalance;

    constructor(bytes32 trustee_) {
        trustee = trustee_;
    }

    function getCapacity() public pure returns (uint256) {
        return 100000000;
    }

    function deposit() public pure {
        require(false, "unrealized");
    }

    function withdraw(uint256) public pure {
        require(false, "unrealized");
    }

    function deposit(IERC20) public pure {
        require(false, "unrealized");
    }

    function withdraw(IERC20, uint256) public pure {
        require(false, "unrealized");
    }
}
