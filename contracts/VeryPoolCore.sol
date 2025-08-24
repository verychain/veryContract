// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable }                from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable }           from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable }          from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable }   from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @dev Trade 로그 (유저별 tradeId 단위 에스크로)
 * - from: 입금자(유저)
 * - to:   관리자 확정 시 송금 대상(최초 확정 시 고정)
 * - amount: 현재 에스크로 잔액(누적)
 */
struct Trade {
    uint256 tradeId;
    uint256 depositAmount;
    uint256 tradeAmount;
    uint256 createdAt;
    uint256 updatedAt;
    address from;
    address to;
    bool    isCancelled;
    bool    isCompleted;
}

contract VeryPoolCore is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    address public veryPoolTreasury;

    // user => tradeId => Trade
    mapping(address => mapping(uint256 => Trade)) public tradeLogs;

    event Deposited(address indexed user, uint256 amount, uint256 timestamp, uint256 tradeId);
    event Cancelled(address indexed user, uint256 amount, uint256 timestamp, uint256 tradeId);
    event Confirmed(address indexed user, address indexed to, uint256 amount, uint256 timestamp, uint256 tradeId);

    function initialize(address _initialOwner, address _veryPoolTreasury) public initializer {
        __Ownable_init(_initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_veryPoolTreasury != address(0), "Invalid treasury address");
        veryPoolTreasury = _veryPoolTreasury;
    }

    /* ---------------------- Emergency Pause ---------------------- */

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /* -------------------- Getter & Setter ------------------------ */

    function getTradeInfo(address user, uint256 tradeId) external view returns (Trade memory) {
        return tradeLogs[user][tradeId];
    }

    function setVeryPoolTreasury(address _veryPoolTreasury) external onlyOwner {
        require(_veryPoolTreasury != address(0), "Invalid treasury address");
        veryPoolTreasury = _veryPoolTreasury;
    }

    function getVeryPoolTreasury() external view returns (address) {
        return veryPoolTreasury;
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /* ------------------------ Core Logic ------------------------- */

    /// @notice 유저가 네이티브 토큰 입금 (tradeId별 에스크로 적립)
    function deposit(uint256 tradeId, uint256 tradeAmount) external payable whenNotPaused nonReentrant {
        require(tradeId != 0, "Invalid tradeId");
        require(msg.value > 0, "Must send native");
        require(msg.value >= tradeAmount, "Insufficient amount");

        Trade storage t = tradeLogs[msg.sender][tradeId];

        if (t.tradeId == 0) {
            // 신규 생성
            t.tradeId   = tradeId;
            t.from      = msg.sender;
            t.to        = address(0);
            t.depositAmount    = msg.value;
            t.tradeAmount      = tradeAmount;
            t.createdAt = block.timestamp;
            t.updatedAt = block.timestamp;
            t.isCancelled = false;
            t.isCompleted = false;
        } else {
            // 기존 적립
            require(!t.isCancelled, "Trade cancelled");
            require(!t.isCompleted, "Trade completed");
            require(t.from == msg.sender, "Not trade owner");
            
            t.depositAmount += msg.value;
            t.tradeAmount   += tradeAmount;
            t.updatedAt  = block.timestamp;
        }

        emit Deposited(msg.sender, msg.value, block.timestamp, tradeId);
    }

    /// @notice 관리자 취소(전액 환불).
    function cancelTrade(address user, uint256 tradeId)
        external
        onlyOwner
        nonReentrant
    {
        require(tradeId != 0, "Invalid tradeId");

        Trade storage t = tradeLogs[user][tradeId];
        require(t.tradeId != 0, "Trade not found");
        require(!t.isCancelled, "Already cancelled");
        require(!t.isCompleted, "Already completed");
        require(t.tradeAmount > 0, "No escrow");
        require(t.depositAmount >= t.tradeAmount, "Insufficient deposit");

        uint256 refund = t.tradeAmount;

        // 상태 선반영 (Checks-Effects-Interactions)
        t.isCancelled = true;
        t.updatedAt   = block.timestamp;
        t.tradeAmount   = 0;

        (bool okToUser, ) = payable(user).call{value: refund}("");
        require(okToUser, "Refund failed");

        (bool okToTreasury, ) = payable(t.from).call{value: t.depositAmount - refund}("");
        require(okToTreasury, "Refund failed");

        emit Cancelled(user, refund, block.timestamp, tradeId);
    }

    /// @notice 관리자 확정(전액 송금). 처음 확정 시 `to` 고정, 이후 동일 `to`만 허용.
    function confirmTrade(address user, uint256 tradeId, address to)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        require(tradeId != 0, "Invalid tradeId");
        require(to != address(0), "Invalid to");

        Trade storage t = tradeLogs[user][tradeId];
        require(t.tradeId != 0, "Trade not found");
        require(!t.isCancelled, "Trade cancelled");
        require(!t.isCompleted, "Trade completed");
        require(t.tradeAmount > 0, "No escrow");
        require(t.depositAmount >= t.tradeAmount, "Insufficient deposit");

        uint256 payout = t.tradeAmount;

        // 상태 선반영
        t.to = to;
        t.tradeAmount = 0;
        t.isCompleted = true;
        t.updatedAt   = block.timestamp;

        (bool okToUser, ) = payable(t.to).call{value: payout}("");
        require(okToUser, "Release failed");

        (bool okToTreasury, ) = payable(t.from).call{value: t.depositAmount - payout}("");
        require(okToTreasury, "Refund failed");

        emit Confirmed(user, to, payout, block.timestamp, tradeId);
    }

    /* ---------------------- Fallback Guard ----------------------- */
    receive() external payable { revert("Use deposit()"); }
    fallback() external payable { revert("Invalid call"); }
}
