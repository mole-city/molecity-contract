pragma solidity ^0.5.16;

/**
 * @title Mole City' Dao Vote Relay
 * @author Mole City
 */
interface MoleThrowerInterface{
    function getBalance(uint256 _pid, address _user) external view returns (uint); 
}

interface MoleLockInterface{
    function balanceOf(address account) external view returns (uint256); 
    function releaseTime() external view returns (uint256); 
}

contract MoleDaoVoteRelay {

    address[] public moleLocks;
    mapping(address => VoteWeight) public voteWeights;

    address public admin;

    event NewWeight(uint period, address moleLock, uint weight);

    struct VoteWeight {
        bool added;
        address moleLock;
        uint period;
        uint weight;
    }

    constructor() public {
        admin = msg.sender;
    }

    /**
     * @notice Set the voting weights corresponding to each lock contract
     * @param _period Lock period -> _period = 0/7/30/90/180/365...
     * @param _moleLock The address of the MoleLock contract
     * @param _weight Voting weight -> _weight = 1\20\30\40\
     */ 
    function _setWeight(uint _period, address _moleLock, uint _weight) public {
        require(msg.sender == admin, "no permission to set");
        VoteWeight memory voteWeight = VoteWeight({
            added: true,
            moleLock: _moleLock,
            period: _period,
            weight: _weight
        });
        if (voteWeights[address(_moleLock)].added == false) {
            moleLocks.push(address(_moleLock));
        }
        voteWeights[address(_moleLock)] = voteWeight;
        emit NewWeight(_period, _moleLock, _weight);
    }

    /**
     * @notice query the user's pledge balance in several pools, and return the sum of each pledge balance multiplied by weight
     * @param _user The address of the user
     * @return Total number of votes
     */
    function getVotes(address _user) external view returns (uint256) {
        uint totalVote = 0;
        for (uint256 i = 0; i < moleLocks.length; i++) {
            address lockAddress = moleLocks[i];
            uint period = voteWeights[lockAddress].period;
            uint weight = voteWeights[lockAddress].weight;
            uint balance = 0;

            if (period > 0) {
                MoleLockInterface moleLock = MoleLockInterface(lockAddress);
                uint256 releaseTime = moleLock.releaseTime();
                //Expired molelock do not count
                if (block.timestamp < releaseTime) {
                    balance = moleLock.balanceOf(_user);
                }
            }
            totalVote = add(totalVote, mul(balance, weight));
        }
        return totalVote;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}
