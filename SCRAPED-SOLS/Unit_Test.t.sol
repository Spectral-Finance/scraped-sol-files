// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseTest } from "../BaseTest.sol";
import { FraxEtherRedemptionQueueParams, FraxEtherRedemptionQueue } from "../../contracts/FraxEtherRedemptionQueue.sol";
import { FraxTest } from "frax-std/FraxTest.sol";
import { SigUtils } from "../utils/SigUtils.sol";
import "../Constants.sol" as Constants;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Unit_Test is BaseTest {

    function miscSetup() internal {
        // Do nothing for now
    }

    function testRecoverERC20() public {
        defaultSetup();

        // Redeemer accidentally sends frxETH
        hoax(redeemer);
        frxETH.transfer(redemptionQueueAddress, 10e18);

        // Try recovering the frxETH as the redeemer (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.recoverErc20(address(frxETH), 10e18);

        // Recover the frxETH as the timelock
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.recoverErc20(address(frxETH), 10e18);
    }

    // Will fail unless timelock has a fallback
    function testRecoverEther() public {
        defaultSetup();

        // Give ETH to the redemption queue contract
        vm.deal(redeemer, 10 ether);
        hoax(redeemer);
        redemptionQueueAddress.transfer(10e18);

        // Try recovering the ETH as the redeemer (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.recoverEther(10e18);

        // Try recovering the ETH as the operator (should fail)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, Constants.Mainnet.OPERATOR_ADDRESS));
        redemptionQueue.recoverEther(10e18);

        // Recover half of the ETH as the timelock
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.recoverEther(5e18);

        // Change the timelock to one that cannot accept ETH
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.transferTimelock(Constants.Mainnet.TIMELOCK_ADDRESS_REAL);

        // Accept the new timelock address
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS_REAL);
        redemptionQueue.acceptTransferTimelock();

        // Try to collect the ETH with an address that has no fallback() / receive() (should fail)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS_REAL);
        vm.expectRevert(abi.encodeWithSignature("InvalidETHTransfer()"));
        redemptionQueue.recoverEther(5e18);

        // Change the timelock back to one that can accept ETH
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS_REAL);
        redemptionQueue.transferTimelock(Constants.Mainnet.TIMELOCK_ADDRESS);

        // Accept the new timelock address
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.acceptTransferTimelock();

        // Recover the remaining half of the ETH as the ETH-compatible timelock
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.recoverEther(5e18);
    }


    function testSetOperator() public {
        defaultSetup();

        // Try setting the operator as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.setOperator(redeemer);

        // Set the operator to the frxETH whale (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setOperator(Constants.Mainnet.FRXETH_WHALE);
        assertEq(redemptionQueue.operatorAddress(), Constants.Mainnet.FRXETH_WHALE, "Operator should now be FRXETH_WHALE");
    }

    function testSetFeeRecipient() public {
        defaultSetup();

        // Try setting the fee recipient as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.setFeeRecipient(redeemer);

        // Set the fee recipient to the frxETH whale (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setFeeRecipient(Constants.Mainnet.FRXETH_WHALE);
        assertEq(redemptionQueue.feeRecipient(), Constants.Mainnet.FRXETH_WHALE, "Fee recipient should now be FRXETH_WHALE");
    }

    function testSetMaxOperatorQueueLengthSecs() public {
        defaultSetup();

        // Try setting the max operator queue length as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.setMaxOperatorQueueLengthSeconds(1000);

        // Set the queue length using as the timelock (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setMaxOperatorQueueLengthSeconds(1000);
        uint256 maxOperatorQueueLengthSecs = redemptionQueue.maxOperatorQueueLengthSeconds();
        assertEq(maxOperatorQueueLengthSecs, 1000, "Max Queue length should now be 1000");
    }

    function testSetQueueLengthSecs() public {
        defaultSetup();

        // Try setting the queue length as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("NotTimelockOrOperator()"));
        redemptionQueue.setQueueLengthSeconds(1000);

        // Try to set the queue length above the operator max, as the operator (should fail)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("ExceedsMaxQueueLengthSecs(uint64,uint256)", 105 days, 100 days));
        redemptionQueue.setQueueLengthSeconds(105 days);

        // Try to set the queue length above the operator max, as the timelock (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setQueueLengthSeconds(105 days);

        // Set the queue length using the operator (should pass)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        redemptionQueue.setQueueLengthSeconds(1000);
        (, uint64 queueLengthSecs, , ) = redemptionQueue.redemptionQueueState();
        assertEq(queueLengthSecs, 1000, "Queue length should now be 1000");

        // Set the queue length using the timelock (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setQueueLengthSeconds(5000);
        (, queueLengthSecs, , ) = redemptionQueue.redemptionQueueState();
        assertEq(queueLengthSecs, 5000, "Queue length should now be 5000");
    }

    function testSetEarlyExitFee() public {
        defaultSetup();

        // Try setting the early exit fee as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.setEarlyExitFee(10000);

        // Try to set the early exit fee using the operator (should fail)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, Constants.Mainnet.OPERATOR_ADDRESS));
        redemptionQueue.setEarlyExitFee(10000);

        // Try to set the early exit fee above the max (should fail)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("ExceedsMaxEarlyExitFee(uint64,uint64)", 13371337, 1000000));
        redemptionQueue.setEarlyExitFee(13371337);

        // Set the early exit fee using the timelock (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setEarlyExitFee(10000);
        (, , , uint64 earlyExitFee) = redemptionQueue.redemptionQueueState();
        assertEq(earlyExitFee, 10000, "Early exit fee should now be 10000");
    }

    function testSetRedemptionFee() public {
        defaultSetup();

        // Try setting the redemption fee as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.setRedemptionFee(10000);

        // Try to set the redemption fee using the operator (should fail)
        hoax(Constants.Mainnet.OPERATOR_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, Constants.Mainnet.OPERATOR_ADDRESS));
        redemptionQueue.setRedemptionFee(10000);

        // Try to set the redemption fee above the max (should fail)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("ExceedsMaxRedemptionFee(uint64,uint64)", 13371337, 1000000));
        redemptionQueue.setRedemptionFee(13371337);

        // Set the redemption fee using the timelock (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.setRedemptionFee(10000);
        (, , uint64 redemptionFee, ) = redemptionQueue.redemptionQueueState();
        assertEq(redemptionFee, 10000, "Redemption fee should now be 10000");
    }

    function testTransferAcceptTimelock() public {
        defaultSetup();

        // Try setting the timelock as a random person (should fail)
        hoax(redeemer);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, redeemer));
        redemptionQueue.transferTimelock(redeemer);

        // Set the pending timelock to the redeemer (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.transferTimelock(redeemer);
        assertEq(redemptionQueue.pendingTimelockAddress(), redeemer, "Pending timelock should now be FRXETH_WHALE");

        // Try to accept the timelock credentials as the FRXETH_WHALE (should fail)
        hoax(Constants.Mainnet.FRXETH_WHALE);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotPendingTimelock(address,address)", redeemer, Constants.Mainnet.FRXETH_WHALE));
        redemptionQueue.acceptTransferTimelock();

        // Accept the timelock credentials as the redeemer (should pass)
        hoax(redeemer);
        redemptionQueue.acceptTransferTimelock();
        assertEq(redemptionQueue.timelockAddress(), redeemer, "Timelock should now be the redeemer");
    }


    function testRenounceTimelock() public {
        defaultSetup();

        // Try renouncing the timelock to the redeemer TIMELOCK_ADDRESS as FRXETH_WHALE (should fail)
        hoax(Constants.Mainnet.FRXETH_WHALE);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotTimelock(address,address)", Constants.Mainnet.TIMELOCK_ADDRESS, Constants.Mainnet.FRXETH_WHALE));
        redemptionQueue.renounceTimelock();

        // Try renouncing the timelock before setting TIMELOCK_ADDRESS as pending (should fail)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("AddressIsNotPendingTimelock(address,address)", address(0), Constants.Mainnet.TIMELOCK_ADDRESS));
        redemptionQueue.renounceTimelock();

        // Set the pending timelock as the timelock address too (required for renounce as a safety precaution) (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.transferTimelock(Constants.Mainnet.TIMELOCK_ADDRESS);
        assertEq(redemptionQueue.pendingTimelockAddress(), Constants.Mainnet.TIMELOCK_ADDRESS, "Pending timelock should now be TIMELOCK_ADDRESS");

        // Try renouncing the timelock as the TIMELOCK_ADDRESS (should pass)
        hoax(Constants.Mainnet.TIMELOCK_ADDRESS);
        redemptionQueue.renounceTimelock();
        assertEq(redemptionQueue.timelockAddress(), address(0), "Timelock should now be address(0)");
    }

}
