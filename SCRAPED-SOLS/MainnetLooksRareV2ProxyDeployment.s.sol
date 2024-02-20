// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LooksRareV2ProxyDeployment} from "./LooksRareV2ProxyDeployment.s.sol";

contract MainnetLooksRareV2ProxyDeployment is LooksRareV2ProxyDeployment {
    address private constant LOOKSRARE_V2 = 0x0000000000E655fAe4d56241588680F86E3b2377;

    function run() public {
        if (block.chainid != 1) {
            revert WrongChain();
        }
        _run(LOOKSRARE_V2);
    }
}
