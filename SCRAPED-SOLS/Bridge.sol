// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./interface/IHeaderPublisher.sol";
import "./BitcoinSPVLib.sol";

contract Bridge {
    IHeaderPublisher public publisher;

    constructor(address _publisher) {
        publisher = IHeaderPublisher(_publisher);
    }

    function verifyMerkleRoot(
        bytes memory _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes memory _locktime,
        bytes memory _intermediateNodes,
        uint _index
    ) public view returns (bytes32) {
        bytes32 txid = BitcoinSPVLib.calculateTxId(
            _version,
            _vin,
            _vout,
            _locktime
        );
        bytes32 merkleRoot = BitcoinSPVLib.calcMerkleRoot(txid, _intermediateNodes, _index);
        return publisher.blockHashes(merkleRoot);
    }
}
