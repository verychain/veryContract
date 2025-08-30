
# VeryPool Contracts

> **Upgradable escrow & treasury contracts for P2P trade settlement.**
> 유저별 `tradeId` 단위의 에스크로 관리와 트레저리 출금 기능을 제공합니다.

---

## 📦 Contracts

### `VeryPoolCore.sol`

* **역할:** P2P 거래를 위한 에스크로 관리
* **구조:** `user → tradeId → Trade`
* **주요 기능**

  * `deposit(tradeId, tradeAmount)`:
    유저가 네이티브 토큰(ETH 등)을 `tradeId`별로 에스크로 입금
  * `cancelTrade(user, tradeId)`:
    관리자 취소 시 전액 환불 처리
  * `confirmTrade(user, tradeId, to)`:
    거래 확정 시 수취자(`to`)에게 송금, 이후 동일 `to`만 허용
  * `pause / unpause`:
    비상 정지 기능
  * 조회 기능: `getTradeInfo`, `contractBalance`, `getVeryPoolTreasury` 등

### `VeryPoolTreasury.sol`

* **역할:** 업그레이더블 트레저리 (네이티브 토큰만 보관)
* **주요 기능**

  * `claimNative(to, amount)`:
    오너 전용 출금
  * `treasuryBalance()`:
    트레저리 보유 잔액 조회
  * 외부에서 네이티브 입금 허용 (`receive()`)

---

## 🛠️ Tech Stack

* Solidity `^0.8.20`
* OpenZeppelin Upgradeable Contracts

  * `OwnableUpgradeable`, `PausableUpgradeable`, `ReentrancyGuardUpgradeable`
* Proxy Pattern: **Transparent Proxy (Hardhat Upgrades 호환)**

---

## 🚀 Deployment

```bash
# Install deps
npm install

# Compile
npx hardhat compile

# Deploy (example)
npx hardhat run scripts/deploy.ts --network <network-name>
```

---

## 🔒 Security

* **Checks-Effects-Interactions** 패턴 적용
* `nonReentrant`로 재진입 방지
* `pause()`를 통한 비상 정지 가능

---

## 📜 License

MIT

## 📂 Deploy report  
Treasury Proxy: 0x93b0fb5B0c7B447924acbfC152971340ea5a1C7A   
Treasury Impl : 0x1cA61E66c0c742D1C44a601cda0Efa7fD53dc2Ab   
Treasury Admin: 0xbfF64fc7C58bf098b61c5D371Cfbe84618d4E8fe   
   
Core Proxy: 0x4C59643cDc3974763aD02D4b3dc0Fa58E5B971FD   
Core Impl : 0x6D862be31b1A2C601087dAeE76b2757eDC6AC3c6   
Core Admin: 0xa0dbDF4c9F1e6CfE966822BF7E095983Df37fE3e   
