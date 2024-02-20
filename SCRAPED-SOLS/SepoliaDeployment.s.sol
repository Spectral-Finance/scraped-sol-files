// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Deployment} from "./Deployment.s.sol";

contract SepoliaDeployment is Deployment {
    address private constant LOOKSRARE = 0x34098cc15a8a48Da9d3f31CC0F63F01f9aa3D9F3;
    // Using Seaport 1.5 here instead of 1.4
    address private constant SEAPORT = 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC;

    function run() public {
        if (block.chainid != 11155111) {
            revert WrongChain();
        }
        _run(LOOKSRARE, SEAPORT);
    }
}
