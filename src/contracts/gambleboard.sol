// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

/**
 * @title Gambleboard
 * @dev Create and place decentralized bets on anything.
 * @dev states as hexadecimal:
 * open:              0
 * waiting for votes: 1
 * resolved:          2
 * disputed:          3
 */
contract Gambleboard {
    
    event BetCreated(address creator, bytes betID, string description, bytes1 categoryAndType, uint8 country, uint8 state);

    struct Bet {
        address creator;
        uint8 state;
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
    
    
    function createBet(string memory description, bytes1 categoryAndType, uint8 country, uint[] memory odds, uint8 creatorBet) payable public returns (bool){
        require(odds.length < 30, "Max 30 outcomes!");
        require(country < 205, "Invalid country number!");
        require(creatorBet < odds.length, "Invalid creator outcome selection");
        bytes memory betID = abi.encodePacked(uint160(msg.sender), betsCreated[msg.sender]);
        betsCreated[msg.sender] += 1;
        require(!bets[betID].isSet, "Bet ID collision!");

        Bet storage newBet = bets[betID];
        
        bytes1 stateCategoryAndType = 0x00;
        stateCategoryAndType = stateCategoryAndType | categoryAndType;
        
        uint amountToWinFromOthers = (msg.value/1000000) * odds[creatorBet] - msg.value;
        
        for (uint256 i = 0; i < odds.length; i++) {
            newBet.betPlacements.push();
            newBet.betPlacements[i].valueOpen = (amountToWinFromOthers*1000000) / odds[i];
        }

        newBet.betPlacements[creatorBet].valueOpen = 0;
        newBet.betPlacements[creatorBet].placedBets.push(PlacedBet(msg.sender, msg.value));

        newBet.creator = msg.sender;
        newBet.stateCategoryAndType = stateCategoryAndType;
        newBet.isSet = true;

        emit BetCreated(msg.sender, betID, description, categoryAndType, country, 0);
        
        return true;
    }
    
    function placeBet(bytes memory betID, uint256 outcome) payable public returns (bool) {
        
    }
}
