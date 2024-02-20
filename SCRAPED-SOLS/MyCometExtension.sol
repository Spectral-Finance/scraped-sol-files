// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/CometInterface.sol";

/**
 * @title My Extension
 * @notice A Compound III operator to ...
 * @author Compound
 */
contract MyCometExtension {
  /// @notice The Comet contract
  Comet public immutable comet;

  /**
   * @notice Construct a new MyExtension operator.
   * @param comet_ The Comet contract.
   **/
  constructor(Comet comet_) payable {
    comet = comet_;
  }
}
