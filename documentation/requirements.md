# Gambleboard, a decentralized betting app

Martin Frick, Md Rezuanul Haque, Ronin Chellakudam, Lauri Tahvanainen

Department of Informatics IfI University of Zurich UZH


## 1.1 Use case

Our goal is to create a platform (DApp) where players can bet against each other without a centralized provider demanding a commission in between. The type of bets we offer are “back”- and “lay”-bets. (https://www.livetipsportal.com/en/betting-strategies/back-lay/). The players have the possibility to back or to lay a bet which allows them to either offer a bet to other players or to accept a bet another player has offered. 

The bet can be almost on any type of event. A champions league football match, a beer league ice hockey match, a political event or even a funny bet with a friend about being able to throw a ping pong ball in to a glass while blind. The way we can achieve having bets of so many types is through having the default situation be that the players agree on the outcome of the event. 
After a bet has been layed, the players stake is frozen until the bet is over or removed. A user who lays a bet also has to decide on some options. They have to decide on which basis it will be decided who wins the bet. 

There are following options: just upon agreement, one agreement with  (*Opt*) Kleros and an (*Opt*) oracle with Kleros. When the latter is chosen, the users do have to agree on an oracle. In Addition the layer can allow both parties in advance to provide resources which will be taken into account if it comes to Kleros.

The platform itself offers several kinds of bets which are listed under different categories users are allowed to choose between. 

A bet pool is created by a interaction with a smart contract. In a simple 1v1 pool the creator configures the pool and add stake and wait for someone to agree on the odds and provide their stake. The stakes would then be locked in the pool for a certain time or until both parties vote on the result. When the outcome is known, both parties interact with the contract to broadcast their opinion on the result. If these opinions match the rewards are delegated to the winner accordingly. 

### *Optional*
Further the layer of the bet decides between making the bet private or public. Private bets are accessible through invitation. There is also the option that the lay side offers a bet which can be backed by many players with a share of the total bet at the same time. This option increases the chance of a bet with high stakes to come off. The payoffs would then depend on how big the share of the respective player is.

### *Optional*
If there is an dispute on the result, the contract will automatically, or with the interraction of one player, send the dispute to Kleros court for arbitration. At this point both parties could provide evidence or the users could have defined some sources for the events result, which are sent to the Kleros jury. The jury will make a decision and the smart contract will react to the decision awarding the winner and punishing the other. For the pool to use Kleros there needs to be certain amount of stake locked for a possible court case. In addition a percentage of 5% of the stake of the user who is wrong will be charged.

### *Optional*
There are some rules with how to solve disagreement on bets. In a one to one bet the bet will go automatically to Kleros is there is a disagreement. For one to many bet there is the rule that on the many side at least 75% percent of the users have to agree on the outcome, otherwise the case will go to Kleros.

### *Optional*
Furthermore there users will be rated by the system and get ratings from other users. After a bet is over upon agreement, both users get an increase of their rating depending on the stake. On the other hand if the bet is moved to Klerus the user who was wrong will be punishes with a lower rating accordingly. Users with high rating can also be offered to become a moderator which allows them to remove bets with inappropriate content reported by users.

### *Optional*
Private bets are not visible for users without an invitation.

### *Optional*
Parimutual bets
Next step would be to offer Parimutual bets on our platform. Parimutual bets can also be layed and backed. The same rules that are defined for P2P bets apply for Parimutual bets.

## Use case summary
The minimum requirement is thus for the players to be able to create 1v1 "back" and "lay" bets, for which the result is agreed upon between the players. The winning are spread accordingly according to the agreement of the players. The smart constract allows creation of any kind of bets, but the minimum requirement for the user interface is that there are matches offered in the UI to the players, and from those matches the players can create bets with their preferred odds.
All the optional marked use cases will be developed on top of the minimum requirements if there is sufficient time. These include for example the Kleros arbitration for disagreements and the possibility to create any kind of bet in the UI.

## 1.2 Implementation

## 1.3 Software Architecture

## 1.4 Front-End / Graphical User Interface

