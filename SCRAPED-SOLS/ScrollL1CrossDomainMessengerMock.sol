// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../interfaces/scroll/IScrollMessenger.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Mocks a L1->L2 call by executing the call immediately on the target address on the current chain
contract ScrollL1CrossDomainMessengerMock is IScrollMessenger {
    /// @notice Temporary storage of the mocked msg.sender
    address msgSender;

    /// @notice Returns the mocked L1 sender address
    function xDomainMessageSender() external view returns (address) {
        return msgSender;
    }

    /// @notice Mocks a cross domain call to the given target by executing it immediately on the current chain
    function sendMessage(
        address _target,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit
    ) public payable {
        // Mock xDomainMessageSender to be the caller of this method
        msgSender = msg.sender;
        // Call the target (ignore failure as it can't be handled in a real cross chain environment)
        (bool success,) = _target.call{gas : _gasLimit, value: _value}(_message);
        // Silence unused local variable warning
        assert(success == success);
        // Reset the mocked caller
        msgSender = address(0);
    }

    /// @notice Mocks a cross domain call to the given target by executing it immediately on the current chain
    function sendMessage(
        address _target,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit,
        address /* _refundAddress */
    ) external payable {
        sendMessage(_target, _value, _message, _gasLimit);
        // Ignore refund
    }
}

