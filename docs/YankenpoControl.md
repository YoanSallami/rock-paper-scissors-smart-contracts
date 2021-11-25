## `YankenpoControl`



Smart contract that manage the maintainer and treasurer roles
and functions.


### `constructor()` (public)



Smart contract constructor

### `setFactoryAddr(address factory_addr)` (public)



Function that pause game creation.
Requirement: the factory need to transfer its ownership to this contract.


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


### `withdrawCommision()` (public)



Function that withdraw the commision.




