// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {SeaportProxy} from "../../../contracts/proxies/SeaportProxy.sol";
import {IImmutableCreate2Factory} from "../../../contracts/interfaces/IImmutableCreate2Factory.sol";

contract Seaport_V1_5_ProxyDeployment is Script {
    IImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    address private constant LOOKS_RARE_AGGREGATOR = 0x00000000005228B791a99a61f36A130d50600106;
    address private constant SEAPORT_V1_5 = 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("SEAPORT_V1_5_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(SeaportProxy).creationCode,
                abi.encode(SEAPORT_V1_5, LOOKS_RARE_AGGREGATOR)
            )
        });

        vm.stopBroadcast();
    }
}
