// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IHeaderPublisher.sol";

contract HeaderPublisher is IHeaderPublisher{
    mapping(uint32 => bytes32) public override heights;
    mapping(bytes32 => bytes32) public override blockHashes;

    bool public validatePrevHash;

    constructor() {
      validatePrevHash = false;
    }

    function publishHeader(uint32 _height, bytes32 _blockHash, bytes32 _merkleRoot) public {
      require(heights[_height] == 0, "HeaderPublisher: height exist");
      require(blockHashes[_merkleRoot] == bytes32(0), "HeaderPublisher: header exist");
      heights[_height] = _blockHash;
      blockHashes[_merkleRoot] = _blockHash;
    }
}
