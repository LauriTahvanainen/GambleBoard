
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


import "./dependencies/Arbitrable.sol";

/**
 * @title Gambleboard
 * Create and place decentralized "Back and lay" bets on anything.
 * @dev Parimutuel betting might be useful to be put into another contract.
 * @dev states:
 * open:              0
 * waiting for votes: 1
 * resolved:          2
 * disputed:          3
 */
contract GambleBoard is Arbitrable {
    
    uint8 constant STATE_OPEN = 0;
    uint8 constant STATE_VOTING = 1;
    uint8 constant STATE_RESOLVED = 2;
    uint8 constant STATE_DISPUTED = 3;
    
    uint8 constant MAX_COUNTRIES = 200;
    // Odds with 6 decimals.
    uint constant MIN_ODD = 1000000;
    uint constant MIN_STAKE = 1000000;
    uint constant MIN_TIME_TO_VOTE = 86400;
    
    enum RulingOptions {RefusedToArbitrate, creatorWins, backerWins}
    uint constant amountOfRulingOptions = 2; // 0 if can't arbitrate
    
    // Indexed params can be filtered in the UI.
    event BetCreated(bytes indexed betID, bytes betIDData, uint8 indexed country, uint16 indexed category, uint8 league, uint backerStake);

    struct Bet {
        uint256 stakingDeadline;
        uint256 timeToVote;
        uint256 backerStake;
        uint256 amountStaked;
        uint8 state;
        RulingOptions outcome;
        address payable creator;
        address payable backer;
        string description;
        string creatorBetDescription;
    }
    
    mapping(bytes => Bet) public bets;
    mapping(address => uint32) public betsCreated;
    mapping(uint => bytes) private disputeIDToBetID;
    
    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData) Arbitrable(_arbitrator, _arbitratorExtraData) {}
    
    /**
     * Creates a new bet. Calculates the amount a backer has to stake from the creators stake and odd.
     * @ dev is payable, meaning the ETH value sent with the transaction is sent to the contract address
     * @ dev emits information about the created bet.
     * @ params:
     * description: String description of the match
     * creatorBetDescription: String description of the creators bet.
     * country: country code as integer
     * category: category as integer
     * league: league as integer
     * stakingDeadline: deadline after which no new bets are accepted. Unix time
     * timeToVote: amount of time to vote after the stakingDeadline. Seconds
     * creatorOdd: The odd of the outcome the creator chose. x.yz e 18
     */
    function createBet(string memory description,
                       string memory creatorBetDescription,
                       uint8 country,
                       uint16 category,
                       uint8 league,
                       uint stakingDeadline,
                       uint timeToVote,
                       uint creatorOdd
                       ) payable public returns (bool){
                           
        require(msg.value > MIN_STAKE, "Creator bet has to be bigger than 1000000 wei");
        require(creatorOdd > MIN_ODD, "Creator odd has to be bigger than 1!");
        require(country < MAX_COUNTRIES, "Invalid country number!");
        require(stakingDeadline > block.timestamp, "Deadline to place stakes cannot be in the past!");
        require(timeToVote > MIN_TIME_TO_VOTE, "Time to vote should be atleast 1 day!");
        bytes memory betID = abi.encodePacked(uint160(msg.sender), betsCreated[msg.sender]);
        betsCreated[msg.sender] += 1;
        require(bets[betID].creator == address(0x0), "Bet ID collision!");

        Bet storage newBet = bets[betID];

        // Calculate fixed stake for the backer based on the creator odd and stake
        // Always fair odds
        
        uint amountToWinFromBet = (msg.value * creatorOdd) / MIN_ODD;
        newBet.backerStake = amountToWinFromBet - msg.value;
        newBet.amountStaked = msg.value;

        newBet.creator = payable(msg.sender);
        newBet.description = description;
        newBet.creatorBetDescription = creatorBetDescription;
        newBet.stakingDeadline = stakingDeadline;
        newBet.timeToVote = timeToVote;

        emit BetCreated(betID, betID, country, category, league, newBet.backerStake);
        
        return true;
    }
    
    
    function placeBet(bytes memory betID) payable public returns (bool) {
        
    }
    
    function voteOnOutcome(bytes memory betID, uint outcome) public {
        
    }
    
    function resolveBet(bytes memory betID, uint outcome) private {
        
    }
    
    function claimWinnings(bytes memory betID) public {
        
    }
    
    function createDispute(bytes memory betID) public {
        
    }
    
    function executeRuling(uint _disputeID, uint _ruling) override internal {
        resolveBet(disputeIDToBetID[_disputeID], _ruling);
        emit Ruling(arbitrator, _disputeID, _ruling);
    }
    
    //Fallback functions if someone only sends ether to the contract address
    fallback () external payable {
        revert("Cant send Ether to contract address!");
    }
    
    receive () external payable {
        revert("Cant send ether to contract address!");
    }
}