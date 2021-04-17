// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Gambleboard
 * Create and place decentralized "Back and lay" bets on anything.
 * @dev Parimutuel betting might be useful to be put into another contract.
 * @dev states as hexadecimal:
 * open:              0
 * waiting for votes: 1
 * resolved:          2
 * disputed:          3
 * @dev state, type and category are saved on the same variable:
 * State is on the first 3 bits (1 useless bit atm), Type on the 4th bit, Category on the last 4 bits
 * Bitwise mask used to get the values:
 * State: 0x07   Type: 0x08    Category: 0xF0
 */
contract Gambleboard {
    
    bytes1 constant STATE_MASK = 0x07;
    bytes1 constant TYPE_MASK = 0x08;
    bytes1 constant CATEGORY_MASK = 0xF0;
    bytes1 constant TYPE_CATEGORY_MASK = 0xF8;
    
    bytes1 constant TYPE_BACKLAY = 0x00;
    bytes1 constant TYPE_PARIMUTUEL = 0x08;
    
    bytes1 constant STATE_OPEN = 0x00;
    bytes1 constant STATE_VOTING = 0x01;
    bytes1 constant STATE_RESOLVED = 0x02;
    bytes1 constant STATE_DISPUTED = 0x03;
    
    uint8 constant MAX_OUTCOMES = 50;
    uint8 constant MAX_COUNTRIES = 194;
    uint constant ODDS_MULTIPLIER = 1000000;
    
    event BetCreated(address creator, bytes betID, string description, bytes1 categoryTypeAndState, uint8 country, uint16 sport);

    struct Bet {
        uint256 deadline;
        address creator;
        bytes1 categoryTypeAndState;
        bool isSet;
        BetPlacementData[] betPlacements;
    }
    
    struct BetPlacementData {
        uint256 valueOpen;
        PlacedBet[] placedBets;
    }
    
    struct PlacedBet {
        address bettor;
        uint256 valueBet;
    }
    
    mapping(bytes => Bet) private bets;
    mapping(address => uint32) betsCreated;
    
    constructor() {
    }
    
    /**
     * Creates a new bet based on the bet type given as parameter
     * @ dev The array odds has all the odds of the possible outcomes. An outcome is thus represented by an index number of the odds array
     * AND in the datastructure by an index in the betPlacements array;
     * @ dev is payable, meaning the ETH value sent with the transaction is sent to the contract address
     * @ params:
     * description: String description of the match
     * categoryAndType: Category and Type information in 8 bits.
     * country: country code, countries from 0 to 194
     * sport: sport as integer
     * odds: array of odds of each outcomes
     * creatorBet: the outcome that the creator bets on
     * deadline: After the deadline no new bets should be allowed. Unix time
     */
    function createBet(string memory description, bytes1 categoryAndType, uint8 country, uint16 sport, uint[] memory odds, uint8 creatorBet, uint256 deadline) payable public returns (bool){
        require(msg.value > ODDS_MULTIPLIER, "Value has to be bigger than 1000000 wei");
        require(odds.length < MAX_OUTCOMES, "Max 50 outcomes!");
        require(country < MAX_COUNTRIES, "Invalid country number!");
        require(creatorBet <= odds.length, "Invalid creator outcome selection");
        require(msg.value != 0, "Creator bet cannot be 0!");
        bytes memory betID = abi.encodePacked(uint160(msg.sender), betsCreated[msg.sender]);
        betsCreated[msg.sender] += 1;
        require(!bets[betID].isSet, "Bet ID collision! Developer fucked up!");

        Bet storage newBet = bets[betID];
        
        bytes1 betType = categoryAndType & STATE_MASK;
        
        if (betType == TYPE_BACKLAY) {

            uint amountToWinFromBet = (msg.value/ODDS_MULTIPLIER) * odds[creatorBet];
        
            // Calculate fixed stakes for each outcome based on the stake of the creator and the given odds.
            // Check that the odds are actually fair odds. Need fair odds for the stake calculation to work
            uint compoundedStakes = 0;
            for (uint i = 0; i < odds.length; i++) {
                newBet.betPlacements.push();
                uint fixdStake = (amountToWinFromBet*ODDS_MULTIPLIER) / odds[i];
                compoundedStakes += fixdStake;
                newBet.betPlacements[i].valueOpen = fixdStake;
            }
            //Check for fair odds. Might break due to rounding error in some case.
            //Solidity rounds towards 0 so probably e.g odd 1666667 should be as 1666666
            require(((compoundedStakes * ODDS_MULTIPLIER) / amountToWinFromBet) == ODDS_MULTIPLIER, "The odds are not fair!");

            newBet.betPlacements[creatorBet].valueOpen = 0;
        } else if (betType == TYPE_PARIMUTUEL) {
            // Not supported
            revert("Bet type not supported!");
        }
        newBet.betPlacements[creatorBet].placedBets.push(PlacedBet(msg.sender, msg.value));

        newBet.creator = msg.sender;
        newBet.categoryTypeAndState = categoryAndType & TYPE_CATEGORY_MASK;
        newBet.deadline = deadline;
        newBet.isSet = true;
        emit BetCreated(msg.sender, betID, description, newBet.categoryTypeAndState, country, sport);
        
        return true;
    }
    
    function placeBet(bytes memory betID, uint256 outcome) payable public returns (bool) {
        
    }
}
