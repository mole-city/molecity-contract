pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract GovernorAlpha {
    /// @notice The name of this contract
    string public constant name = "Mole City's Governor Alpha";

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public quorumVotes;

    /// @notice The number of votes required in order for a voter to become a proposer
    uint public proposalThreshold;

    /// @notice The delay before voting on a proposal may take place, once proposed, in seconds
    uint public votingDelay;

    /// @notice The duration of voting on a proposal, in seconds
    uint public votingPeriod;
    
    ///@notice The last time to execute a proposal, in seconds
    uint public executingDelay;

    /// @notice The address of the MoleDaoVoteRelay
    MoleDaoVoteRelayInterface public moleDaoVoteRelay;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice The timestamp at which voting begins: holders must delegate their votes prior to this timestamp
        uint startTime;

        /// @notice The timestamp at which voting ends: votes must be cast prior to this timestamp
        uint endTime;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
        
        ///@notice The description of proposalId
        string description;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, uint startTime, uint endTime, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued 
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint id);

    event NewDaoParams(uint quorumVotes, uint proposalThreshold, uint votingDelay, uint votingPeriod, uint executingDelay);
    event NewMoleDaoVoteRelay(address oldMoleDaoVoteRelay, address moleDaoVoteRelay);
    event NewGuardian(address oldGuardian, address guardian);

    constructor(address moleDaoVoteRelay_,
                uint quorumVotes_,
                uint proposalThreshold_,
                uint votingDelay_,
                uint votingPeriod_,
                uint executingDelay_) public {
        moleDaoVoteRelay = MoleDaoVoteRelayInterface(moleDaoVoteRelay_);
        guardian = msg.sender;
        quorumVotes = quorumVotes_;
        proposalThreshold = proposalThreshold_;
        votingDelay = votingDelay_;
        votingPeriod = votingPeriod_;
        executingDelay = executingDelay_;
    }

    function propose(string memory description) public returns (uint) {
        require(msg.sender == guardian || moleDaoVoteRelay.getVotes(msg.sender) > proposalThreshold, "MoleCityDao::propose: proposer votes below proposal threshold");

        //Remove restrictions on administrators
        if (msg.sender != guardian) {
            uint latestProposalId = latestProposalIds[msg.sender];
            if (latestProposalId != 0) {
                ProposalState proposersLatestProposalState = state(latestProposalId);
                require(proposersLatestProposalState != ProposalState.Active, "MoleCityDao::propose: one live proposal per proposer, found an already active proposal");
                require(proposersLatestProposalState != ProposalState.Pending, "MoleCityDao::propose: one live proposal per proposer, found an already pending proposal");
            }
        }

        uint startTime = add256(block.timestamp, votingDelay);
        uint endTime = add256(startTime, votingPeriod);

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            startTime: startTime,
            endTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false,
            description: description
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, startTime, endTime, description);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
         require(msg.sender == guardian || moleDaoVoteRelay.getVotes(msg.sender) > proposalThreshold, "MoleCityDao::queue: proposer votes below proposal threshold");
        require(state(proposalId) == ProposalState.Succeeded, "MoleCityDao::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, executingDelay);
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function execute(uint proposalId) public payable {
         require(msg.sender == guardian || moleDaoVoteRelay.getVotes(msg.sender) > proposalThreshold, "MoleCityDao::execute: proposer votes below proposal threshold");
        require(state(proposalId) == ProposalState.Queued, "MoleCityDao::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "MoleCityDao::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == guardian || moleDaoVoteRelay.getVotes(msg.sender) > proposalThreshold, "MoleCityDao::cancel: proposer votes below proposal threshold");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "MoleCityDao::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "MoleCityDao::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "MoleCityDao::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "MoleCityDao::_castVote: voter already voted");
        uint96 votes = moleDaoVoteRelay.getVotes(msg.sender);
        
        require(votes > 0, "MoleCityDao::_castVote: votes must be greater than zero ");

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function __setMoleDaoVoteRelay(address moleDaoVoteRelay_) public {
        require(msg.sender == guardian, "MoleCityDao::__setMoleDaoVoteRelay: sender must be gov guardian");
        address oldMoleDaoVoteRelay = address(moleDaoVoteRelay);
        moleDaoVoteRelay = MoleDaoVoteRelayInterface(moleDaoVoteRelay_);
        emit NewMoleDaoVoteRelay(oldMoleDaoVoteRelay, moleDaoVoteRelay_);
    }

    function __setDaoParams(uint quorumVotes_,
                            uint proposalThreshold_,
                            uint votingDelay_,
                            uint votingPeriod_,
                            uint executingDelay_) public {
        require(msg.sender == guardian, "MoleCityDao::__setDaoParams: sender must be gov guardian");
        quorumVotes = quorumVotes_;
        proposalThreshold = proposalThreshold_;
        votingDelay = votingDelay_;
        votingPeriod = votingPeriod_;
        executingDelay = executingDelay_;
        emit NewDaoParams(quorumVotes_, proposalThreshold_, votingDelay_, votingPeriod_, executingDelay_);
    }

    function __setGuardian(address guardian_) public {
        require(msg.sender == guardian, "MoleCityDao::__setGuardian: sender must be gov guardian");
        address oldGuardian = guardian;
        guardian = guardian_;
        emit NewGuardian(oldGuardian, guardian_);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface MoleDaoVoteRelayInterface {
    function getVotes(address _user) external view returns (uint96);
}
