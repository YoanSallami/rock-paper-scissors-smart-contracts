// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IYankenpo {

    event NewRound(uint round_id, address indexed player_1, address indexed player_2);
    event RoundCommited(uint256 round_id, address indexed player_1, address indexed player_2);
    event RoundPlayed(uint256 round_id, address indexed player_1, address indexed player_2);
    event RoundRevealed(uint256 round_id, address indexed player_1, address indexed player_2);
    event RoundTimeout(uint256 round_id, address indexed player_1, address indexed player_2);

    event GameStarted(address indexed player_1, uint256 pending_bet);
    event GameReady(address indexed player_1, address indexed player_2, uint256 pending_bet);
    event GameFinished(address indexed winner, address indexed looser);
    event GameCanceled(address indexed player_1, uint256 pending_bet);

    event Withdrawn(address indexed payee, uint256 bet);

    function isGameCreated() external view returns (bool);
    function isGameStarted() external view returns (bool);
    function isGameReady() external view returns (bool);
    function isGameFinished() external view returns (bool);
    function isGameCanceled() external view returns (bool);

    function isRoundCreated() external view returns (bool);
    function isRoundStarted() external view returns (bool);
    function isRoundReady() external view returns (bool);
    function isRoundFinished() external view returns (bool);
    function isRoundCanceled() external view returns (bool);

    function startGame() external payable;
    function joinGame(address player) external payable;
    function cancelGame() external;

    function commitRound(bytes32 commitment) external;
    function playRound(uint8 choice) external;
    function revealRound(uint8 choice, bytes32 nonce) external;
    function claimRoundTimeout() external;

    function withdraw() external payable;
    
}