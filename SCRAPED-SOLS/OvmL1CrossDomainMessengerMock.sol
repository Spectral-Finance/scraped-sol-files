// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Mocks a L1->L2 call by executing the call immediately on the target address on the current chain
contract OvmL1CrossDomainMessengerMock is ICrossDomainMessenger {
    /// @notice Temporary storage of the mocked msg.sender
    address msgSender;

    /// @notice Returns the mocked L1 sender address
    function xDomainMessageSender() external view returns (address) {
        return msgSender;
    }

    /// @notice Mocks a cross domain call to the given target by executing it immediately on the current chain
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external {
        // Mock xDomainMessageSender to be the caller of this method
        msgSender = msg.sender;
        // Call the target (ignore failure as it can't be handled in a real cross chain environment)
        (bool success,) = _target.call{gas : _gasLimit}(_message);
        // Silence unused local variable warning
        assert(success == success);
        // Reset the mocked caller
        msgSender = address(0);
    }
}
