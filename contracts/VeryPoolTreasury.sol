// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable }              from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable }         from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title VeryPoolTreasury
 * @notice 업그레이더블 트레저리. 네이티브 토큰(ETH 등)만 보관/출금.
 *         오너만 출금 가능. Hardhat Upgrades(Transparent Proxy)와 호환.
 */
contract VeryPoolTreasury is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event ClaimedNative(address indexed to, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
    }

    /**
     * @notice 오너 전용 네이티브 토큰 출금
     * @param to     수령자 주소
     * @param amount 출금 금액(wei)
     */
    function claimNative(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid to");
        require(amount > 0, "Amount=0");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool ok, ) = payable(to).call{value: amount}("");
        require(ok, "Native transfer failed");

        emit ClaimedNative(to, amount);
    }

    /// @notice 트레저리 보유 네이티브 잔액 조회
    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev 입금 허용 (코어/EOA 모두 가능)
    receive() external payable {}
    fallback() external payable { revert("Invalid call"); }
}
