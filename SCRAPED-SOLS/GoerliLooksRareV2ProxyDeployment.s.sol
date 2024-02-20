// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LooksRareV2ProxyDeployment} from "./LooksRareV2ProxyDeployment.s.sol";

contract GoerliLooksRareV2ProxyDeployment is LooksRareV2ProxyDeployment {
    address private constant LOOKSRARE_V2 = 0x35C2215F2FFe8917B06454eEEaba189877F200cf;

    function run() public {
        if (block.chainid != 5) {
            revert WrongChain();
        }
        _run(LOOKSRARE_V2);
    }
}
