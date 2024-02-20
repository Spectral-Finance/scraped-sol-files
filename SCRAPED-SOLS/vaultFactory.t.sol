//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { LiquidityBaseTest } from "../../liquidity/liquidityBaseTest.t.sol";
import { ILiquidityLogic } from "../../../../contracts/liquidity/interfaces/iLiquidity.sol";
import { VaultT1 } from "../../../../contracts/protocols/vault/vaultT1/coreModule/main.sol";
import { VaultT1Secondary } from "../../../../contracts/protocols/vault/vaultT1/coreModule/main2.sol";
import { VaultT1Admin } from "../../../../contracts/protocols/vault/vaultT1/adminModule/main.sol";
import { MockOracle } from "../../../../contracts/mocks/mockOracle.sol";
import { VaultFactory } from "../../../../contracts/protocols/vault/factory/main.sol";
import { VaultT1DeploymentLogic } from "../../../../contracts/protocols/vault/factory/deploymentLogics/vaultT1Logic.sol";

import "../../testERC20.sol";
import "../../testERC20Dec6.sol";
import "../../../../contracts/protocols/lending/lendingRewardsRateModel/main.sol";

contract VaultFactoryTest is LiquidityBaseTest {
    using stdStorage for StdStorage;

    VaultFactory vaultFactory;
    VaultT1DeploymentLogic vaultT1Deployer;
    address vaultAdminImplementation_;
    address vaultSecondaryImplementation_;

    function setUp() public virtual override {
        super.setUp();

        vaultFactory = new VaultFactory(admin);
        vm.prank(admin);
        vaultFactory.setDeployer(alice, true);
        vaultAdminImplementation_ = address(new VaultT1Admin());
        vaultSecondaryImplementation_ = address(new VaultT1Secondary());
        vaultT1Deployer = new VaultT1DeploymentLogic(
            address(liquidity),
            vaultAdminImplementation_,
            vaultSecondaryImplementation_
        );

        vm.prank(admin);
        vaultFactory.setGlobalAuth(alice, true);
        vm.prank(admin);
        vaultFactory.setVaultDeploymentLogic(address(vaultT1Deployer), true);
    }

    function testDeployNewVault() public {
        MockOracle oracle = new MockOracle();

        VaultT1Admin vaultWithAdmin_;

        vm.prank(alice);

        bytes memory vaultT1CreationCode = abi.encodeCall(vaultT1Deployer.vaultT1, (address(USDC), address(DAI)));

        address vault = vaultFactory.deployVault(address(vaultT1Deployer), vaultT1CreationCode);

        // Updating admin related things to setup vault
        vaultWithAdmin_ = VaultT1Admin(address(vault));
        vm.prank(alice);
        vaultWithAdmin_.updateCoreSettings(
            10000, // supplyFactor_ => 100%
            10000, // borrowFactor_ => 100%
            8000, // collateralFactor_ => 80%
            9000, // liquidationThreshold_ => 90%
            9500, // liquidationMaxLimit_ => 95%
            500, // withdrawGap_ => 5%
            100, // liquidationPenalty_ => 1%
            100 // borrowFee_ => 1%
        );
        vm.prank(alice);
        vaultWithAdmin_.updateOracle(address(oracle));
        vm.prank(alice);
        vaultWithAdmin_.updateRebalancer(address(admin));

        console.log("Vault Address", vault);
        assertNotEq(vault, address(0));

        uint256 vaultId = VaultT1(vault).VAULT_ID();
        console.log("Vault Id", vaultId);

        address computedVaultAddress = vaultFactory.getVaultAddress(vaultId);
        console.log("Computed Vault Address", computedVaultAddress);
        assertEq(vault, computedVaultAddress);

        // TODO: asset all the variables are set correctly.
    }

    function _deployVault(uint64 nonce) internal {
        vm.setNonceUnsafe(address(vaultFactory), nonce);
        stdstore.target(address(vaultFactory)).sig("totalVaults()").checked_write(nonce - 1);
        vm.startPrank(alice);
        nonce = vm.getNonce(address(vaultFactory));
        bytes memory vaultT1CreationCode = abi.encodeCall(vaultT1Deployer.vaultT1, (address(USDC), address(DAI)));
        address vault = vaultFactory.deployVault(address(vaultT1Deployer), vaultT1CreationCode);
        uint256 vaultId = VaultT1(vault).VAULT_ID();
        address computedVaultAddress = vaultFactory.getVaultAddress(vaultId);
        console.log("Computed Vault Address for vaultId '%s' with nonce '%s': ", vaultId, nonce, computedVaultAddress);
        assertEq(vault, computedVaultAddress);
    }

    // function testComputeAddress() public {
    //     // nonce of deployment starts with 1.
    //     uint32[20] memory nonces = [1, 2, 3, 10, 126, 127, 128, 129, 254, 255, 256, 257, 65534, 65535, 65536, 65537, 16777214, 16777215, 16777216, 16777217];

    //     for (uint256 i = 0; i < nonces.length; i++) {
    //         _deployVault(uint64(nonces[i]));
    //     }
    // }
}
