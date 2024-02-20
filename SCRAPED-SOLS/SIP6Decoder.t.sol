// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ISIP6} from "src/interfaces/sips/ISIP6.sol";
import {SIP6Decoder} from "src/sips/lib/SIP6Decoder.sol";
import {SIP6Encoder} from "src/sips/lib/SIP6Encoder.sol";

contract SIP6DecoderTest is Test {
    function testDecode1() public {
        bytes memory variable = "hello world";
        bytes memory extraData = abi.encodePacked(uint8(0), variable);
        bytes memory decoded = this.decode1(extraData);
        assertEq(decoded, variable);
    }

    function testDecode1(bytes memory variable) public {
        bytes memory extraData = SIP6Encoder.encodeSubstandard1(variable);
        bytes memory decoded = this.decode1(extraData);
        assertEq(decoded, variable);
    }

    function testDecode2() public {
        bytes memory fixedData = "hello world";
        bytes32 expectedHash = keccak256(abi.encodePacked(fixedData));
        bytes memory extraData = abi.encodePacked(uint8(1), fixedData);
        bytes memory decoded = this.decode2(extraData, expectedHash);
        assertEq(decoded, fixedData);
    }

    function testDecode2_InvalidExtraData() public {
        bytes memory fixedData = "hello world";
        bytes32 expectedHash = bytes32(uint256(keccak256(abi.encodePacked(fixedData))) + 1);
        bytes memory extraData = abi.encodePacked(uint8(1), fixedData);
        vm.expectRevert(SIP6Decoder.InvalidExtraData.selector);
        this.decode2(extraData, expectedHash);
    }

    function testDecode2(bytes memory fixedData) public {
        bytes32 expectedHash = keccak256(abi.encodePacked(fixedData));
        bytes memory extraData = SIP6Encoder.encodeSubstandard2(fixedData);
        bytes memory decoded = this.decode2(extraData, expectedHash);
        assertEq(decoded, fixedData);
    }

    function testDecode3() public {
        bytes memory fixedData = "hello";
        bytes memory variableData = "world";
        bytes32 expectedHash = keccak256(fixedData);
        bytes memory extraData = abi.encodePacked(uint8(2), abi.encode(fixedData, variableData));
        (bytes memory decodedFixedData, bytes memory decodedVariableData) = this.decode3(extraData, expectedHash);
        assertEq(decodedFixedData, fixedData);
        assertEq(decodedVariableData, variableData);
    }

    function testDecode2(bytes memory fixedData, bytes memory variableData) public {
        bytes32 expectedHash = keccak256(fixedData);
        bytes memory extraData = SIP6Encoder.encodeSubstandard3(fixedData, variableData);
        (bytes memory decodedFixedData, bytes memory decodedVariableData) = this.decode3(extraData, expectedHash);
        assertEq(decodedFixedData, fixedData);
        assertEq(decodedVariableData, variableData);
    }

    function testDecode4() public {
        bytes memory variableData1 = "hello";
        bytes memory variableData2 = "world";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;
        bytes memory extraData = abi.encodePacked(uint8(3), abi.encode(variableDataArrays));
        bytes[] memory decoded = this.decode4(extraData);
        assertEq(decoded.length, 2);
        assertEq(decoded[0], variableData1);
        assertEq(decoded[1], variableData2);
    }

    function testDecode4(bytes[] memory variableDataArrays) public {
        bytes memory extraData = SIP6Encoder.encodeSubstandard4(variableDataArrays);
        bytes[] memory decoded = this.decode4(extraData);
        assertEq(decoded.length, variableDataArrays.length);
        for (uint256 i; i < variableDataArrays.length; i++) {
            assertEq(decoded[i], variableDataArrays[i]);
        }
    }

    function testDecode4_emptyArray() public {
        bytes memory variableData1 = "";
        bytes memory variableData2 = "";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;
        bytes memory extraData = abi.encodePacked(uint8(3), abi.encode(variableDataArrays));
        bytes[] memory decoded = this.decode4(extraData);
        assertEq(decoded.length, 2);
        assertEq(decoded[0], variableData1);
        assertEq(decoded[1], variableData2);
    }

    function testDecode5_InvalidExtraData() public {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = bytes32(1 + uint256(keccak256(abi.encodePacked(subhashes))));

        bytes memory extraData = abi.encodePacked(uint8(4), abi.encode(fixedDataArrays));
        vm.expectRevert(SIP6Decoder.InvalidExtraData.selector);
        this.decode5(extraData, expectedHash);
    }

    function testDecode5() public {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));

        bytes memory extraData = abi.encodePacked(uint8(4), abi.encode(fixedDataArrays));
        bytes[] memory decoded = this.decode5(extraData, expectedHash);
        vm.breakpoint("a");
        assertEq(decoded.length, 2);
        assertEq(decoded[0], fixedData1);
        assertEq(decoded[1], fixedData2);
    }

    function testDecode5(bytes[] memory fixedData) public {
        bytes32[] memory subhashes = new bytes32[](fixedData.length);

        for (uint256 i; i < fixedData.length; i++) {
            subhashes[i] = keccak256(fixedData[i]);
        }
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));

        bytes memory extraData = SIP6Encoder.encodeSubstandard5(fixedData);
        bytes[] memory decoded = this.decode5(extraData, expectedHash);
        for (uint256 i; i < fixedData.length; i++) {
            assertEq(decoded[i], fixedData[i]);
        }
    }

    function testDecode6() public {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));

        bytes memory variableData1 = "hello2";
        bytes memory variableData2 = "world2";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;

        bytes memory extraData = abi.encodePacked(uint8(5), abi.encode(fixedDataArrays, variableDataArrays));
        (bytes[] memory decodedFixed, bytes[] memory decodedVariable) = this.decode6(extraData, expectedHash);
        assertEq(decodedFixed.length, 2);
        assertEq(decodedFixed[0], fixedData1);
        assertEq(decodedFixed[1], fixedData2);
        assertEq(decodedVariable.length, 2);
        assertEq(decodedVariable[0], variableData1);
        assertEq(decodedVariable[1], variableData2);
    }

    function testDecode6_InvalidExtraData() public {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = bytes32(1 + uint256(keccak256(abi.encodePacked(subhashes))));

        bytes memory variableData1 = "hello2";
        bytes memory variableData2 = "world2";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;

        bytes memory encoded = abi.encodePacked(uint8(5), abi.encode(fixedDataArrays, variableDataArrays));
        vm.expectRevert(SIP6Decoder.InvalidExtraData.selector);
        this.decode5(encoded, expectedHash);
    }

    function testDecode6(bytes[] memory fixedDataArrays, bytes[] memory variableDataArrays) public {
        bytes32[] memory subhashes = new bytes32[](fixedDataArrays.length);
        for (uint256 i; i < fixedDataArrays.length; i++) {
            subhashes[i] = keccak256(fixedDataArrays[i]);
        }

        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));

        bytes memory extraData = SIP6Encoder.encodeSubstandard6(fixedDataArrays, variableDataArrays);
        (bytes[] memory decodedFixed, bytes[] memory decodedVariable) = this.decode6(extraData, expectedHash);
        for (uint256 i; i < decodedFixed.length; i++) {
            assertEq(decodedFixed[i], fixedDataArrays[i]);
        }
        for (uint256 i; i < decodedVariable.length; i++) {
            assertEq(decodedVariable[i], variableDataArrays[i]);
        }
    }

    function decode1(bytes calldata extraData) external pure returns (bytes memory) {
        return SIP6Decoder.decodeSubstandard1(extraData);
    }

    function decode2(bytes calldata extraData, bytes32 expectedHash) external pure returns (bytes memory) {
        return SIP6Decoder.decodeSubstandard2(extraData, expectedHash);
    }

    function decode3(bytes calldata extraData, bytes32 expectedHash)
        external
        pure
        returns (bytes memory, bytes memory)
    {
        return SIP6Decoder.decodeSubstandard3(extraData, expectedHash);
    }

    function decode4(bytes calldata extraData) external pure returns (bytes[] memory) {
        return SIP6Decoder.decodeSubstandard4(extraData);
    }

    function decode5(bytes calldata extraData, bytes32 expectedHash) external pure returns (bytes[] memory) {
        return SIP6Decoder.decodeSubstandard5(extraData, expectedHash);
    }

    function decode6(bytes calldata extraData, bytes32 expectedHash)
        external
        pure
        returns (bytes[] memory, bytes[] memory)
    {
        return SIP6Decoder.decodeSubstandard6(extraData, expectedHash);
    }
}
