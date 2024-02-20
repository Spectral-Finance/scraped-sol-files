// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "./DelegatedOps.sol";
import "./SystemStart.sol";
import "../interfaces/ITokenLocker.sol";

contract AdminVoting is DelegatedOps, SystemStart {
    using Address for address;

    event ProposalCreated(address indexed account, Action[] payload, uint256 week, uint256 requiredWeight);
    event ProposalExecuted(uint256 proposalId);
    event VoteCast(address indexed account, uint256 id, uint256 weight, uint proposalCurrentWeight);
    event ProposalCreationMinWeightSet(uint256 weight);
    event ProposalPassingPctSet(uint256 pct);

    struct Proposal {
        uint16 week; // week which vote weights are based upon
        uint32 createdAt; // timestamp when the proposal was created
        uint40 currentWeight; //  amount of weight currently voting in favor
        uint40 requiredWeight; // amount of weight required for the proposal to be executed
        bool executed; // set to true once the proposal is executed
    }

    struct Action {
        address target;
        bytes data;
    }

    Proposal[] proposalData;
    mapping(uint => Action[]) proposalPayloads;

    // account -> ID -> amount of weight voted in favor
    mapping(address => mapping(uint => uint)) public accountVoteWeights;

    uint256 public constant VOTING_PERIOD = 1 weeks;
    uint256 public constant MIN_TIME_TO_EXECUTION = 86400;

    // absolute amount of weight required to create a new proposal
    uint256 public minCreateProposalWeight;
    // percent of total weight that must vote for a proposal before it can be executed
    uint256 public passingPct;

    ITokenLocker public immutable tokenLocker;

    constructor(address _addressProvider, ITokenLocker _tokenLocker) SystemStart(_addressProvider) {
        tokenLocker = _tokenLocker;
    }

    /**
        @notice The total number of votes created
     */
    function getProposalCount() external view returns (uint256) {
        return proposalData.length;
    }

    /**
        @notice Gets information on a specific proposal
     */
    function getProposalData(
        uint id
    )
        external
        view
        returns (
            uint week,
            uint createdAt,
            uint currentWeight,
            uint requiredWeight,
            bool executed,
            bool canExecute,
            Action[] memory payload
        )
    {
        Proposal memory proposal = proposalData[id];
        payload = proposalPayloads[id];
        canExecute = (!proposal.executed &&
            proposal.currentWeight >= proposal.requiredWeight &&
            proposal.createdAt + MIN_TIME_TO_EXECUTION < block.timestamp);

        return (
            proposal.week,
            proposal.createdAt,
            proposal.currentWeight,
            proposal.requiredWeight,
            proposal.executed,
            canExecute,
            payload
        );
    }

    /**
        @notice Create a new proposal
        @param payload Tuple of [(target address, calldata), ... ] to be
                       executed if the proposal is passed.
     */
    function createNewProposal(address account, Action[] calldata payload) external callerOrDelegated(account) {
        require(payload.length > 0, "Empty payload");

        // week is set at -1 to the active week so that weights are finalized
        uint week = getWeek();
        require(week > 0, "No proposals in first week");
        week -= 1;

        uint accountWeight = tokenLocker.getAccountWeightAt(account, week);
        require(accountWeight >= minCreateProposalWeight, "Not enough weight to propose");
        uint totalWeight = tokenLocker.getTotalWeightAt(week);
        uint40 requiredWeight = uint40((totalWeight * passingPct) / 100);
        proposalData.push(
            Proposal({
                week: uint16(week),
                createdAt: uint32(block.timestamp),
                currentWeight: 0,
                requiredWeight: requiredWeight,
                executed: false
            })
        );
        uint idx = proposalData.length;

        for (uint i = 0; i < payload.length; i++) {
            proposalPayloads[idx].push(payload[i]);
        }
        emit ProposalCreated(account, payload, week, requiredWeight);
    }

    /**
        @notice Vote in favor of a proposal
        @dev Each account can vote once per proposal
        @param id Proposal ID
        @param weight Weight to allocate to this action. If set to zero, the full available
                      account weight is used. Integrating protocols may wish to use partial
                      weight to reflect partial support from their own users.
     */
    function voteForProposal(address account, uint id, uint weight) external callerOrDelegated(account) {
        require(id < proposalData.length, "Invalid ID");
        require(accountVoteWeights[account][id] == 0, "Already voted");

        Proposal memory proposal = proposalData[id];
        require(!proposal.executed, "Vote was already executed");
        require(proposal.createdAt + VOTING_PERIOD > block.timestamp, "Voting period has closed");

        uint accountWeight = tokenLocker.getAccountWeightAt(account, proposal.week);
        if (weight == 0) {
            weight = accountWeight;
            require(weight > 0, "No vote weight");
        } else {
            require(weight <= accountWeight, "Weight exceeds account weight");
        }

        accountVoteWeights[account][id] = weight;
        uint40 updatedWeight = uint40(proposal.currentWeight + weight);
        proposalData[id].currentWeight = updatedWeight;
        emit VoteCast(account, id, weight, updatedWeight);
    }

    /**
        @notice Execute a proposal's payload
        @dev Can only be called if the proposal has received sufficient vote weight,
             and has been active for at least `MIN_TIME_TO_EXECUTION`
        @param id Proposal ID
     */
    function executeProposal(uint id) external {
        require(id < proposalData.length, "Invalid ID");
        Proposal memory proposal = proposalData[id];
        require(proposal.currentWeight >= proposal.requiredWeight, "Not passed");
        require(proposal.createdAt + MIN_TIME_TO_EXECUTION < block.timestamp, "MIN_TIME_TO_EXECUTION");
        require(!proposal.executed, "Already executed");
        proposalData[id].executed = true;

        Action[] storage payload = proposalPayloads[id];
        uint payloadLength = payload.length;

        for (uint i = 0; i < payloadLength; i++) {
            payload[i].target.functionCall(payload[i].data);
        }
        emit ProposalExecuted(id);
    }

    /**
        @notice Set the minimum absolute weight required to create a new proposal
        @dev Only callable via a passing proposal that includes a call
             to this contract and function within it's payload
     */
    function setMinCreateProposalWeight(uint weight) external returns (bool) {
        require(msg.sender == address(this), "Only callable via proposal");
        minCreateProposalWeight = weight;
        emit ProposalCreationMinWeightSet(weight);
        return true;
    }

    /**
        @notice Set the required % of the total weight that must vote
                for a proposal prior to being able to execute it
        @dev Only callable via a passing proposal that includes a call
             to this contract and function within it's payload
     */
    function setPassingPct(uint pct) external returns (bool) {
        require(msg.sender == address(this), "Only callable via proposal");
        require(pct <= 100, "Invalid value");
        passingPct = pct;
        emit ProposalPassingPctSet(pct);
        return true;
    }
}
