// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "./BitcoinSPVLib.sol";
import "./BytesLib.sol";

contract BitcoinSPVLibTest is DSTest {
    using BytesLib for bytes;

    function setUp() public {}

    function test_prove() public {
        bytes32 txid = 0x4296a40352621ee5fb772e06c2ab829833a07ca24b9b9703572eab08d74fb510;
        bytes32 merkleRoot = 0x35c6c97ce2ba51f87dd4ca371f42e9ee22297bef811cc664f433319bda07a4d7;
        bytes
            memory intermediateNodes = hex"355f111911ed231dd7106e18f446a249c0c6955dac2c6492ee1a1c66f10f0ba1ea4e59de46658d19eaacbd3a8664a18326a0f1bb47e9fc64371a5c463070309f90a46842f129faa6a6caa73f978f0ac7eda25158469d958a631dab8ca83968b47ef2f9eb252807ec6386af941d57013c840e88100352c217b94e8b286890741f6667c01ff5f28ec70949311a440f1d7fab5115a14e67f09ebbb6eef04938f60f87f55897656c67828f1a1bf8277e7681914fe75bcd6393a6fb8c3bb312336c3477044d68439ece8dc652a37d7c8f65f4f6adb018338698cabeced613d223aab2479aadd4f5e26da590140bc450c3183608635a8bb957ec42f25709bb6f459cbc37c7787d55e92b19509f22f0c89fb4f6248e7a5c4153648c90b1413cafca7296cc7e49f5853088227e253bd80340c0755e16eafe48d65db0ade3511d3d63d4ba31dd13e5c18a3f82eb330d6a81f91c98667087eb94f05786bdbbe8667369983407ad0ea3fd6ee66d7be0f26137993788c83ac09f87eb3c6cd1be891e7d3c58f0";
        uint index = 38;
        bool condition = BitcoinSPVLib.prove(
            txid,
            merkleRoot,
            intermediateNodes,
            index
        );
        assertTrue(condition);
    }

    function test_verifyHash256Merkle() public {
        bytes
            memory proof = hex"4296a40352621ee5fb772e06c2ab829833a07ca24b9b9703572eab08d74fb510355f111911ed231dd7106e18f446a249c0c6955dac2c6492ee1a1c66f10f0ba1ea4e59de46658d19eaacbd3a8664a18326a0f1bb47e9fc64371a5c463070309f90a46842f129faa6a6caa73f978f0ac7eda25158469d958a631dab8ca83968b47ef2f9eb252807ec6386af941d57013c840e88100352c217b94e8b286890741f6667c01ff5f28ec70949311a440f1d7fab5115a14e67f09ebbb6eef04938f60f87f55897656c67828f1a1bf8277e7681914fe75bcd6393a6fb8c3bb312336c3477044d68439ece8dc652a37d7c8f65f4f6adb018338698cabeced613d223aab2479aadd4f5e26da590140bc450c3183608635a8bb957ec42f25709bb6f459cbc37c7787d55e92b19509f22f0c89fb4f6248e7a5c4153648c90b1413cafca7296cc7e49f5853088227e253bd80340c0755e16eafe48d65db0ade3511d3d63d4ba31dd13e5c18a3f82eb330d6a81f91c98667087eb94f05786bdbbe8667369983407ad0ea3fd6ee66d7be0f26137993788c83ac09f87eb3c6cd1be891e7d3c58f035c6c97ce2ba51f87dd4ca371f42e9ee22297bef811cc664f433319bda07a4d7";
        uint index = 38;
        bool condition = BitcoinSPVLib.verifyHash256Merkle(proof, index);
        assertTrue(condition);
    }

    function test_calculateTxId() public {
        bytes memory version = hex"01000000";
        bytes
            memory vin = hex"01e17e03d21d051aa2bd9d336c3ac0693cfa92ce71592ceec521b1c48019ff77a10100";
        bytes
            memory vout = hex"0000171600146d76e574b5f4825fe740ba6c41aaf1b319dfb80cffffffff02819a010000000000160014422002d927a1cae901eac668444cce8dd0ae60d529b31b0b0000000017a914f5b48d1130dc3d366d1eabf6783a552d1c8e08f487";
        bytes memory locktime = hex"00000000";
        bytes32 result = BitcoinSPVLib.calculateTxId(
            version,
            vin,
            vout,
            locktime
        );
        bytes32 txId = 0x4296a40352621ee5fb772e06c2ab829833a07ca24b9b9703572eab08d74fb510;
        assertEq(txId, result);
    }

    function test_calculateTxId2() public {
        bytes memory version = hex"01000000";
        bytes
            memory vin = hex"0153e335f2125ed77117ca81418edba2b0e74fa26b229ed163aea8279288a0534e0000000000fdffffff";
        bytes
            memory vout = hex"01d0cff50500000000160014d8e1505dae543d15f0d859c54217fe89c141b831";
        bytes memory locktime = hex"00000000";
        bytes32 result = BitcoinSPVLib.calculateTxId(
            version,
            vin,
            vout,
            locktime
        );
        bytes32 txId = 0x501f985500d814c1710c820f6c40c44f547bd6b324440995079c9fe621a7bef5;
        assertEq(txId, result);
    }

    function test_calcMerkleRoot() public {
        bytes32 txid = 0x501f985500d814c1710c820f6c40c44f547bd6b324440995079c9fe621a7bef5;
        bytes32 merkleRoot = 0xe0ca6438e2b419efef9d3416d1d2ae70a4fd3d69413222b5c1a5e87b39326607;
        bytes
            memory intermediateNodes = hex"1d691caf7138cba3b4b397a1931d82e3673303e91be44f932230e4dcaa0b035f07cdb617012dd2055f9c0ac0a4016cd7c12a5cd8d208b3d627a1fa4cb4a4748fc2e4997501e4d059f8aa590cbba8cf592370c04a254ad253104a61b5f1d5cb06fb728b06ee84dd0ca74bb5963c2a08dbc213e2c1ecc4b3a8bb21c7acbbc98d34290f20a92fdca8fd647c4c18597896b90af050e8eebf20cd9047e494bb2f105423b5d2aad052bff423bcaa767dfae4542e9e42116d9a7748bc7a905a61b6a45644dcd19fcffb849b4b4417a5c58a6bed52ba552a857cfe6fbb38b053d9f27093b9d5e2ee4a39898f453f3fe8f65ff50aa93c21a00fee5eaa72c0771bc621cd3d0acf0320104c55066e4ffb244ba946848e302bb58600f133567dd07abbd316ef9885c35f70f9e0e6347b0740f378c8b497181321c21043bb69d86f662f509459435308a78ab45f825423389e479c0fb3b4b58a02532cefba6b921da55171a2e18e620b7ea1b2b8a8b6c229530eea420444820378903d8ad489308343ef1ee73d";
        uint index = 253;
        bytes32 result = BitcoinSPVLib.calcMerkleRoot(
            txid,
            intermediateNodes,
            index
        );
        assertEq(merkleRoot, result);
    }

    function test_extractOutputAtIndex() public {
        bytes
            memory vout = hex"01d0cff50500000000160014d8e1505dae543d15f0d859c54217fe89c141b831";
        bytes memory expected = hex"d0cff50500000000160014d8e1505dae543d15f0d859c54217fe89c141b831";
        uint256 index = 0;
        bytes memory data = BitcoinSPVLib.extractOutputAtIndex(vout, index);
        assertEq0(data, expected);

        uint64 amount = BitcoinSPVLib.extractValue(data);
        uint64 expectedAmount = 99995600;
        assertEq(amount, expectedAmount);
    }
}
