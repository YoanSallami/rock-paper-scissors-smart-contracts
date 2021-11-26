// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './Yankenpo.sol';

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title YankenpoFactory
 * @dev The factory smart contract that manage Rock-Paper-Cissor games.
 * In addition this contract store the commision of the platform.
 */
contract YankenpoFactory is Ownable, Pausable {

  event GameCreated(uint256 game_id, address indexed player_1, uint256 starting_bet);
  event GameJoined(uint256 game_id, address indexed player_2, uint256 starting_bet);
  event CommisionWithdrawn(address indexed payee, uint256 amount);

  address[] public games;

  // Variables to manage afk players
  uint256 internal round_expiration_time = 1 hours;

  // Variables for the business model
  uint256 public minimum_bet;
  uint8 public commision_percent = 7;
  uint256 public commision;

  /**
   * @dev Smart contract constructor.
   */
  constructor() Pausable() Ownable() {}

  /**
   * @dev Function that create a new Yankenpo game.
   * @return The game index.
   */
  function createGame(bytes32 access_lock) public payable virtual
    whenNotPaused() returns (uint256)
  {
    require(msg.value >= minimum_bet, "Bet value not enough");
    // Create the game contract and store it
    address game_addr = address(new Yankenpo(
        _msgSender(),
        access_lock,
        msg.value,
        round_expiration_time));
    games.push(game_addr);
    uint256 game_id = games.length - 1;
    uint256 commision_amount = (msg.value * commision_percent) / 100;
    Yankenpo(games[game_id]).startGame{value: msg.value - commision_amount}();
    commision += commision_amount;
    emit GameCreated(game_id, _msgSender(), msg.value);
    return game_id;
  }
  
  /**
   * @dev Function that join an already created game.
   * @param game_id The game index.
   * @param access_key The secret used to build the access key.
   */
  function joinGame(uint256 game_id, bytes32 access_key) public payable virtual
    whenNotPaused()
  {
    require(_msgSender() != Yankenpo(games[game_id]).player_1(), "Caller is player 1");
    require(Yankenpo(games[game_id]).access_lock() == keccak256(abi.encodePacked(access_key)), "Access key do not match");
    require(msg.value == Yankenpo(games[game_id]).starting_bet(), "Bet value not equals to starting bet");
    uint256 commision_amount = (msg.value * commision_percent) / 100;
    Yankenpo(games[game_id]).joinGame{value: msg.value - commision_amount}(_msgSender());
    commision += commision_amount;
    emit GameJoined(game_id, _msgSender(), msg.value);
  }

  /**
   * @dev Function that pause game creation.
   */
  function pauseGameCreation() public
    onlyOwner()
    whenNotPaused()
  {
    _pause();
  }

  /**
   * @dev Function that unpause game creation.
   */
  function unpauseGameCreation() public
    onlyOwner()
    whenPaused()
  {
    _unpause();
  }

  /**
   * @dev Function that set the minimal bet.
   * @param bet The minimum bet.
   */
  function setMinimumBet(uint256 bet) public
    onlyOwner()
  {
    minimum_bet = bet;
  }

  /**
   * @dev Function that set the commision percent.
   * @param percent The commision percent.
   */
  function setCommisionPercent(uint8 percent) public
    onlyOwner()
  {
    require(percent>0 && percent <=100, "Invalid commision percent");
    commision_percent = percent;
  }

  /**
   * @dev Function that set the round expirationt time.
   * @param time The expiration time.
   */
  function setRoundExpirationTime(uint256 time) public
    onlyOwner()
  {
    round_expiration_time = time;
  }

  /**
   * @dev Function that withdraw the commision.
   * @param payee The payee address.
   */
  function withdrawCommision(address payable payee) public payable
    onlyOwner()
  {
    require(commision>0, "No commision to withdraw");
    uint256 payment = commision;
    commision = 0;
    payee.transfer(payment);
    emit CommisionWithdrawn(payee, payment);
  }

}
