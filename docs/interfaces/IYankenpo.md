## `IYankenpo`






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





### `joinGame(address player)` (external)





### `cancelGame()` (external)





### `commitRound(bytes32 commitment)` (external)





### `playRound(uint8 choice)` (external)





### `revealRound(uint8 choice, bytes32 nonce)` (external)





### `claimRoundTimeout()` (external)





### `withdraw()` (external)






### `NewRound(uint256 round_id, address player_1, address player_2)`





### `RoundCommited(uint256 round_id, address player_1, address player_2)`





### `RoundPlayed(uint256 round_id, address player_1, address player_2)`





### `RoundRevealed(uint256 round_id, address player_1, address player_2)`





### `RoundTimeout(uint256 round_id, address player_1, address player_2)`





### `GameStarted(address player_1, uint256 pending_bet)`





### `GameReady(address player_1, address player_2, uint256 pending_bet)`





### `GameFinished(address winner, address looser)`





### `GameCanceled(address player_1, uint256 pending_bet)`





### `Withdrawn(address payee, uint256 bet)`







