import { Address, BigInt } from "@graphprotocol/graph-ts"

import {
  GambleBoard,
  BetCreated,
  BetDisputed,
  BetPlaced,
  BetStateChanged,
  Dispute,
  Evidence,
  MetaEvidence,
  Ruling,
  BetRefund,
  BetVotedOn
} from "../../generated/GambleBoard/GambleBoard"
import { Bet } from "../../generated/schema"

export function handleBetCreated(event: BetCreated): void {
  let betID = event.params.betID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);

  let betEntity = new Bet(betID.toHex());
  betEntity.stakingDeadline = betData.value0;
  betEntity.votingDeadline = betData.value1;
  betEntity.backerStake = betData.value2
  betEntity.creatorStake = betData.value3;
  betEntity.outcome = betData.value4;
  betEntity.state = betData.value5;
  betEntity.creator = betData.value6;
  betEntity.backer = betData.value7;
  betEntity.description = betData.value8;
  betEntity.creatorBetDescription = betData.value9;

  betEntity.country = event.params.country;
  betEntity.league = event.params.league;
  betEntity.category = event.params.category;

  betEntity.timeCreated = event.block.timestamp;
  betEntity.timeUpdated = event.block.timestamp;
  // Save the entity to the store
  betEntity.save()
}

export function handleBetDisputed(event: BetDisputed): void {
  let betID = event.params.betID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);

  // Creating a new and writing that to store is faster than loading
  // and saving.
  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state
  betEntity.disputeID = event.params.disputeID;
  betEntity.backerStake = betData.value2
  betEntity.creatorStake = betData.value3;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetPlaced(event: BetPlaced): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;
  betEntity.backer = event.params.backer;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetRefund(event: BetRefund): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;
  betEntity.backerStake = event.params.backerStake;
  betEntity.creatorStake = event.params.creatorStake;
  
  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetStateChanged(event: BetStateChanged): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetVotedOn(event: BetVotedOn): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;
  betEntity.outcome = event.params.outcome;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleRuling(event: Ruling): void { 
  let disputeID = event.params._disputeID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betID = betContract.disputeIDToBetID(disputeID);

  let betEntity = new Bet(betID.toHex());
  betEntity.state = 2; // STATE_AGREEMENT
  betEntity.outcome = event.params._ruling.toI32();
}

export function handleDispute(event: Dispute): void { }

export function handleEvidence(event: Evidence): void { }

export function handleMetaEvidence(event: MetaEvidence): void { }