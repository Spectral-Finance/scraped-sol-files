// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { FXBFactory } from "src/contracts/FXBFactory.sol";
import { SlippageAuction } from "src/contracts/SlippageAuction.sol";
import { SlippageAuctionFactory } from "src/contracts/SlippageAuctionFactory.sol";
import "src/Constants.sol" as Constants;

contract DeployAll is BaseScript {
    // FXBFactory
    FXBFactory public factory;
    address public factoryAddress;

    // SlippageAuctionFactory
    SlippageAuctionFactory public auctionFactory;
    address public auctionFactoryAddress;

    // SlippageAuction
    SlippageAuction public auction;
    address public auctionAddress;

    constructor() {}

    function run() public {
        vm.startBroadcast();

        // Deploy the contracts
        // ======================

        // FXBFactory
        factory = new FXBFactory(Constants.Mainnet.TIMELOCK_ADDRESS, address(Constants.Mainnet.FRAX_ERC20));
        factoryAddress = address(factory);

        //AuctionFactory
        auctionFactory = new SlippageAuctionFactory();
        auctionFactoryAddress = address(auctionFactory);

        vm.stopBroadcast();
    }
}
