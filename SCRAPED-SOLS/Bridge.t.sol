// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./Bridge.sol";
import "./HeaderPublisher.sol";

contract BridgeTest is DSTest {
    Bridge public bridge;
    HeaderPublisher public publisher;

    function setUp() public {
        publisher = new HeaderPublisher();
        uint32 height = 804204;
        bytes32 blockHash = 0x00000000c937983704a73af28acdec37b049d214adbda81d7e2a3dd146f6ed09;
        bytes32 merkleRoot = 0xe0ca6438e2b419efef9d3416d1d2ae70a4fd3d69413222b5c1a5e87b39326607;
        publisher.publishHeader(height, blockHash, merkleRoot);

        bridge = new Bridge(address(publisher));
    }

    function test_verifyMerkleRoot() public {
        bytes memory version = hex"01000000";
        bytes
            memory vin = hex"0153e335f2125ed77117ca81418edba2b0e74fa26b229ed163aea8279288a0534e0000000000fdffffff";
        bytes
            memory vout = hex"01d0cff50500000000160014d8e1505dae543d15f0d859c54217fe89c141b831";
        bytes memory locktime = hex"00000000";
        bytes
            memory intermediateNodes = hex"1d691caf7138cba3b4b397a1931d82e3673303e91be44f932230e4dcaa0b035f07cdb617012dd2055f9c0ac0a4016cd7c12a5cd8d208b3d627a1fa4cb4a4748fc2e4997501e4d059f8aa590cbba8cf592370c04a254ad253104a61b5f1d5cb06fb728b06ee84dd0ca74bb5963c2a08dbc213e2c1ecc4b3a8bb21c7acbbc98d34290f20a92fdca8fd647c4c18597896b90af050e8eebf20cd9047e494bb2f105423b5d2aad052bff423bcaa767dfae4542e9e42116d9a7748bc7a905a61b6a45644dcd19fcffb849b4b4417a5c58a6bed52ba552a857cfe6fbb38b053d9f27093b9d5e2ee4a39898f453f3fe8f65ff50aa93c21a00fee5eaa72c0771bc621cd3d0acf0320104c55066e4ffb244ba946848e302bb58600f133567dd07abbd316ef9885c35f70f9e0e6347b0740f378c8b497181321c21043bb69d86f662f509459435308a78ab45f825423389e479c0fb3b4b58a02532cefba6b921da55171a2e18e620b7ea1b2b8a8b6c229530eea420444820378903d8ad489308343ef1ee73d";
        uint index = 253;
        
        bytes32 blockHash = bridge.verifyMerkleRoot(version, vin, vout, locktime, intermediateNodes, index);
        bytes32 expected = 0x00000000c937983704a73af28acdec37b049d214adbda81d7e2a3dd146f6ed09;
        assertEq(blockHash, expected);
    }
}
