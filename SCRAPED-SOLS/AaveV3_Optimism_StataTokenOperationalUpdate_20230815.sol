// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {IStaticATokenFactory} from './IStaticATokenFactory.sol';

/**
 * @title stataToken operational update
 * @author BGD labs
 * - Snapshot: TODO
 * - Discussion: https://governance.aave.com/t/bgd-statatoken-operational-update/14497
 */
contract AaveV3_Optimism_StataTokenOperationalUpdate_20230815 is IProposalGenericExecutor {
  address public constant NEW_ADMIN = 0x043f9687842771b3dF8852c1E9801DCAeED3f6bc;

  function execute() external {
    address[] memory tokens = IStaticATokenFactory(AaveV3Optimism.STATIC_A_TOKEN_FACTORY)
      .getStaticATokens();
    for (uint256 i; i < tokens.length; i++) {
      ProxyAdmin(AaveMisc.PROXY_ADMIN_OPTIMISM).changeProxyAdmin(
        TransparentUpgradeableProxy(payable(tokens[i])),
        NEW_ADMIN
      );
    }
  }
}
