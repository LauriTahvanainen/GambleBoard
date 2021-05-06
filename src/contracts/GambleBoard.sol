// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


import "./dep/Arbitrable.sol";

/**
 * @title Gambleboard
 * Create and place decentralized "Back and lay" bets on anything.
 * @dev Parimutuel betting might be useful to be put into another contract.
 * @dev states:
 * open:              0
 * waiting for votes: 1
 * resolved:          2
 * disagreement:      3
 * disputed:          4
 * arbitration:       5
 * 
 * @dev countryLeagueCategory:
 * Country, Category and League are concatenated to one bytes2 variable. 
 * Bits from left to right
 * Country: 8 bits
 * League: 8 bits
 * Category: 16 bits
 */
contract GambleBoard is Arbitrable {
    
    uint8 constant STATE_OPEN = 0;
    uint8 constant STATE_VOTING = 1;
    uint8 constant STATE_RESOLVED = 2;
    uint8 constant STATE_DISAGREEMENT = 3;
    uint8 constant STATE_DISPUTED = 4;
    uint8 constant STATE_ARBITRATION = 5;

    enum RulingOptions {RefusedToArbitrate, creatorWins, backerWins}
    uint constant RULING_OPTIONS_AMOUNT = 2; // 0 if can't arbitrate
    
    uint8 constant MAX_COUNTRIES = 200;
    // Odds with 6 decimals.
    uint constant MIN_ODD = 1000000;
    uint constant MIN_STAKE = 1000000;
    
    uint constant ONE_DAY = 86400;

    // Indexed params can be filtered in the UI.
    event BetCreated(uint indexed betID, address indexed creator, uint backerStake);

    // Arbitration fee is just added to the steak of the player.
    struct Bet {
        uint256 stakingDeadline;
        uint256 deadline; // The same variable used for both deadlines, voting and dispute fee deposit
        uint256 backerStake;
        uint256 totalStake;
        RulingOptions outcome;
        uint8 state;
        bytes4 countryLeagueCategory;
        address payable creator;
        address payable backer;
        address payable lastArbitrationFeeAddr;
        string description;
        string creatorBetDescription;
    }
    
    mapping(uint => Bet) public bets;
    mapping(uint => uint) private disputeIDToBetID;
    
    uint public betsCreated;
    
    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData) Arbitrable(_arbitrator, _arbitratorExtraData) {
        betsCreated = 0;
    }
    
    /**
     * Creates a new bet. Calculates the amount a backer has to stake from the creators stake and odd.
     * @ dev is payable, meaning the ETH value sent with the transaction is sent to the contract address
     * @ dev emits information about the created bet.
     * @ params:
     * description: String description of the match
     * creatorBetDescription: String description of the creators bet.
     * countryLeagueCategory: Country, Category and League of the bet concatenated into a bytes2
     * stakingDeadline: deadline after which no new bets are accepted. Unix time
     * timeToVote: amount of time to vote after the stakingDeadline. Seconds
     * creatorOdd: The odd of the outcome the creator chose. x.yz e 18
     */
    function createBet(string memory description,
                       string memory creatorBetDescription,
                       bytes4 countryLeagueCategory,
                       uint stakingDeadline,
                       uint timeToVote,
                       uint creatorOdd
                       ) payable public returns (bool){
                           
        require(msg.value > MIN_STAKE, "Creator bet has to be bigger than 1000000 wei");
        require(creatorOdd > MIN_ODD, "Creator odd has to be bigger than 1!");
        require(stakingDeadline > block.timestamp, "Deadline to place stakes cannot be in the past!");
        require(timeToVote > ONE_DAY, "Time to vote should be atleast 1 day!");
        uint betID = betsCreated++;

        Bet storage newBet = bets[betID];

        // Calculate fixed stake for the backer based on the creator odd and stake
        // Always fair odds
        
        uint amountToWinFromBet = (msg.value * creatorOdd) / MIN_ODD;
        newBet.backerStake = amountToWinFromBet - msg.value;
        newBet.totalStake = msg.value;

        newBet.creator = payable(msg.sender);
        newBet.description = description;
        newBet.creatorBetDescription = creatorBetDescription;
        newBet.stakingDeadline = stakingDeadline;
        newBet.deadline = timeToVote;
        newBet.countryLeagueCategory = countryLeagueCategory;

        emit BetCreated(betID, msg.sender, newBet.backerStake);
        
        return true;
    }
    
    
    function placeBet(uint betID) payable public returns (bool) {
        Bet storage placingBet = bets[betID];
        
        //check that the state is open
        require(
            placingBet.state == STATE_OPEN,
            "The bet is not open!"
            );
            
         //make sure that the bet is not done after the Deadline
        require(
            block.timestamp > placingBet.stakingDeadline,
            "The bet match has expired, we are sorry!"
            );
        
        //check that no one else betted before
        require(
            placingBet.backer == address(0x0),
            "We have a backer already"
            );
        
        //bet must be equal to the amount specified during the creation for the Bet
        require(
            msg.value == placingBet.backerStake,
            "The amount you staked is not valid!"
            );

        placingBet.backer = payable(msg.sender);       
        placingBet.state = STATE_VOTING;
        
        return true;
    }
    
    function voteOnOutcome(uint betID, uint outcome) public {
        
    }
    
    function resolveBet(uint betID, uint outcome) private {
        
    }
    
    function claimWinnings(uint betID) public {
        // If bet is in disputed state and time to deposit arbitration fee has expired,
        // the first who deposited the fee can claim the winnings.
    }
    
    // @title Creates a dispute in the arbitrator contract
    // Both players need to deposit arbitration fee. Arbitration fees go to the winner.
    // If the second player does not deposit arbitration fee in time, the first to deposit the fee wins.
    function depositArbitrationFee(uint betID) public payable {
        Bet storage bet = bets[betID];
        require(bet.state == STATE_DISAGREEMENT || bet.state == STATE_DISPUTED, "Bet not in disputed or disagreement state!");
        require(msg.sender == bet.creator || msg.sender == bet.backer, "Only the players can send the bet to arbitration!");
        require(msg.value >= arbitrator.arbitrationCost("0x0"), "Not enough ETH to cover arbitration costs.");
        
        if (bet.state == STATE_DISPUTED) {
            bet.totalStake += msg.value;
            arbitrator.createDispute{value: msg.value}(RULING_OPTIONS_AMOUNT, "");
            bet.state = STATE_ARBITRATION;   
        } else {
            bet.totalStake += msg.value;
            bet.deadline = block.timestamp + ONE_DAY;
            bet.lastArbitrationFeeAddr = payable(msg.sender);
            bet.state = STATE_DISPUTED;
        }
    }
    
    function executeRuling(uint _disputeID, uint _ruling) override internal {
        resolveBet(disputeIDToBetID[_disputeID], _ruling);
    }
    
    //Fallback functions if someone only sends ether to the contract address
    fallback () external payable {
        revert("Cant send ETH to contract address!");
    }
    
    receive () external payable {
        revert("Cant send ETH to contract address!");
    }
}
