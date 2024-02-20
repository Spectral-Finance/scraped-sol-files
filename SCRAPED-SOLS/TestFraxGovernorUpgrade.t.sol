// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./FraxGovernorTestBase.t.sol";

contract TestFraxGovernorUpgrade is FraxGovernorTestBase {
    IFraxGovernorAlpha fraxGovernorAlphaUpgrade;
    TimelockController timelockControllerUpgrade;
    IFraxGovernorOmega fraxGovernorOmegaUpgrade;
    FraxGuard fraxGuardUpgrade;
    FraxCompatibilityFallbackHandler fraxCompatibilityFallbackHandlerUpgrade;

    function _upgradeSetUp() internal {
        (address payable _timelockController, , ) = deployTimelockController(address(this));
        timelockControllerUpgrade = TimelockController(_timelockController);

        (address payable _fraxGovernorAlpha, , ) = deployFraxGovernorAlpha(
            address(veFxs),
            address(veFxsVotingDelegation),
            _timelockController
        );
        fraxGovernorAlphaUpgrade = IFraxGovernorAlpha(_fraxGovernorAlpha);

        timelockControllerUpgrade.grantRole(timelockControllerUpgrade.PROPOSER_ROLE(), _fraxGovernorAlpha);
        timelockControllerUpgrade.grantRole(timelockControllerUpgrade.EXECUTOR_ROLE(), _fraxGovernorAlpha);
        timelockControllerUpgrade.grantRole(timelockControllerUpgrade.CANCELLER_ROLE(), _fraxGovernorAlpha);
        timelockControllerUpgrade.renounceRole(timelockControllerUpgrade.TIMELOCK_ADMIN_ROLE(), address(this));

        address[] memory safeAllowlist = new address[](1);
        safeAllowlist[0] = address(multisig);

        address[] memory delegateCallAllowlist = new address[](1);
        delegateCallAllowlist[0] = address(signMessageLib);

        (address payable _fraxGovernorOmega, , ) = deployFraxGovernorOmega(
            address(veFxs),
            address(veFxsVotingDelegation),
            safeAllowlist,
            delegateCallAllowlist,
            _timelockController
        );
        fraxGovernorOmegaUpgrade = IFraxGovernorOmega(_fraxGovernorOmega);

        assertEq(
            1,
            fraxGovernorOmegaUpgrade.$safeAllowlist(address(multisig)),
            "New omega allowlist configuration is set on deploy"
        );

        (address _fraxCompatibilityFallbackHandler, ) = deployFraxCompatibilityFallbackHandler();
        fraxCompatibilityFallbackHandlerUpgrade = FraxCompatibilityFallbackHandler(_fraxCompatibilityFallbackHandler);

        (address _fraxGuard, , ) = deployFraxGuard(_fraxGovernorOmega);
        fraxGuardUpgrade = FraxGuard(_fraxGuard);
    }

    function setUp() public virtual override {
        super.setUp();
        _upgradeSetUp();
    }

    // create and execute proposal to remove old frxGov from multisig and set up with new frxGov
    function testUpgradeGovernance() public {
        address[] memory targets = new address[](6);
        uint256[] memory values = new uint256[](6);
        bytes[] memory calldatas = new bytes[](6);
        DeployedSafe _safe = getSafe(address(multisig)).safe;

        // Switch fraxGuard to new one
        targets[0] = address(multisig);
        calldatas[0] = genericAlphaSafeProposalData(
            address(multisig),
            0,
            abi.encodeWithSignature("setGuard(address)", address(fraxGuardUpgrade)),
            Enum.Operation.Call
        );

        // Add new timelock as module
        targets[1] = address(multisig);
        calldatas[1] = genericAlphaSafeProposalData(
            address(multisig),
            0,
            abi.encodeWithSignature("enableModule(address)", address(fraxGovernorAlphaUpgrade)),
            Enum.Operation.Call
        );

        // Swap owner oldOmega to new omega
        targets[2] = address(multisig);
        calldatas[2] = genericAlphaSafeProposalData(
            address(multisig),
            0,
            abi.encodeWithSignature(
                "swapOwner(address,address,address)",
                address(0x1), // prevOwner
                address(fraxGovernorOmega), // oldOwner
                address(fraxGovernorOmegaUpgrade) // newOwner
            ),
            Enum.Operation.Call
        );

        // Remove safe from old omega allowlist
        address[] memory _safesToRemoveFromAllowlist = new address[](1);
        _safesToRemoveFromAllowlist[0] = address(multisig);

        targets[3] = address(fraxGovernorOmega);
        calldatas[3] = abi.encodeWithSelector(
            IFraxGovernorOmega.removeFromSafeAllowlist.selector,
            _safesToRemoveFromAllowlist
        );

        // Remove old timelock as module
        targets[4] = address(multisig);
        calldatas[4] = genericAlphaSafeProposalData(
            address(multisig),
            0,
            abi.encodeWithSignature(
                "disableModule(address,address)",
                address(fraxGovernorAlphaUpgrade), // prevModule
                address(fraxGovernorAlpha) // module
            ),
            Enum.Operation.Call
        );

        targets[5] = address(multisig);
        calldatas[5] = genericAlphaSafeProposalData(
            address(multisig),
            0,
            abi.encodeWithSignature("setFallbackHandler(address)", address(fraxCompatibilityFallbackHandlerUpgrade)),
            Enum.Operation.Call
        );

        hoax(accounts[0]);
        uint256 proposalId = fraxGovernorAlpha.propose(targets, values, calldatas, "");

        mineBlocksBySecond(fraxGovernorAlpha.votingDelay() + 1);
        vm.roll(block.number + 1);

        for (uint256 i = 0; i < accounts.length; ++i) {
            if (uint256(fraxGovernorAlpha.state(proposalId)) == uint256(IGovernor.ProposalState.Active)) {
                hoax(accounts[i]);
                fraxGovernorAlpha.castVote(proposalId, uint8(GovernorCompatibilityBravo.VoteType.For));
            }
        }

        mineBlocksBySecond(fraxGovernorAlpha.votingPeriod());

        assertEq(
            uint256(IGovernor.ProposalState.Succeeded),
            uint256(fraxGovernorAlpha.state(proposalId)),
            "Proposal state is succeeded"
        );

        fraxGovernorAlpha.queue(targets, values, calldatas, keccak256(bytes("")));

        vm.warp(fraxGovernorAlpha.proposalEta(proposalId));

        fraxGovernorAlpha.execute(targets, values, calldatas, keccak256(bytes("")));

        assertEq(
            uint256(IGovernor.ProposalState.Executed),
            uint256(fraxGovernorAlpha.state(proposalId)),
            "Proposal state is executed"
        );

        assertEq(
            address(fraxGuardUpgrade),
            _bytesToAddress(_safe.getStorageAt({ offset: GUARD_STORAGE_OFFSET, length: 1 })),
            "New Frax Guard is set"
        );

        assertEq(
            address(fraxCompatibilityFallbackHandlerUpgrade),
            _bytesToAddress(_safe.getStorageAt({ offset: FALLBACK_HANDLER_OFFSET, length: 1 })),
            "New FraxCompatibilityFallbackHandlerUpgrade is set"
        );

        assertTrue(_safe.isModuleEnabled(address(fraxGovernorAlphaUpgrade)), "New Alpha is a module");

        assertFalse(_safe.isOwner(address(fraxGovernorOmega)), "Old Omega removed as safe owner");

        assertTrue(_safe.isOwner(address(fraxGovernorOmegaUpgrade)), "New Omega is safe owner");

        assertEq(fraxGovernorOmega.$safeAllowlist(address(multisig)), 0, "Removed safe from old omega allowlist");

        assertFalse(_safe.isModuleEnabled(address(fraxGovernorAlpha)), "Old Alpha removed as module");

        assertEq(_safe.getOwners().length, 6, "6 total safe owners");
        assertEq(_safe.getThreshold(), 3, "3 signatures required");
    }
}
