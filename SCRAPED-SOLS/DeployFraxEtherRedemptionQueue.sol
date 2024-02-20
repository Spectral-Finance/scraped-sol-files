// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
import { IFrxEth } from "src/contracts/IFrxEth.sol";
import { FraxEtherRedemptionQueue, FraxEtherRedemptionQueueParams } from "src/contracts/FraxEtherRedemptionQueue.sol";
import "src/test/Constants.sol" as ConstantsDep;

struct DeployFraxEtherRedemptionQueueReturn {
    address _address;
    bytes constructorParams;
    string contractName;
}

function deployFraxEtherRedemptionQueue() returns (DeployFraxEtherRedemptionQueueReturn memory _return) {
    FraxEtherRedemptionQueueParams memory _params = FraxEtherRedemptionQueueParams({
        timelockAddress: ConstantsDep.Mainnet.TIMELOCK_ADDRESS,
        operatorAddress: ConstantsDep.Mainnet.OPERATOR_ADDRESS,
        frxEthAddress: ConstantsDep.Mainnet.FRXETH_ADDRESS,
        initialQueueLengthSeconds: 604800 // One week
    });

    _return.constructorParams = abi.encode(_params);
    _return.contractName = "FraxEtherRedemptionQueue";
    _return._address = address(new FraxEtherRedemptionQueue(_params));
}



contract DeployFraxEtherRedemptionQueue is BaseScript {
    function run()
        external
        broadcaster
        returns (DeployFraxEtherRedemptionQueueReturn memory _return)
    {
        _return = deployFraxEtherRedemptionQueue();
        console.log("_constructorParams:");
        console.logBytes(_return.constructorParams);
        console.log("_address:", _return._address);
    }
}
