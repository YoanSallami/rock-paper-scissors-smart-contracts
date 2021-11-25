// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./YankenpoFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title YankenpoControl
 * @dev Smart contract that manage the maintainer and treasurer roles
 * and functions.
 */
contract YankenpoControl is AccessControl {

    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    address factory;

    /**
     * @dev Smart contract constructor
     */
    constructor() AccessControl() {
        address factory_addr = address(new YankenpoFactory());
        factory = factory_addr;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Function that pause game creation.
     * Requirement: the factory need to transfer its ownership to this contract.
     * @param factory_addr The new factory address
     */
    function setFactoryAddr(address factory_addr) public
        onlyRole(MAINTAINER_ROLE)
    {
        factory = factory_addr;
    }

    /**
     * @dev Function that pause game creation.
     */
    function pauseGameCreation() public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(factory).pauseGameCreation();
    }

    /**
     * @dev Function that unpause game creation.
     */
    function unpauseGameCreation() public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(factory).unpauseGameCreation();
    }

    /**
     * @dev Function that set the minimal bet.
     * @param bet The minimum bet.
     */
    function setMinimumBet(uint256 bet) public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(factory).setMinimumBet((bet));
    }

    /**
     * @dev Function that set the commision percent.
     * @param percent The commision percent.
     */
    function setCommisionPercent(uint8 percent) public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(factory).setCommisionPercent(percent);
    }

    /**
     * @dev Function that set the round expirationt time.
     * @param time The expiration time.
     */
    function setRoundExpirationTime(uint256 time) public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(factory).setRoundExpirationTime(time);
    }

    /**
     * @dev Function that withdraw the commision.
     */
    function withdrawCommision() public payable
        onlyRole(TREASURER_ROLE)
    {
        YankenpoFactory(factory).withdrawCommision(payable(_msgSender()));
    }

}