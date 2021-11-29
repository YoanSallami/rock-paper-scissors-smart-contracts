// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IYankenpoFactory {

    event GameCreated(uint256 game_id, address indexed player_1, uint256 starting_bet);
    event GameJoined(uint256 game_id, address indexed player_2, uint256 starting_bet);
    event Withdrawn(address indexed payee, uint256 amount);

    function createGame(bytes32 access_lock) external payable returns (uint256);
    function joinGame(uint256 game_id, bytes32 access_key) external payable;

    function pauseGameCreation() external;
    function unpauseGameCreation() external;

    function setMinimumBet(uint256 bet) external;
    function setCommisionPercent(uint8 percent) external;
    function setRoundExpirationTime(uint256 time) external;

    function withdraw(address payable payee) external payable;

}