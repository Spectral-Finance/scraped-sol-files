// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LowLevelETHReturnETHIfAny} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelETHReturnETHIfAny.sol";
import {TokenReceiver} from "../TokenReceiver.sol";
import {InvalidOrderLength} from "../libraries/SharedErrors.sol";

/**
 * @title V0Aggregator
 * @notice This contract allows NFT sweepers to buy NFTs from different marketplaces
 *         by passing bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract V0Aggregator is TokenReceiver, LowLevelETHReturnETHIfAny, OwnableTwoSteps {
    struct TradeData {
        address proxy;
        bytes data;
        uint256 value;
    }

    mapping(address => mapping(bytes4 => bool)) private _proxyFunctionSelectors;

    event FunctionAdded(address indexed proxy, bytes4 selector);
    event FunctionRemoved(address indexed proxy, bytes4 selector);
    event Sweep(address indexed sweeper);

    error InvalidFunction();

    constructor(address _owner) OwnableTwoSteps(_owner) {}

    function execute(TradeData[] calldata tradeData) external payable {
        uint256 tradeCount = tradeData.length;
        if (tradeCount == 0) {
            revert InvalidOrderLength();
        }

        for (uint256 i; i < tradeCount; ) {
            bytes calldata data = tradeData[i].data;
            bytes4 selector;

            assembly {
                selector := calldataload(data.offset)
            }

            address proxy = tradeData[i].proxy;
            if (!_proxyFunctionSelectors[proxy][selector]) {
                revert InvalidFunction();
            }

            (bool success, bytes memory returnData) = proxy.delegatecall(data);

            if (!success) {
                if (returnData.length != 0) {
                    assembly {
                        let returnDataSize := mload(returnData)
                        revert(add(32, returnData), returnDataSize)
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny();

        emit Sweep(msg.sender);
    }

    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        _proxyFunctionSelectors[proxy][selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete _proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }
}
