// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAO is ReentrancyGuard,AccessControl{
    bytes32 private immutable CONTRIBUTOR_ROLE=keccak256("CONTRIBUTOR");
    bytes32 private immutable STAKEHOLDER_ROLE=keccak256("STAKEHOLDER");

    uint256 immutable MIN_STAKEHOLDER_CONTRIBUTION=1 ether;
    uint32 immutable MIN_VOTE_DURATION= 3 minutes;

    uint32 totalProposals;
    uint256 public daoBalance;

    mapping(uint256 => ProposalStruct) private raisedProposals;
    mapping(address=> uint256[]) private stakeholderVotes;
    mapping(uint256=> VotedStruct[]) private votedOn;
    mapping(address => uint256) private contributors;
    mapping(address => uint256) private stakeholders;

    struct ProposalStruct{
        uint256 id;
        uint256 amount;
        uint256 duration;
        uint256 upvotes;
        uint256 downvotes;
        string title;
        string description;
        bool passed;
        bool paid;
        address payable beneficiary;
        address proposer;
        address executor;
    }

    struct VotedStruct{
        address voter;
        uint256 timestamp;
        bool chosen;
    }

    event Action(
        address indexed initiator,
        bytes32 role,
        string message,
        address indexed beneficiary,
        uint256 amount 
    );

    modifier stakeholderOnly(string memory message){
        require(hasRole(STAKEHOLDER_ROLE,msg.sender),message);
        _;
    }

    modifier contributorOnly(string memory message){
        require(hasRole(CONTRIBUTOR_ROLE,msg.sender),message);
        _;
    }

    function createProposal(
        string memory title,
        string memory description,
        address beneficiary,
        uint amount
    ) external stakeholderOnly("proposal creation allowed for the stakeholders only")
    {
        uint32 proposalId=totalProposals++;
        ProposalStruct storage proposal=raisedProposals[proposalId];

        proposal.id=proposalId;
        proposal.proposer=payable(msg.sender);
        proposal.title=title;
        proposal.description=description;
        proposal.beneficiary=payable(beneficiary);
        proposal.amount=amount;
        proposal.duration=block.timestamp+MIN_VOTE_DURATION;

        emit Action(
            msg.sender,
            STAKEHOLDER_ROLE,
            "PROPOSAL RAISED",
            beneficiary,
            amount
        );
    }

    function handleVoting(ProposalStruct storage proposal) private{
        if(
            proposal.passed ||
            proposal.duration<=block.timestamp
        ){
            proposal.passed=true;
            revert("proposal duration expired");
        }

        uint256[] memory tempVotes=stakeholderVotes[msg.sender];
        for(uint256 votes=0;votes<tempVotes.length;votes++){
            if(proposal.id==tempVotes[votes]){
                revert("Double voting not allowed");
            }
        }
    }

    function Vote(uint256 proposalId,bool chosen) external stakeholderOnly("Unauthorized access: Stakeholders only permitted")
    returns (VotedStruct memory){
        ProposalStruct storage proposal=raisedProposals[proposalId];
        handleVoting(proposal);

        if(chosen) proposal.upvotes++;
        else proposal.downvotes++;

        stakeholderVotes[msg.sender].push(proposal.id);

        votedOn[proposal.id].push(
            VotedStruct(
                msg.sender,
                block.timestamp,
                chosen
            )
        );
        emit Action(
            msg.sender,
            STAKEHOLDER_ROLE,
            "PROPOSAL VOTE",
            proposal.beneficiary,
            proposal.amount
        );
        return VotedStruct(
            msg.sender,
            block.timestamp,
            chosen
        );
    }







}


