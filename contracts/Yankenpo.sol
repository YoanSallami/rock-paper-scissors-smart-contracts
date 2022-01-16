// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Yankenpo
 * @dev The smart contract that manage the logic of a Rock-Paper-Cissor game.
 * This contract should be instanciated by a trusted contract that manage the commision.
 * In addition to that, this contract store the bet until the end of the game 
 * to avoid the main contract to manage store it.
 */
contract Yankenpo is Ownable {

  event NewRound(uint roundID, address indexed player1, address indexed player2);
  event RoundCommited(uint256 roundID, address indexed player1, address indexed player2);
  event RoundPlayed(uint256 roundID, address indexed player1, address indexed player2);
  event RoundRevealed(uint256 roundID, address indexed player1, address indexed player2);
  event RoundTimeout(uint256 roundID, address indexed player1, address indexed player2);

  event GameStarted(address indexed player1, uint256 pendingBet);
  event GameReady(address indexed player1, address indexed player2, uint256 pendingBet);
  event GameFinished(address indexed winner, address indexed looser);
  event GameCanceled(address indexed player1, uint256 pendingBet);

  event Withdrawn(address indexed payee, uint256 amount);

  // Variables for the addresses used
  address public player1;
  address public player2;
  address public winner;
  
  // Variables for the bet
  uint public startingBet;
  uint public pendingBet;
  
  // Enum for the machine states
  enum State
  {
    Created,
    Started,
    Ready,
    Finished,
    Canceled
  }

  // Game machine state variable
  State private _state;

  // Constants for the game mechanics 
  uint8 constant UNKNOWN = 0;
  uint8 constant ROCK = 1;
  uint8 constant PAPER = 2;
  uint8 constant CISSOR = 3;

  // Count for win condition
  uint public player1Count = 0;
  uint public player2Count = 0;

  struct Round {
    State state;
    bytes32 commitment;
    uint8 choice;
  }

  // Game rounds
  Round[] public rounds;

  // Variables to manage afk players
  uint256 public roundExpiration = 2**256-1;
  uint256 public roundExpirationTime;
  
  /**
   * @dev Smart contract constructor.
   * @param player The player 1 (creator of the game).
   * @param bet The starting bet to enter the game.
   * @param time The round expiration time.
   */
  constructor(address player,
              uint256 bet,
              uint256 time)
    Ownable()
  {
    player1 = player;
    startingBet = bet;
    roundExpirationTime = time;
    _state = State.Created;
  }

  /**
   * @dev Check that the caller is player 1.
   */
  modifier onlyPlayer1() {
    require(_msgSender() == player1, "Caller is not player 1");
    _;
  }

  /**
   * @dev Check that the caller is not player 1.
   */
  modifier isNotPlayer1() {
    require(_msgSender() != player1, "Caller is player 1");
    _;
  }

  /**
   * @dev Check that the caller is player 2.
   */
  modifier onlyPlayer2() {
    require(_msgSender() == player2, "Caller is not player 2");
    _;
  }

  /**
   * @dev Check that the caller is the winner.
   */
  modifier onlyWinner() {
    require(_msgSender() == winner, "Caller is not the winner");
    _;
  }

  /**
   * @dev Check that the game is in Created mode.
   */
  modifier whenCreated() {
    require(_state == State.Created, "Game not created");
    _;
  }

  /**
   * @dev Check that the game is in Started mode.
   */
  modifier whenStarted() {
    require(_state == State.Started, "Game not started");
    _;
  }

  /**
   * @dev Check that the game is in Ready state.
   */
  modifier whenReady() {
    require(_state == State.Ready, "Game not ready");
    _;
  }

  /**
   * @dev Check that the game is in Finished state.
   */
  modifier whenFinished() {
    require(_state == State.Finished, "Game not finished");
    _;
  }

  /**
   * @dev Check that the game is in Canceled state.
   */
  modifier whenCanceled() {
    require(_state == State.Canceled, "Game not canceled");
    _;
  }

  /**
   * @dev Check that the last round is in Created state.
   */
  modifier whenRoundCreated() {
    require(_getLastRound().state == State.Created, "Last round not started");
    _;
  }

  /**
   * @dev Check that the last round is in Started state.
   */
  modifier whenRoundStarted() {
    require(_getLastRound().state == State.Started, "Last round not started");
    _;
  }

  /**
   * @dev Check that the last round is in Ready state.
   */
  modifier whenRoundReady() {
    require(_getLastRound().state == State.Ready, "Last round not ready");
    _;
  }

  /**
   * @dev Check that the last round is in Finished state.
   */
  modifier whenRoundFinised() {
    require(_getLastRound().state == State.Finished, "Last round not finised");
    _;
  }

  /**
   * @dev Check that the last round is in Canceled state.
   */
  modifier whenRoundCanceled() {
    require(_getLastRound().state == State.Canceled, "Last round not canceled");
    _;
  }

  /**
   * @dev Check that the last round is expired
   */
  modifier whenRoundExpired() {
    require(_getLastRound().state == State.Ready && block.timestamp >= roundExpiration, "Last round is not expired");
    _;
  }

  function isGameCreated() external view returns (bool) {
    return (_state == State.Created);
  }

  function isGameStarted() external view returns (bool) {
    return (_state == State.Started);
  }

  function isGameReady() external view returns (bool) {
    return (_state == State.Ready);
  }

  function isGameFinished() external view returns (bool) {
    return (_state == State.Finished);
  }

  function isGameCanceled() external view returns (bool) {
    return (_state == State.Canceled);
  }

  function isRoundCreated() external view returns (bool) {
    return (_getLastRound().state == State.Created);
  }

  function isRoundStarted() external view returns (bool) {
    return (_getLastRound().state == State.Started);
  }

  function isRoundReady() external view returns (bool) {
    return (_getLastRound().state == State.Ready);
  }

  function isRoundFinished() external view returns (bool) {
    return (_getLastRound().state == State.Finished);
  }

  function isRoundCanceled() external view returns (bool) {
    return (_getLastRound().state == State.Canceled);
  }

  /**
   * @dev Function that get the last round of the game.
   */
  function _getLastRound() private view returns (Round storage)
  {
    return (rounds[rounds.length-1]);
  }

  /**
   * @dev Function that update the winner of the game.
   */
  function _updateWinner() private returns (bool)
  {
    if (player1Count > player2Count && player1Count - player2Count >= 3) {
      winner = player1;
      _state = State.Finished;
      emit GameFinished(winner, player2);
      return true;
    } else if (player2Count > player1Count && player2Count - player1Count >= 3) {
      winner = player2;
      _state = State.Finished;
      emit GameFinished(winner, player1);
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Function that create a new round.
   */
  function _createRound() private returns (uint256)
  {
      // Create a new round
    rounds.push(Round(State.Created, 0, 0));
    uint256 roundID = rounds.length - 1;
    emit NewRound(roundID, player1, player2);
    return roundID;
  }

  /**
   * @dev Start the game by getting the first part of the bet,
   * only player factory contract should start the game.
   */
  function startGame() external virtual payable
    onlyOwner()
    whenCreated()
  {
    pendingBet = msg.value;
    _state = State.Started;
    emit GameStarted(player1, pendingBet);
  }

  /**
   * @dev Function to join the game by getting the second part of the bet.
   * @param player The player 2 address.
   */
  function joinGame(address player) external virtual payable
    onlyOwner()
    whenStarted()
  {
    player2 = player;
    pendingBet += msg.value;
    _createRound();
    _state = State.Ready;
    emit GameReady(player1, player2, pendingBet);
  }
  
  /**
   * @dev Function that cancel the game if nobody joined it and get back the bet.
   * Only player 1 should be able to cancel the game.
   */
  function cancelGame() external virtual
    onlyPlayer1()
    whenStarted()
  {
    _state = State.Canceled;
    emit GameCanceled(_msgSender(), pendingBet);
  }
  
  /**
   * @dev Function commit the player 1 choice as a secret.
   * Only player 1 should be able to commit.
   */
  function commitRound(bytes32 commitment) external
    onlyPlayer1()
    whenReady()
    whenRoundCreated()
  {
    _getLastRound().commitment = commitment;
    _getLastRound().state = State.Started;
    emit RoundCommited(rounds.length-1, player1, player2);
  }
  
  /**
   * @dev Function that play against the player 1 by making a choice.
   * Only player 2 should be able to play.
   * @param choice the choice made by player 2
   */
  function playRound(uint8 choice) external
    onlyPlayer2()
    whenReady()
    whenRoundStarted()
  {
    _getLastRound().choice = choice;
    roundExpiration = block.timestamp + roundExpirationTime;
    _getLastRound().state = State.Ready;
    emit RoundPlayed(rounds.length-1, player1, player2);
  }
  
  /**
   * @dev Function that reveal the secret choice made by player 1 and create
   * a new round if needed, only player 1 should reveal.
   * @param choice The choice made by player 1.
   * @param nonce The nonce used to create the secret.
   */
  function revealRound(uint8 choice, bytes32 nonce) external
    onlyPlayer1()
    whenReady()
    whenRoundReady()
  {
    require(choice >= ROCK && choice <= CISSOR, "Choice is invalid");
    // Check that the hash previously stored correspond to the choice + nonce
    require(keccak256(abi.encodePacked(choice, nonce)) == _getLastRound().commitment, "Cannot reveal, hash do not match");
    
    if(choice == ROCK && _getLastRound().choice == PAPER){
      player2Count += 1;
    } else if(choice == ROCK && _getLastRound().choice == CISSOR){
      player1Count += 1;
    } else if(choice == PAPER && _getLastRound().choice == ROCK){
      player1Count += 1;
    } else if(choice == PAPER && _getLastRound().choice == CISSOR){
      player2Count += 1;
    } else if(choice == CISSOR && _getLastRound().choice == ROCK){
      player2Count += 1;
    } else if(choice == CISSOR && _getLastRound().choice == PAPER){
      player1Count += 1;
    } else {
        // Nothing to do
    }
    _getLastRound().state = State.Finished;
    emit RoundRevealed(rounds.length-1, player1, player2);
    if (_updateWinner() == false) {
      // Then continue the game by creating a new round
      _createRound();
    }
  }
  
  /**
   * @dev Function that claim the round if player 1 do not reveal his secret,
   * only player 2 can claim the round.
   */
  function claimRoundTimeout() external
    onlyPlayer2()
    whenReady()
    whenRoundExpired()
  {
    player2Count += 1;
    _getLastRound().state = State.Canceled;
    emit RoundTimeout(rounds.length-1, player1, player2);
    if (_updateWinner() == false) {
      // Then continue the game by creating a new round
      _createRound();
    }
  }

  /**
   * @dev Withdraw the bet.
   */
  function withdraw() external virtual payable
    whenFinished()
  {
    require( _state == State.Canceled || _state == State.Finished);
    address payee;
    if (_state == State.Canceled) {
      require (_msgSender() == player1);
      payee = player1;
    } else {
      require (_msgSender() == winner);
      payee = winner;
    }
    uint256 payment = pendingBet;
    pendingBet = 0;
    payable(payee).transfer(payment);
    emit Withdrawn(payee, payment);
  }

}