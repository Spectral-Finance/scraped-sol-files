// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {IImmutableCreate2Factory} from "../../contracts/interfaces/IImmutableCreate2Factory.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {Seaport_V1_4_ProxyTestHelpers} from "./Seaport_V1_4_ProxyTestHelpers.sol";

contract DeploymentTest is TestParameters, TestHelpers, Seaport_V1_4_ProxyTestHelpers {
    IImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        IImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    function testDeploymentAddresses() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16_744_216);

        address deployer = vm.envAddress("LOOKS_RARE_DEPLOYER");

        vm.startPrank(deployer);

        address looksRareAggregatorAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(type(LooksRareAggregator).creationCode, abi.encode(deployer))
        });

        assertEq(looksRareAggregatorAddress, 0x00000000005228B791a99a61f36A130d50600106);
        assertEq(LooksRareAggregator(payable(looksRareAggregatorAddress)).owner(), deployer);

        address erc20EnabledLooksRareAggregatorAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("ERC20_ENABLED_LOOKS_RARE_AGGREGATOR_SALT"),
            initializationCode: abi.encodePacked(
                type(ERC20EnabledLooksRareAggregator).creationCode,
                abi.encode(looksRareAggregatorAddress)
            )
        });

        assertEq(erc20EnabledLooksRareAggregatorAddress, 0x0000000000a35231D7706BD1eE827d43245655aB);
        assertEq(
            address(ERC20EnabledLooksRareAggregator(payable(erc20EnabledLooksRareAggregatorAddress)).aggregator()),
            looksRareAggregatorAddress
        );

        address looksRareProxyAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("LOOKS_RARE_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(LooksRareProxy).creationCode,
                abi.encode(LOOKSRARE_V1, looksRareAggregatorAddress)
            )
        });

        assertEq(looksRareProxyAddress, 0x0000000000DA151039Ed034d1C5BACb47C284Ed1);
        LooksRareProxy looksRareProxy = LooksRareProxy(payable(looksRareProxyAddress));
        assertEq(address(looksRareProxy.marketplace()), LOOKSRARE_V1);
        assertEq(looksRareProxy.aggregator(), looksRareAggregatorAddress);

        address seaportProxyAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2({
            salt: vm.envBytes32("SEAPORT_PROXY_SALT"),
            initializationCode: abi.encodePacked(
                type(SeaportProxy).creationCode,
                abi.encode(SEAPORT, looksRareAggregatorAddress)
            )
        });

        assertEq(seaportProxyAddress, 0x0000000000aD2C5a35209EeAb701B2CD49BA3A0D);
        SeaportProxy seaportProxy = SeaportProxy(payable(seaportProxyAddress));
        assertEq(address(seaportProxy.marketplace()), SEAPORT);
        assertEq(seaportProxy.aggregator(), looksRareAggregatorAddress);

        vm.stopPrank();
    }
}
