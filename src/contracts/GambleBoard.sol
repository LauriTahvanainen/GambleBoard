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
 * 
 * @dev countryLeagueCategory:
 * Country, Category and League are concatenated to one bytes2 variable. 
 * Bits from left to right
 * Country: 8 bits
 * League: 8 bits
 * Category: 16 bits
 */
contract GambleBoard is Arbitrable {
    
    uint8 constant private STATE_OPEN = 0;
    uint8 constant private STATE_VOTING = 1;
    uint8 constant private STATE_RESOLVED = 2;
    uint8 constant private STATE_DISAGREEMENT = 3;
    uint8 constant private STATE_DISPUTED = 4;
    uint8 constant private STATE_NOOUTCOME = 5;
    
    uint constant private ONE_DAY = 86400;
     
    uint8 constant private MAX_COUNTRIES = 200;

    enum RulingOptions {NoOutcome, creatorWins, backerWins}
    
    uint constant public RULING_OPTIONS_AMOUNT = 2; // 0 if can't arbitrate
    
    // Odds with 6 decimals.
    uint constant public MIN_ODD = 1000000;
    uint constant public MIN_STAKE = 1000000;
    
    // Indexed params can be filtered in the UI.
    event BetCreated(uint indexed betID, address indexed creator, uint backerStake);

    modifier onlyPlayer(uint betID){
        require(msg.sender == bets[betID].creator || msg.sender == bets[betID].backer, "Only a player can send the bet to arbitration!");
        _;    
    }
    
    struct Bet {
        uint256 stakingDeadline;
        uint256 votingDeadline;
        uint256 backerStake;      // Arbitration fee is added to the fee payers stake.
        uint256 creatorStake;             
        RulingOptions outcome;
        uint8 state;
        bytes4 countryLeagueCategory;
        address payable creator;
        address payable backer;
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
                       ) payable public returns (uint){
                           
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
        newBet.creatorStake = msg.value;

        newBet.creator = payable(msg.sender);
        newBet.description = description;
        newBet.creatorBetDescription = creatorBetDescription;
        newBet.stakingDeadline = stakingDeadline;
        newBet.votingDeadline = stakingDeadline + timeToVote;
        newBet.countryLeagueCategory = countryLeagueCategory;

        emit BetCreated(betID, msg.sender, newBet.backerStake);
        
        return betID;
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
            block.timestamp <= placingBet.stakingDeadline,
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
  
    
    function voteOnOutcome(uint betID, RulingOptions outcome) public onlyPlayer(betID) {
        require(bets[betID].state == STATE_VOTING, "State is not on voting");
        
        if (bets[betID].outcome == RulingOptions.NoOutcome){
            bets[betID].outcome = outcome;
        } else {
            if (bets[betID].outcome == outcome){
                bets[betID].state = STATE_RESOLVED;
            } else {
                bets[betID].state = STATE_DISPUTED;
            }
        }
    }


    function refund(uint betID) public onlyPlayer(betID) {
        // If no players voted in time or if the votes were on NoOutcome, the stakes are refunded.
        require(bets[betID].outcome == RulingOptions.NoOutcome, "Bet outcome defined");
        require((bets[betID].state == STATE_VOTING && bets[betID].votingDeadline < block.timestamp) || bets[betID].state == STATE_RESOLVED, "Refund not possible");
        
        if ((msg.sender) == bets[betID].creator){
            uint amountTransfer = bets[betID].creatorStake;
            bets[betID].creatorStake = 0;
            payable(msg.sender).transfer(amountTransfer);
        } else {
            uint amountTransfer = bets[betID].backerStake;
            bets[betID].backerStake = 0;
            payable(msg.sender).transfer(amountTransfer);
        }
    }



       
    function claimWinnings(uint betID) public onlyPlayer(betID) {
        // If only one player voted within the time to vote, the winner of the bet will be choosen based on the one voting.
        // Player who won the bet can claim winning, but can also be called by loser
        // Function can only be called after voting Deadline
        
        require(bets[betID].state == STATE_RESOLVED || (bets[betID].state == STATE_VOTING && bets[betID].votingDeadline < block.timestamp));
        require(bets[betID].outcome != RulingOptions.NoOutcome);
        
        uint amountTransfer = bets[betID].creatorStake + bets[betID].backerStake;
        bets[betID].creatorStake = 0;
        bets[betID].backerStake = 0;
        
        if (bets[betID].outcome == RulingOptions.creatorWins){
            bets[betID].creator.transfer(amountTransfer);
            
        } else {
            bets[betID].backer.transfer(amountTransfer);
        }
    }
        
  
    
    
    
    // @title Creates a dispute in the arbitrator contract
    // Needs to deposit arbitration fee. The fee goes to the winner.
    // One player is enough to send the case to arbitration.
    function createDispute(uint betID) public payable onlyPlayer(betID) {
        require(bets[betID].state == STATE_DISAGREEMENT, "Bet not in disagreement state!");
        require(msg.value >= arbitrator.arbitrationCost("0x0"), "Not enough ETH to cover arbitration costs.");
        
        if ((msg.sender) == bets[betID].creator){
            bets[betID].creatorStake += msg.value;
        } else {
            bets[betID].backerStake += msg.value;
        }
        bets[betID].state = STATE_DISPUTED;   
        disputeIDToBetID[arbitrator.createDispute{value: msg.value}(RULING_OPTIONS_AMOUNT, "")] = betID;
    }
    
    function executeRuling(uint _disputeID, uint _ruling) override internal {
        bets[disputeIDToBetID[_disputeID]].state = STATE_RESOLVED;
        bets[disputeIDToBetID[_disputeID]].outcome = RulingOptions(_ruling);    
    }
    
    //Fallback functions if someone only sends ether to the contract address
    fallback () external payable {
        revert("Cant send ETH to contract address!");
    }
    
    receive () external payable {
        revert("Cant send ETH to contract address!");
    }
}
