## `Yankenpo`



The smart contract that manage the logic of a Rock-Paper-Cissor game.
This contract should be instanciated by a trusted contract that manage the commision.
In addition to that, this contract store the bet until the end of the game 
to avoid the main contract to manage store it.

### `onlyPlayer1()`



Check that the caller is player 1.

### `isNotPlayer1()`



Check that the caller is not player 1.

### `onlyPlayer2()`



Check that the caller is player 2.

### `onlyWinner()`



Check that the caller is the winner.

### `whenCreated()`



Check that the game is in Created mode.

### `whenStarted()`



Check that the game is in Started mode.

### `whenReady()`



Check that the game is in Ready state.

### `whenFinished()`



Check that the game is in Finished state.

### `whenCanceled()`



Check that the game is in Canceled state.

### `whenRoundCreated()`



Check that the last round is in Created state.

### `whenRoundStarted()`



Check that the last round is in Started state.

### `whenRoundReady()`



Check that the last round is in Ready state.

### `whenRoundFinised()`



Check that the last round is in Finished state.

### `whenRoundCanceled()`



Check that the last round is in Canceled state.

### `whenRoundExpired()`



Check that the last round is expired


### `constructor(address player, uint256 bet, uint256 time)` (public)



Smart contract constructor.


### `isGameCreated() → bool` (external)





### `isGameStarted() → bool` (external)





### `isGameReady() → bool` (external)





### `isGameFinished() → bool` (external)





### `isGameCanceled() → bool` (external)





### `isRoundCreated() → bool` (external)





### `isRoundStarted() → bool` (external)





### `isRoundReady() → bool` (external)





### `isRoundFinished() → bool` (external)





### `isRoundCanceled() → bool` (external)





### `startGame()` (external)



Start the game by getting the first part of the bet,
only player factory contract should start the game.

### `joinGame(address player)` (external)



Function to join the game by getting the second part of the bet.


### `cancelGame()` (external)



Function that cancel the game if nobody joined it and get back the bet.
Only player 1 should be able to cancel the game.

### `commitRound(bytes32 commitment)` (external)



Function commit the player 1 choice as a secret.
Only player 1 should be able to commit.

### `playRound(uint8 choice)` (external)



Function that play against the player 1 by making a choice.
Only player 2 should be able to play.


### `revealRound(uint8 choice, bytes32 nonce)` (external)



Function that reveal the secret choice made by player 1 and create
a new round if needed, only player 1 should reveal.


### `claimRoundTimeout()` (external)



Function that claim the round if player 1 do not reveal his secret,
only player 2 can claim the round.

### `withdraw()` (external)



Withdraw the bet.


### `NewRound(uint256 round_id, address player_1, address player_2)`





### `RoundCommited(uint256 round_id, address player_1, address player_2)`





### `RoundPlayed(uint256 round_id, address player_1, address player_2)`





### `RoundRevealed(uint256 round_id, address player_1, address player_2)`





### `RoundTimeout(uint256 round_id, address player_1, address player_2)`





### `GameStarted(address player_1, uint256 pending_bet)`





### `GameReady(address player_1, address player_2, uint256 pending_bet)`





### `GameFinished(address winner, address looser)`





### `GameCanceled(address player_1, uint256 pending_bet)`





### `Withdrawn(address payee, uint256 amount)`






### `Round`


enum Yankenpo.State state


bytes32 commitment


uint8 choice



### `State`

















