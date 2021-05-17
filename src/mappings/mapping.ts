import { BigInt } from "@graphprotocol/graph-ts";
import {
  GambleBoard,
  BetCreated,
  BetPlaced,
  BetStateChanged,
  Dispute,
  Evidence,
  Ruling,
  BetRefund,
  BetVotedOn,
  MetaEvidence,
} from "../../generated/GambleBoard/GambleBoard"
import { Bet, Event, League } from "../../generated/schema"

export function handleBetCreated(event: BetCreated): void {
  let betID = event.params.betID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);

  // Events
  // Create the event first since it will have a derived field to Bet
  ///////////////////
  let unixTimeStampInDays = betData.value0.toI32() / 86400;
  let eventID = betData.value9
    + BigInt.fromI32(event.params.country).toString()
    + BigInt.fromI32(event.params.category).toString()
    + event.params.league.toString()
    + unixTimeStampInDays.toString();

  let eventEntity = Event.load(eventID);

  if (eventEntity == null) {
    eventEntity = new Event(eventID);
    eventEntity.description = betData.value9;
    eventEntity.startTime = betData.value0;
  }

  if (eventEntity.startTime > betData.value0) {
    eventEntity.startTime = betData.value0;
  }
  eventEntity.country = event.params.country;
  eventEntity.league = event.params.league;
  eventEntity.category = event.params.category;

  eventEntity.save();

  // Bet
  ////

  let betEntity = new Bet(betID.toString());
  betEntity.stakingDeadline = betData.value0;
  betEntity.votingDeadline = betData.value1;
  betEntity.backerStake = betData.value2
  betEntity.creatorStake = betData.value3;
  betEntity.outcome = betData.value4;
  betEntity.state = betData.value5;
  betEntity.creator = betData.value7;
  betEntity.backer = betData.value8;
  betEntity.description = betData.value9;
  betEntity.creatorBetDescription = betData.value10;

  betEntity.country = event.params.country;
  betEntity.league = event.params.league;
  betEntity.category = event.params.category;

  betEntity.timeCreated = event.block.timestamp;
  betEntity.timeUpdated = event.block.timestamp;

  betEntity.creatorHasVoted = false;
  betEntity.backerHasVoted = false;
  betEntity.creatorProvidedEvidence = false;
  betEntity.backerProvidedEvidence = false;

  betEntity.creatorBacker = betData.value7.toHexString();

  betEntity.event = eventID;
  // Save the entity to the store
  betEntity.save()

  //Leagues of CategoryCountry pairs
  //////////////////////
  if (event.params.league !== "") {
    let leagueID = BigInt.fromI32(event.params.country).toString() + BigInt.fromI32(event.params.category).toString() + event.params.league;
    let leagueListEntity = League.load(leagueID);

    if (leagueListEntity == null) {
      leagueListEntity = new League(leagueID);
    }

    leagueListEntity.league = event.params.league;
    leagueListEntity.category = event.params.category;
    leagueListEntity.country = event.params.country;

    leagueListEntity.save();
  }

}

export function handleBetPlaced(event: BetPlaced): void {
  let betID = event.params.betID

  let betEntity = Bet.load(betID.toString());
  betEntity.state = event.params.state;
  betEntity.backer = event.params.backer;

  betEntity.creatorBacker = betEntity.creatorBacker + event.params.backer.toHexString();

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetRefund(event: BetRefund): void {
  let betID = event.params.betID

  let betEntity = Bet.load(betID.toString());
  betEntity.state = event.params.state;
  betEntity.backerStake = event.params.backerStake;
  betEntity.creatorStake = event.params.creatorStake;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetStateChanged(event: BetStateChanged): void {
  let betID = event.params.betID

  let betEntity = Bet.load(betID.toString());
  betEntity.state = event.params.state;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetVotedOn(event: BetVotedOn): void {
  let betID = event.params.betID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);
  let betEntity = Bet.load(betID.toString());
  betEntity.outcome = betContract.getOutcome(betID);
  betEntity.state = betContract.getState(betID);

  if (event.transaction.from == betEntity.creator) {
    betEntity.creatorHasVoted = true;
  } else if (event.transaction.from == betEntity.backer) {
    betEntity.backerHasVoted = true;
  }

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleRuling(event: Ruling): void {
  let disputeID = event.params._disputeID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betID = betContract.disputeIDToBetID(disputeID);

  let betEntity = Bet.load(betID.toString());
  betEntity.state = 2; // STATE_AGREEMENT
  betEntity.outcome = event.params._ruling.toI32();

  betEntity.timeUpdated = event.block.timestamp;

  betEntity.save();
}

export function handleDispute(event: Dispute): void {
  let betID = event.params._evidenceGroupID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);

  let betEntity = Bet.load(betID.toString());
  betEntity.state = 4 // STATE_DISPUTED
  betEntity.disputeID = event.params._disputeID;
  betEntity.backerStake = betData.value2
  betEntity.creatorStake = betData.value3;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleEvidence(event: Evidence): void {
  let betID = event.params._evidenceGroupID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betEntity = Bet.load(betID.toString());
  betEntity.outcome = betContract.getOutcome(betID);
  betEntity.state = betContract.getState(betID);


  if (event.transaction.from == betEntity.creator) {
    betEntity.creatorProvidedEvidence = true;
  } else if (event.transaction.from == betEntity.backer) {
    betEntity.backerProvidedEvidence = true;
  }

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleMetaEvidence(event: MetaEvidence): void {
  let betEntity = Bet.load(event.params._metaEvidenceID.toString());

  betEntity._metaEvidence = event.params._evidence;

  betEntity.save();
}