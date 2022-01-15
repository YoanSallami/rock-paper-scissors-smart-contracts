// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import './Yankenpo.sol';

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title YankenpoFactory
 * @dev The factory smart contract that manage Yankenpo (Rock-Paper-Cissor) games.
 * In addition this contract store the commission of the platform.
 */
contract YankenpoFactory is Ownable, Pausable {

  event GameCreated(uint256 gameID, address indexed player1, uint256 startingBet);
  event GameJoined(uint256 gameID, address indexed player2, uint256 startingBet);
  event Withdrawn(address indexed payee, uint256 amount);

  address[] public games;

  mapping(uint256 => bytes32) private _accessLock;

  // Variables to manage afk players
  uint256 internal roundExpirationTime = 1 hours;

  // Variables for the business model
  uint256 public minimum_bet;
  uint8 public commissionPercent = 7*10;
  uint256 public commission;

  /**
   * @dev Smart contract constructor.
   */
  constructor() Pausable() Ownable() {}

  /**
   * @dev Function that create a new Yankenpo game.
   * @return The game index.
   */
  function createGame(bytes32 accessLock) external payable virtual
    whenNotPaused() returns (uint256)
  {
    require(msg.value >= minimum_bet, "Bet value not enough");
    // Create the game contract and store it
    address game_addr = address(new Yankenpo(
        _msgSender(),
        msg.value,
        roundExpirationTime));
    games.push(game_addr);
    uint256 gameID = games.length - 1;
    _accessLock[gameID] = accessLock;
    uint256 commissionAmount = (msg.value * commissionPercent) / 100;
    Yankenpo(games[gameID]).startGame{value: msg.value - commissionAmount}();
    commission += commissionAmount;
    emit GameCreated(gameID, _msgSender(), msg.value);
    return gameID;
  }
  
  /**
   * @dev Function that join an already created game.
   * @param gameID The game index.
   * @param access_key The secret used to build the access key.
   */
  function joinGame(uint256 gameID, bytes32 access_key) external payable virtual
    whenNotPaused()
  {
    require(_msgSender() != Yankenpo(games[gameID]).player1(), "Caller is player 1");
    require(_accessLock[gameID] == keccak256(abi.encodePacked(access_key)), "Access key do not match");
    require(msg.value == Yankenpo(games[gameID]).startingBet(), "Bet value not equals to starting bet");
    uint256 commissionAmount = (msg.value * commissionPercent) / 100*10;
    Yankenpo(games[gameID]).joinGame{value: msg.value - commissionAmount}(_msgSender());
    commission += commissionAmount;
    emit GameJoined(gameID, _msgSender(), msg.value);
  }

  /**
   * @dev Function that pause game creation.
   */
  function pauseGameCreation() external
    onlyOwner()
    whenNotPaused()
  {
    _pause();
  }

  /**
   * @dev Function that unpause game creation.
   */
  function unpauseGameCreation() external
    onlyOwner()
    whenPaused()
  {
    _unpause();
  }

  /**
   * @dev Function that set the minimal bet.
   * @param bet The minimum bet.
   */
  function setMinimumBet(uint256 bet) external
    onlyOwner()
  {
    minimum_bet = bet;
  }

  /**
   * @dev Function that set the commission percent.
   * @param percent The commission percent. 
   * Note: commision percent is defined with e^10 decimals.
   */
  function setCommissionPercent(uint8 percent) external
    onlyOwner()
  {
    require(percent>0 && percent <=100, "Invalid commission percent");
    commissionPercent = percent;
  }

  /**
   * @dev Function that set the round expirationt time.
   * @param time The expiration time.
   */
  function setRoundExpirationTime(uint256 time) external
    onlyOwner()
  {
    roundExpirationTime = time;
  }

  /**
   * @dev Function that withdraw the commission.
   * @param payee The payee address.
   */
  function withdraw(address payable payee) external payable
    onlyOwner()
  {
    require(commission>0, "No commission to withdraw");
    uint256 payment = commission;
    commission = 0;
    payee.transfer(payment);
    emit Withdrawn(payee, payment);
  }

}
