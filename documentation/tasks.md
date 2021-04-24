# User stories

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want a Homepage where I can search listed bets|Rez||||
- Categories by Country, Sport, League
- Single bet information shown: Description, Outcome, Odds, Available to stake
- Only outcomes which have not been played available. e.g. on basic back-lay with 2 outcomes, only opposite of creator bet playable.
- Clicking on outcomes odd starts the transaction
- Ability to create a new bet from the listing page.
- Ability to create a bet under a category 
- Ability to use “lay bet” button which will lead to a MetaMask popup → Confirm or Reject the current transaction. 
- Confirmation: bet will be listed under the upcoming bets, so that other users can back the bet.

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want see my Betting history|Ronin||||
- Access from the front page
- Ability to vote on outcome of a bet.
- Ability to dispute a result (Optional)
- See the result

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to create a “lay” bet pool|Lauri||||
- 1 player / outcome
- Enter amount of ether and outcome selected by the creator
- Fixed odds
- Fixed stake
- Creator defines: Odds, Match description, deadline
- Given by UI: Outcomes, Categories, Type

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to place a bet on “back” bet pools|Ronin||||
- Display and selection of  a league on which I want to bet
- Odd and fixed stake shown.
- 1 backer / bet.

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to vote on the outcome|Martin||||
- Receive back the bet-money if dispute without Kleros
- If there is not a backer, creator can withdraw own stake.
- Option for voting undecidable e.g. for cancelled matches.
- If disagreement -> contract to dispute state
- Automatical reward distribution in case of agreement or withdraw for winner?


|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to dispute the result (Optional)|Lauri||||
- Give an evidence of the wrong result
- Only if the player has a bet on the match.
- Ruling done automatically

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to create a parimutuel bet pool (Optional)|DevX||||
- N players / outcome
- Any amount of stake
- Enter amount of ether and outcome selected by the creator
- Rewards by distribution of bets, dynamic odds
- Creator defines: Outcomes, Match description, deadline
- Given by UI: Categories, Type

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to place a bet on parimutuel bet pools (Optional)|DevX||||
- Display and selection of  a league on which I want to bet
- Stake given by user.
- Automatic distribution might be a problem with Parimutuel betting when there are many players. Dividing the winnings would have to be done in a costly loop. A claim winnings function in this scenario?

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to receive notifications about the status of my bets (Optional)|DevX||||
