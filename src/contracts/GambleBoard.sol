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
    enum State {OPEN, VOTING, AGREEMENT, DISAGREEMENT, DISPUTED, CLOSED}
    enum RulingOption {NO_OUTCOME, CREATOR_WINS, BACKER_WINS}

    uint256 private constant ONE_DAY = 86400;

    uint8 private constant MAX_COUNTRIES = 200;

    uint256 public constant RULING_OPTIONS_AMOUNT = 2; // 0 if can't arbitrate

    // Odds with 6 decimals.
    uint256 public constant MIN_ODD = 1000000;
    uint256 public constant MIN_STAKE = 1000000;

    // Indexed params can be filtered in the UI.
    event BetCreated(
        uint256 betID,
        uint8 country,
        uint8 league,
        uint16 category
    );
    event BetPlaced(uint256 betID, address backer, State state);
    event BetStateChanged(uint256 betID, State state);
    event BetVotedOn(uint256 betID, RulingOption outcome, State state);
    event BetDisputed(uint256 betID, uint256 disputeID, State state);
    event BetRefund(
        uint256 betID,
        State state,
        uint256 backerStake,
        uint256 creatorStake
    );

    modifier onlyPlayer(uint256 betID) {
        require(
            msg.sender == bets[betID].creator ||
                msg.sender == bets[betID].backer,
            "Only a player can send the bet to arbitration!"
        );
        _;
    }

    struct Bet {
        uint256 stakingDeadline;
        uint256 votingDeadline;
        uint256 backerStake; // Arbitration fee is added to the fee payers stake.
        uint256 creatorStake;
        RulingOption outcome;
        State state;
        address payable creator;
        address payable backer;
        string description;
        string creatorBetDescription;
    }

    mapping(uint256 => Bet) public bets;
    mapping(uint256 => uint256) private disputeIDToBetID;

    uint256 public betsCreated;

    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData)
        Arbitrable(_arbitrator, _arbitratorExtraData)
    {
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
    function createBet(
        string memory description,
        string memory creatorBetDescription,
        uint8 country,
        uint8 league,
        uint16 category,
        uint256 stakingDeadline,
        uint256 timeToVote,
        uint256 creatorOdd
    ) public payable returns (uint256) {
        require(
            msg.value > MIN_STAKE,
            "Creator bet has to be bigger than 1000000 wei"
        );
        require(creatorOdd > MIN_ODD, "Creator odd has to be bigger than 1!");
        require(
            stakingDeadline > block.timestamp,
            "Deadline to place stakes cannot be in the past!"
        );
        require(timeToVote > ONE_DAY, "Time to vote should be atleast 1 day!");
        uint256 betID = betsCreated++;

        Bet storage newBet = bets[betID];

        // Calculate fixed stake for the backer based on the creator odd and stake
        // Always fair odds

        uint256 amountToWinFromBet = (msg.value * creatorOdd) / MIN_ODD;
        newBet.backerStake = amountToWinFromBet - msg.value;
        newBet.creatorStake = msg.value;

        newBet.creator = payable(msg.sender);
        newBet.description = description;
        newBet.creatorBetDescription = creatorBetDescription;
        newBet.stakingDeadline = stakingDeadline;
        newBet.votingDeadline = stakingDeadline + timeToVote;

        emit BetCreated(betID, country, league, category);

        return betID;
    }

    function placeBet(uint256 betID) public payable {
        Bet storage placingBet = bets[betID];

        //check that the state is open
        require(placingBet.state == State.OPEN, "The bet is not open!");

        //make sure that the bet is not done after the Deadline
        require(
            block.timestamp <= placingBet.stakingDeadline,
            "The bet match has expired, we are sorry!"
        );

        //check that no one else betted before
        require(placingBet.backer == address(0x0), "We have a backer already");

        //bet must be equal to the amount specified during the creation for the Bet
        require(
            msg.value == placingBet.backerStake,
            "The amount you staked is not valid!"
        );

        placingBet.backer = payable(msg.sender);
        placingBet.state = State.VOTING;

        emit BetPlaced(betID, msg.sender, State.VOTING);
    }

    function voteOnOutcome(uint256 betID, RulingOption outcome)
        public
        onlyPlayer(betID)
    {
        require(bets[betID].state == State.VOTING, "State is not on voting");

        if (bets[betID].outcome == RulingOption.NO_OUTCOME) {
            bets[betID].outcome = outcome;
        } else {
            if (bets[betID].outcome == outcome) {
                bets[betID].state = State.AGREEMENT;
            } else {
                bets[betID].state = State.DISPUTED;
            }
        }

        emit BetVotedOn(betID, bets[betID].outcome, bets[betID].state);
    }

    function refund(uint256 betID) public onlyPlayer(betID) {
        // If no players voted in time or if the votes were on NO_OUTCOME, the stakes are refunded.
        require(
            bets[betID].outcome == RulingOption.NO_OUTCOME,
            "Bet outcome defined"
        );
        require(
            (bets[betID].state == State.VOTING &&
                bets[betID].votingDeadline < block.timestamp) ||
                bets[betID].state == State.AGREEMENT,
            "Refund not possible"
        );

        if ((msg.sender) == bets[betID].creator) {
            uint256 amountTransfer = bets[betID].creatorStake;
            bets[betID].creatorStake = 0;
            payable(msg.sender).transfer(amountTransfer);
        } else {
            uint256 amountTransfer = bets[betID].backerStake;
            bets[betID].backerStake = 0;
            payable(msg.sender).transfer(amountTransfer);
        }

        if (bets[betID].backerStake == 0 && bets[betID].creatorStake == 0) {
            bets[betID].state = State.CLOSED;
        }

        emit BetRefund(
            betID,
            bets[betID].state,
            bets[betID].backerStake,
            bets[betID].creatorStake
        );
    }

    function claimWinnings(uint256 betID) public onlyPlayer(betID) {
        // If only one player voted within the time to vote, the winner of the bet will be choosen based on the one voting.
        // Player who won the bet can claim winning, but can also be called by loser
        // Function can only be called after voting Deadline

        require(bets[betID].state == State.AGREEMENT || 
               (bets[betID].state == State.VOTING && bets[betID].votingDeadline < block.timestamp));
        require(bets[betID].outcome != RulingOption.NO_OUTCOME);

        uint256 amountTransfer = bets[betID].creatorStake + bets[betID].backerStake;
        bets[betID].state = State.CLOSED;

        if (bets[betID].outcome == RulingOption.CREATOR_WINS) {
            bets[betID].creator.transfer(amountTransfer);
        } else {
            bets[betID].backer.transfer(amountTransfer);
        }

        emit BetStateChanged(betID, bets[betID].state);
    }

    // @title Creates a dispute in the arbitrator contract
    // Needs to deposit arbitration fee. The fee goes to the winner.
    // One player is enough to send the case to arbitration.
    function createDispute(uint256 betID)
        public
        payable
        onlyPlayer(betID)
        returns (uint256)
    {
        require(
            bets[betID].state == State.DISAGREEMENT,
            "Bet not in disagreement state!"
        );
        require(
            msg.value >= arbitrator.arbitrationCost("0x0"),
            "Not enough ETH to cover arbitration costs."
        );

        if ((msg.sender) == bets[betID].creator) {
            bets[betID].creatorStake += msg.value;
        } else {
            bets[betID].backerStake += msg.value;
        }
        bets[betID].state = State.DISPUTED;
        uint256 disputeID =
            arbitrator.createDispute{value: msg.value}(
                RULING_OPTIONS_AMOUNT,
                ""
            );
        disputeIDToBetID[disputeID] = betID;

        emit BetDisputed(betID, disputeID, State.DISPUTED);
        return disputeID;
    }

    function executeRuling(uint256 _disputeID, uint256 _ruling)
        internal
        override
    {
        bets[disputeIDToBetID[_disputeID]].state = State.AGREEMENT;
        bets[disputeIDToBetID[_disputeID]].outcome = RulingOption(_ruling);

        emit BetStateChanged(disputeIDToBetID[_disputeID], State.AGREEMENT);
    }

    //Fallback functions if someone only sends ether to the contract address
    fallback() external payable {
        revert("Cant send ETH to contract address!");
    }

    receive() external payable {
        revert("Cant send ETH to contract address!");
    }
}
