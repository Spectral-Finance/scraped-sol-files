// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "./MerlinBridge.sol";

contract MerlinBridgeTest is DSTest {
    MerlinBridge private _mb;

    function setUp() public {
      _mb = new MerlinBridge();
    }

    function test_setAdmin() public {
      address newOne = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
      _mb.setAdmin(newOne);
      // bytes32 role = 0x00;
      // bytes32 admin = _mb.getRoleAdmin(role);
      // assertEq(newOne, bytes32ToAddress(admin));
    }

    function bytes32ToAddress(bytes32 _bytes) private pure returns (address) {
        return address(uint160(uint256(_bytes)));
    }
}
