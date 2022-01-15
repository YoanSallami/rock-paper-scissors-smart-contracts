// SPDX-License-Identifier: GPL-3.0
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

    address private _factoryAddr;
    address private _commissionSplitterAddr;

    /**
     * @dev Smart contract constructor
     */
    constructor() AccessControl() {
        address factoryAddr = address(new YankenpoFactory());
        _factoryAddr = factoryAddr;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Function that set the factory address.
     * Requirement: the factory need to transfer its ownership to this contract.
     * @param factoryAddr The new factory address
     */
    function setFactoryAddr(address factoryAddr) public
        onlyRole(MAINTAINER_ROLE)
    {
        _factoryAddr = factoryAddr;
    }

    /**
     * @dev Function that set the commission splitter address.
     * @param splitterAddr The new commission splitter address
     */
    function setCommissionSplitterAddr(address splitterAddr) public
        onlyRole(MAINTAINER_ROLE)
    {
        _commissionSplitterAddr = splitterAddr;
    }

    /**
     * @dev Function that pause game creation.
     */
    function pauseGameCreation() public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(_factoryAddr).pauseGameCreation();
    }

    /**
     * @dev Function that unpause game creation.
     */
    function unpauseGameCreation() public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(_factoryAddr).unpauseGameCreation();
    }

    /**
     * @dev Function that set the minimal bet.
     * @param bet The minimum bet.
     */
    function setMinimumBet(uint256 bet) public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(_factoryAddr).setMinimumBet((bet));
    }

    /**
     * @dev Function that set the commision percent.
     * @param percent The commision percent.
     */
    function setCommisionPercent(uint8 percent) public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(_factoryAddr).setCommissionPercent(percent);
    }

    /**
     * @dev Function that set the round expirationt time.
     * @param time The expiration time.
     */
    function setRoundExpirationTime(uint256 time) public
        onlyRole(MAINTAINER_ROLE)
    {
        YankenpoFactory(_factoryAddr).setRoundExpirationTime(time);
    }

    /**
     * @dev Function that withdraw the commision.
     */
    function withdraw() public payable
        onlyRole(TREASURER_ROLE)
    {
        YankenpoFactory(_factoryAddr).withdraw(payable(_commissionSplitterAddr));
    }

}