## `YankenpoFactory`



The factory smart contract that manage Rock-Paper-Cissor games.
In addition this contract store the commision of the platform.


### `constructor()` (public)



Smart contract constructor.

### `createGame(bytes32 access_lock) → uint256` (external)



Function that create a new Yankenpo game.


### `joinGame(uint256 game_id, bytes32 access_key)` (external)



Function that join an already created game.


### `pauseGameCreation()` (external)



Function that pause game creation.

### `unpauseGameCreation()` (external)



Function that unpause game creation.

### `setMinimumBet(uint256 bet)` (external)



Function that set the minimal bet.


### `setCommisionPercent(uint8 percent)` (external)



Function that set the commision percent.


### `setRoundExpirationTime(uint256 time)` (external)



Function that set the round expirationt time.


### `withdraw(address payable payee)` (external)



Function that withdraw the commision.



### `GameCreated(uint256 game_id, address player_1, uint256 starting_bet)`





### `GameJoined(uint256 game_id, address player_2, uint256 starting_bet)`





### `Withdrawn(address payee, uint256 amount)`







