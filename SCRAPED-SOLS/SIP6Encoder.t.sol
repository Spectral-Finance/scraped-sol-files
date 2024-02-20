// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ISIP6} from "src/interfaces/sips/ISIP6.sol";
import {SIP6Encoder} from "src/sips/lib/SIP6Encoder.sol";

contract SIP6EncoderTest is Test {
    ///@dev hack to get around forge test reporting a huge number if vm.pauseGasMetering is in effect at end of a test run
    modifier unmetered() {
        vm.pauseGasMetering();
        _;
        vm.resumeGasMetering();
    }

    modifier metered() {
        vm.resumeGasMetering();
        _;
        vm.pauseGasMetering();
    }

    function test_GasBaseline() public unmetered {}

    function testEncode1() public unmetered {
        bytes memory variable = "hello world";
        bytes memory expectedEncoded = abi.encodePacked(uint8(1), variable);
        bytes memory actualEncoded = this.encode1(variable);
        assertEq(actualEncoded, expectedEncoded, "encoded does not match expected");
    }

    function testEncode2() public unmetered {
        bytes memory fixedData = "hello world";
        bytes memory expectedEncoded = abi.encodePacked(uint8(2), fixedData);
        bytes memory actualEncoded = this.encode2(fixedData);
        assertEq(actualEncoded, expectedEncoded, "encoded does not match expected");

        bytes32 expectedHash = keccak256(abi.encodePacked(fixedData));
        bytes32 actualHash = this.generateZoneHash(fixedData);
        assertEq(actualHash, expectedHash, "hash does not match expected");
    }

    function testEncode3() public unmetered {
        bytes memory fixedData = "hello";
        bytes memory variableData = "world";
        bytes memory expectedEncoded = abi.encodePacked(uint8(3), abi.encode(fixedData, variableData));
        (bytes memory actualEncoded) = this.encode3(fixedData, variableData);
        assertEq(actualEncoded, expectedEncoded, "encoded does not match expected");

        bytes32 actualHash = this.generateZoneHash(fixedData);
        bytes32 expectedHash = keccak256(fixedData);
        assertEq(actualHash, expectedHash, "hash does not match expected");
    }

    function testEncode4() public unmetered {
        bytes memory variableData1 = "hello";
        bytes memory variableData2 = "world";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;
        bytes memory expectedEncoded = abi.encodePacked(uint8(4), abi.encode(variableDataArrays));
        bytes memory actualEncoded = this.encode4(variableDataArrays);
        assertEq(actualEncoded, expectedEncoded, "encoded does not match expected");
    }

    function testEncode5() public unmetered {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes memory expectedEncoded = abi.encodePacked(uint8(5), abi.encode(fixedDataArrays));
        bytes memory actualEncoded = this.encode5(fixedDataArrays);
        assertEq(actualEncoded, expectedEncoded, "encoded does not match expected");

        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));
        bytes32 actualHash = this.generateZoneHash(fixedDataArrays);
        assertEq(actualHash, expectedHash, "hash does not match expected");
    }

    function testEncode6() public unmetered {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;

        bytes memory variableData1 = "hello2";
        bytes memory variableData2 = "world2";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;

        bytes memory expectedEncoded = abi.encodePacked(uint8(6), abi.encode(fixedDataArrays, variableDataArrays));
        (bytes memory actualEncoded) = this.encode6(fixedDataArrays, variableDataArrays);
        assertEq(actualEncoded, expectedEncoded, "encoded does not match expected");

        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));
        bytes32 actualHash = this.generateZoneHash(fixedDataArrays);
        assertEq(actualHash, expectedHash, "hash does not match expected");
    }

    function encode1(bytes calldata variableData) external metered returns (bytes memory) {
        return SIP6Encoder.encodeSubstandard1(variableData);
    }

    function encode2(bytes memory fixedData) external metered returns (bytes memory) {
        return SIP6Encoder.encodeSubstandard2(fixedData);
    }

    function encode3(bytes calldata fixedData, bytes memory variableData) external metered returns (bytes memory) {
        return SIP6Encoder.encodeSubstandard3(fixedData, variableData);
    }

    function encode4(bytes[] memory variableData) external metered returns (bytes memory) {
        return SIP6Encoder.encodeSubstandard4(variableData);
    }

    function encode5(bytes[] memory fixedData) external metered returns (bytes memory) {
        return SIP6Encoder.encodeSubstandard5(fixedData);
    }

    function encode6(bytes[] memory fixedData, bytes[] memory variableData) external metered returns (bytes memory) {
        return SIP6Encoder.encodeSubstandard6(fixedData, variableData);
    }

    function generateZoneHash(bytes memory fixedData) external metered returns (bytes32) {
        return SIP6Encoder.generateZoneHash(fixedData);
    }

    function generateZoneHash(bytes[] memory fixedData) external metered returns (bytes32) {
        return SIP6Encoder.generateZoneHash(fixedData);
    }
}
