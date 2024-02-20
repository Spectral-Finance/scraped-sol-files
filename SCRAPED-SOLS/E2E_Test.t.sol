// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseTest } from "../BaseTest.sol";
import { FraxEtherRedemptionQueueParams, FraxEtherRedemptionQueue } from "../../contracts/FraxEtherRedemptionQueue.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { SigUtils } from "../utils/SigUtils.sol";
import "../Constants.sol" as Constants;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract E2E_Test is BaseTest {

    function e2eSetup() internal {
        // Do nothing for now
    }

    function testEnterRedemptionQueue() public {
        defaultSetup();

        // Switch to the redeemer
        vm.startPrank(redeemer);

        // Approve the 100 frxETH
        frxETH.approve(redemptionQueueAddress, 100e18);

        // Enter the queue with the recipient not supporting ERC721 (should fail)
        vm.expectRevert(bytes("ERC721: transfer to non ERC721Receiver implementer"));
        redemptionQueue.enterRedemptionQueue( payable(0x853d955aCEf822Db058eb8505911ED77F175b99e), 100e18);

        // Enter the queue normally
        redemptionQueue.enterRedemptionQueue(redeemer, 100e18);
        assertEq(frxETH.balanceOf(redeemer), 0, "Redeemer should have 0 frxETH after entering the queue");

        vm.stopPrank();
    }

    function testEnterRedemptionQueueWithPermit() public {
        defaultSetup();

        // Switch to the redeemer
        vm.startPrank(redeemer);

        // Sign the permit for 100 frxETH
        uint120 redeem_amt = 100e18;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: redeemer,
            spender: redemptionQueueAddress,
            value: redeem_amt,
            nonce: frxETH.nonces(redeemer),
            deadline: block.timestamp + (1 days)
        });
        bytes32 digest = sigUtils_frxETH.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(redeemerPrivateKey, digest);

        // Enter the queue using the permit
        redemptionQueue.enterRedemptionQueueWithPermit(
            redeem_amt,
            redeemer,
            permit.deadline,
            v,
            r,
            s
        );
        assertEq(frxETH.balanceOf(redeemer), 0, "Redeemer should have 0 frxETH after entering the queue");
    }


    function testEarlyPenalizedNFTRedemption() public {
        defaultSetup();

        // Set the redemption fee to 10%
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setRedemptionFee(100000);

        // Set the early exit penalty fee to 5%
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setEarlyExitFee(50000);

        // Give the redeemer an extra 5 frxETH
        hoax(Constants.Mainnet.FRXETH_WHALE);
        frxETH.transfer(redeemer, 5e18);

        // Switch to the redeemer
        vm.startPrank(redeemer);

        // Approve the 105 frxETH
        frxETH.approve(redemptionQueueAddress, 105e18);

        // Enter the queue using the approve (first NFT)
        redemptionQueue.enterRedemptionQueue(redeemer, 100e18);
        assertEq(frxETH.balanceOf(redeemer), 5 ether, "Redeemer should have 5 frxETH after entering the queue");

        // Enter the queue using the approve (second NFT)
        redemptionQueue.enterRedemptionQueue(redeemer, 4e18);
        assertEq(frxETH.balanceOf(redeemer), 1 ether, "Redeemer should have 1 frxETH after entering the queue");

        // Enter the queue using the approve (third NFT)
        redemptionQueue.enterRedemptionQueue(redeemer, 1e18);
        assertEq(frxETH.balanceOf(redeemer), 0, "Redeemer should have 0 frxETH after entering the queue");

        // Give the redemptionQueue some ETH
        vm.deal(redemptionQueueAddress, 105 ether);

        vm.stopPrank();

        // Try to early exit not as the owner (should fail)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("Erc721CallerNotOwnerOrApproved()"));
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);

        // Try to early exit a non-existent NFT (should fail)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        redemptionQueue.burnRedemptionTicketNft(666, redeemer);

        vm.startPrank(redeemer);

        // Early exit, first token
        ( , uint256 _initialUnclaimedFees) = redemptionQueue.redemptionQueueAccounting();
        uint120 frxeth_out = redemptionQueue.earlyBurnRedemptionTicketNft(redeemer, 0);
        ( , uint256 _finalUnclaimedFees) = redemptionQueue.redemptionQueueAccounting();
        assertEq(frxeth_out, 855e17, "Redeemer should have gotten 85.5 frxETH from the redemption");
        assertEq(_finalUnclaimedFees - _initialUnclaimedFees, 45e17, "4.5 frxETH should have been burned");

        // Early exit, second token (3rd-party approved)
        // ---------------------------------

        // Approve FRXETH_WHALE to do the redeeming for the second NFT
        redemptionQueue.approve(Constants.Mainnet.FRXETH_WHALE, 1);

        // Approve OPERATOR_ADDRESS to use any NFTs that the redeemer owns
        redemptionQueue.setApprovalForAll(Constants.Mainnet.OPERATOR_ADDRESS, true);

        vm.stopPrank();

        // 3rd-party redeem the 2nd NFT
        hoax(Constants.Mainnet.FRXETH_WHALE);
        redemptionQueue.earlyBurnRedemptionTicketNft(redeemer, 1);

        // 3rd-party redeem the 3rd NFT
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        redemptionQueue.earlyBurnRedemptionTicketNft(redeemer, 2);

        vm.startPrank(redeemer);

        // Try to early exit an already-early-exited NFT (should fail)
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);

        // Wait until after the maturity
        mineBlocksBySecond(2 weeks);

        // Try to redeem an already-early-exited NFT after maturity (should fail)
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);

        vm.stopPrank();

        // Operator triggers redemption fee collection
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        redemptionQueue.collectRedemptionFees(10 ether);

    }




    function testRedeemRedemptionTicketNFT() public {
        defaultSetup();

        // Set the redemption fee to 10% first
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setRedemptionFee(100000);

        // Switch to the redeemer
        vm.startPrank(redeemer);

        // Approve the 100 frxETH
        frxETH.approve(redemptionQueueAddress, 100e18);

        // Enter the queue using the approve
        redemptionQueue.enterRedemptionQueue(redeemer, 100e18);
        assertEq(frxETH.balanceOf(redeemer), 0, "Redeemer should have 0 frxETH after entering the queue");

        // Give the redemptionQueue some ETH
        vm.deal(redemptionQueueAddress, 100 ether);

        // Try to redeem the NFT early (should fail)
        ( , uint64 maturityTime, , ) = redemptionQueue.nftInformation(0);
        vm.expectRevert(abi.encodeWithSelector(FraxEtherRedemptionQueue.NotMatureYet.selector, block.timestamp, maturityTime));
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);

        // Wait until after the maturity
        mineBlocksBySecond(2 weeks);

        // Try to redeem the NFT to a non-payable contract (should fail)
        vm.expectRevert();
        redemptionQueue.burnRedemptionTicketNft(0, payable(0x853d955aCEf822Db058eb8505911ED77F175b99e));

        // Try to redeem the NFT again (should work this time)
        uint256 eth_before = redeemer.balance;
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);
        assertEq(redeemer.balance - eth_before, 90 ether, "Redeemer should have gained ETH after redeeming the NFT");

        // Wait 2 weeks again
        mineBlocksBySecond(2 weeks);

        // Try to redeem an already-redeemed NFT (should fail)
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);

        vm.stopPrank();

        // Operator triggers redemption fee collection
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        redemptionQueue.collectRedemptionFees(10 ether);

    }

    function testcollectRedemptionFees() public {
        defaultSetup();

        // Set the redemption fee to 10% first
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setRedemptionFee(100_000);

        // Switch to the redeemer
        vm.startPrank(redeemer);

        // Approve the 100 frxETH
        frxETH.approve(redemptionQueueAddress, 100e18);

        // Enter the queue using the approve
        redemptionQueue.enterRedemptionQueue(redeemer, 100e18);
        assertEq(frxETH.balanceOf(redeemer), 0, "Redeemer should have 0 frxETH after entering the queue");

        // Give the redemptionQueue some ETH
        vm.deal(redemptionQueueAddress, 100 ether);

        // Wait until after the maturity
        mineBlocksBySecond(2 weeks);

        // Redeem the NFT
        uint256 eth_before = redeemer.balance;
        redemptionQueue.burnRedemptionTicketNft(0, redeemer);
        assertEq(redeemer.balance - eth_before, 90 ether, "Redeemer should have gained ETH after redeeming the NFT");

        vm.stopPrank();

        // Random person tries to collect the fee (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("NotTimelockOrOperator()"));
        redemptionQueue.collectRedemptionFees(10 ether);

        // Operator triggers part of the fee to be collected
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        redemptionQueue.collectRedemptionFees(3 ether);

        // Operator tries trigger over-collection of fees (should fail)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("ExceedsCollectedFees(uint128,uint128)", 50 ether, 7 ether));
        redemptionQueue.collectRedemptionFees(50 ether);
    }
}
