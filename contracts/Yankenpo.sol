// SPDX-License-Identifier: MIT
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

  event NewRound(uint round_id, address indexed player_1, address indexed player_2);
  event RoundCommited(uint256 round_id, address indexed player_1, address indexed player_2);
  event RoundPlayed(uint256 round_id, address indexed player_1, address indexed player_2);
  event RoundRevealed(uint256 round_id, address indexed player_1, address indexed player_2);
  event RoundTimeout(uint256 round_id, address indexed player_1, address indexed player_2);

  event GameStarted(address indexed player_1, uint256 pending_bet);
  event GameReady(address indexed player_1, address indexed player_2, uint256 pending_bet);
  event GameFinished(address indexed winner, address indexed looser);
  event GameCanceled(address indexed player_1, uint256 pending_bet);

  event BetWithdrawn(address indexed player_1, uint256 bet);
  event GainWithdrawn(address indexed winner, uint256 gain);

  // Variables for the addresses used
  address public player_1;
  address public player_2;
  address public winner;
  
  // Variables for the bet
  uint public starting_bet;
  uint public pending_bet;

  bytes32 public access_key;
  
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
  uint8 constant ROCK = 0;
  uint8 constant PAPER = 1;
  uint8 constant CISSOR = 2;

  // Count for win condition
  uint public player_1_count = 0;
  uint public player_2_count = 0;

  struct Round {
    State state;
    bytes32 commitment;
    uint8 choice;
  }

  // Game rounds
  Round[] public rounds;

  // Variables to manage afk players
  uint256 public round_expiration = 2**256-1;
  uint256 public round_expiration_time;
  
  /**
   * @dev Smart contract constructor.
   * @param player The player 1 (creator of the game).
   * @param bet The starting bet to enter the game.
   * @param time The round expiration time.
   */
  constructor(address player,
              bytes32 key,
              uint256 bet,
              uint256 time)
    Ownable()
  {
    player_1 = player;
    access_key = key;
    starting_bet = bet;
    round_expiration_time = time;
    _state = State.Created;
  }

  /**
   * @dev Check that the caller is player 1.
   */
  modifier onlyPlayer1() {
    require(_msgSender() == player_1, "Caller is not player 1");
    _;
  }

  /**
   * @dev Check that the caller is not player 1.
   */
  modifier isNotPlayer1() {
    require(_msgSender() != player_1, "Caller is player 1");
    _;
  }

  /**
   * @dev Check that the caller is player 2.
   */
  modifier onlyPlayer2() {
    require(_msgSender() == player_2, "Caller is not player 2");
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
    require(block.timestamp >= round_expiration, "Last round is not expired");
    _;
  }

  function isGameCreated() public view returns (bool) {
    return (_state == State.Created);
  }

  function isGameStarted() public view returns (bool) {
    return (_state == State.Started);
  }

  function isGameReady() public view returns (bool) {
    return (_state == State.Ready);
  }

  function isGameFinished() public view returns (bool) {
    return (_state == State.Finished);
  }

  function isGameCanceled() public view returns (bool) {
    return (_state == State.Canceled);
  }

  function isRoundCreated() public view returns (bool) {
    return (_getLastRound().state == State.Created);
  }

  function isRoundStarted() public view returns (bool) {
    return (_getLastRound().state == State.Started);
  }

  function isRoundReady() public view returns (bool) {
    return (_getLastRound().state == State.Ready);
  }

  function isRoundFinished() public view returns (bool) {
    return (_getLastRound().state == State.Finished);
  }

  function isRoundCanceled() public view returns (bool) {
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
    if (player_1_count > player_2_count && player_1_count - player_2_count >= 3) {
      winner = player_1;
      _state = State.Finished;
      emit GameFinished(winner, player_2);
      return true;
    } else if (player_2_count > player_1_count && player_2_count - player_1_count >= 3) {
      winner = player_2;
      _state = State.Finished;
      emit GameFinished(winner, player_1);
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
    uint256 round_id = rounds.length - 1;
    emit NewRound(round_id, player_1, player_2);
    return round_id;
  }

  /**
   * @dev Start the game by getting the first part of the bet,
   * only player factory contract should start the game.
   */
  function startGame() public virtual payable
    onlyOwner()
    whenCreated()
  {
    pending_bet = msg.value;
    _state = State.Started;
    emit GameStarted(player_1, pending_bet);
  }

  /**
   * @dev Function to join the game by getting the second part of the bet.
   * @param player The player 2 address.
   */
  function joinGame(address player) public virtual payable
    onlyOwner()
    whenStarted()
  {
    player_2 = player;
    pending_bet += msg.value;
    _createRound();
    _state = State.Ready;
    emit GameReady(player_1, player_2, pending_bet);
  }
  
  /**
   * @dev Function that cancel the game if nobody joined it and get back the bet.
   * Only player 1 should be able to cancel the game.
   */
  function cancelGame() public virtual
    onlyPlayer1()
    whenStarted()
  {
    _state = State.Canceled;
    emit GameCanceled(_msgSender(), pending_bet);
  }
  
  /**
   * @dev Function commit the player 1 choice as a secret.
   * Only player 1 should be able to commit.
   */
  function commitRound(bytes32 commitment) public
    onlyPlayer1()
    whenReady()
    whenRoundCreated()
  {
    _getLastRound().commitment = commitment;
    _getLastRound().state = State.Started;
    emit RoundCommited(rounds.length-1, player_1, player_2);
  }
  
  /**
   * @dev Function that play against the player 1 by making a choice.
   * Only player 2 should be able to play.
   * @param choice the choice made by player 2
   */
  function playRound(uint8 choice) public
    onlyPlayer2()
    whenReady()
    whenRoundStarted()
  {
    _getLastRound().choice = choice;
    round_expiration = block.timestamp + round_expiration_time;
    _getLastRound().state = State.Ready;
    emit RoundPlayed(rounds.length-1, player_1, player_2);
  }
  
  /**
   * @dev Function that reveal the secret choice made by player 1 and create
   * a new round if needed, only player 1 should reveal.
   * @param choice The choice made by player 1.
   * @param nonce The nonce used to create the secret.
   */
  function revealRound(uint8 choice, bytes32 nonce) public
    onlyPlayer1()
    whenReady()
    whenRoundReady()
  {
    require(choice >= ROCK && choice <= CISSOR, "Choice is invalid");
    // Check that the hash previously stored correspond to the choice + nonce
    require(keccak256(abi.encodePacked(choice, nonce)) == _getLastRound().commitment, "Cannot reveal, hash do not match");
    
    if(choice == ROCK && _getLastRound().choice == PAPER){
      player_2_count += 1;
    } else if(choice == ROCK && _getLastRound().choice == CISSOR){
      player_1_count += 1;
    } else if(choice == PAPER && _getLastRound().choice == ROCK){
      player_1_count += 1;
    } else if(choice == PAPER && _getLastRound().choice == CISSOR){
      player_2_count += 1;
    } else if(choice == CISSOR && _getLastRound().choice == ROCK){
      player_2_count += 1;
    } else if(choice == CISSOR && _getLastRound().choice == PAPER){
      player_1_count += 1;
    } else {
        // Nothing to do
    }
    _getLastRound().state = State.Finished;
    emit RoundRevealed(rounds.length-1, player_1, player_2);
    if (_updateWinner() == false) {
      // Then continue the game by creating a new round
      _createRound();
    }
  }
  
  /**
   * @dev Function that claim the round if player 1 do not reveal his secret,
   * only player 2 can claim the round.
   */
  function claimRoundTimeout() public
    onlyPlayer2()
    whenReady()
    whenRoundExpired()
  {
    player_2_count += 1;
    _getLastRound().state = State.Canceled;
    emit RoundTimeout(rounds.length-1, player_1, player_2);
    if (_updateWinner() == false) {
      // Then continue the game by creating a new round
      _createRound();
    }
  }

  /**
   * @dev Withdraw the bet if game canceled, only the player 1 should withdraw.
   */
  function withdrawBet() public virtual payable
    onlyPlayer1()
    whenCanceled()
  {
    uint payment = pending_bet;
    pending_bet = 0;
    payable(player_1).transfer(payment);
    emit BetWithdrawn(player_1, payment);
  }

  /**
   * @dev Withdraw the bet, only the winner should withdraw.
   */
  function withdrawGain() public virtual payable
    onlyWinner()
    whenFinished()
  {
    uint256 payment = pending_bet;
    pending_bet = 0;
    payable(winner).transfer(payment);
    emit GainWithdrawn(winner, payment);
  }

}