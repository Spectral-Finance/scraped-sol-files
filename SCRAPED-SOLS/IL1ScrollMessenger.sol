// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IScrollMessenger.sol";

interface IL1ScrollMessenger is IScrollMessenger {
    /***********
     * Structs *
     ***********/

    struct L2MessageProof {
        // The hash of the batch where the message belongs to.
        bytes32 batchHash;
        // Concatenation of merkle proof for withdraw merkle trie.
        bytes merkleProof;
    }

    /****************************
     * Public Mutated Functions *
     ****************************/

    /// @notice Relay a L2 => L1 message with message proof.
    /// @param from The address of the sender of the message.
    /// @param to The address of the recipient of the message.
    /// @param value The msg.value passed to the message call.
    /// @param nonce The nonce of the message to avoid replay attack.
    /// @param message The content of the message.
    /// @param proof The proof used to verify the correctness of the transaction.
    function relayMessageWithProof(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        bytes memory message,
        L2MessageProof memory proof
    ) external;

    /// @notice Send cross chain message from L1 to L2 or L2 to L1.
    /// @param target The address of account who receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    function sendMessage(
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit
    ) external payable;

    /// @notice Send cross chain message from L1 to L2 or L2 to L1.
    /// @param target The address of account who receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    /// @param refundAddress The address of account who will receive the refunded fee.
    function sendMessage(
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit,
        address refundAddress
    ) external payable;
}