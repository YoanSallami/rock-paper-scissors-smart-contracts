## `YankenpoFactory`



The factory smart contract that manage Rock-Paper-Cissor games.
In addition this contract store the commision of the platform.


### `constructor()` (public)



Smart contract constructor.

### `getDeployedGames() → address[]` (public)



Function that return the deployed games addresses.


### `createGame(bytes32 access_key) → uint256` (public)



Function that create a new Yankenpo game.


### `joinGame(uint256 game_id, bytes32 access_nonce)` (public)



Function that join an already created game.


### `pauseGameCreation()` (public)



Function that pause game creation.

### `unpauseGameCreation()` (public)



Function that unpause game creation.

### `setMinimumBet(uint256 bet)` (public)



Function that set the minimal bet.


### `setCommisionPercent(uint8 percent)` (public)



Function that set the commision percent.


### `setRoundExpirationTime(uint256 time)` (public)



Function that set the round expirationt time.


### `withdrawCommision(address payable payee)` (public)



Function that withdraw the commision.



### `NewGame(uint256 game_id, address game_addr, address player_1, uint256 starting_bet)`





### `CommisionWithdrawn(address payee, uint256 amount)`







