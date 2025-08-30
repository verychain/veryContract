# VeryPool Contracts

> **Upgradable escrow & treasury contracts for P2P trade settlement.**
> Provides per-`tradeId` escrow management and treasury withdrawal features.

---

## 📦 Contracts

### `VeryPoolCore.sol`

* **Role:** Escrow management for P2P trades
* **Structure:** `user → tradeId → Trade`
* **Key Features:**

  * `deposit(tradeId, tradeAmount)`:
    User deposits native tokens (e.g., ETH) into escrow, managed by `tradeId`
  * `cancelTrade(user, tradeId)`:
    Admin cancels the trade and refunds the full amount
  * `confirmTrade(user, tradeId, to)`:
    Admin confirms the trade, releases funds to the recipient (`to`), and locks to the same `to` thereafter
  * `pause / unpause`:
    Emergency stop mechanism
  * Getter functions: `getTradeInfo`, `contractBalance`, `getVeryPoolTreasury`, etc.

### `VeryPoolTreasury.sol`

* **Role:** Upgradeable treasury (native token only)
* **Key Features:**

  * `claimNative(to, amount)`:
    Owner-only withdrawal
  * `treasuryBalance()`:
    View treasury balance
  * Native deposits supported (`receive()`)

---

## 🛠️ Tech Stack

* Solidity `^0.8.20`
* OpenZeppelin Upgradeable Contracts

  * `OwnableUpgradeable`, `PausableUpgradeable`, `ReentrancyGuardUpgradeable`
* Proxy Pattern: **Transparent Proxy (Hardhat Upgrades compatible)**

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

* Implements **Checks-Effects-Interactions** pattern
* `nonReentrant` guard against re-entrancy
* Emergency stop via `pause()`

---

## 📜 License

MIT

---

## 📂 Deploy Report

**Treasury**

* Proxy: `0x93b0fb5B0c7B447924acbfC152971340ea5a1C7A`
* Impl : `0x1cA61E66c0c742D1C44a601cda0Efa7fD53dc2Ab`
* Admin: `0xbfF64fc7C58bf098b61c5D371Cfbe84618d4E8fe`

**Core**

* Proxy: `0x4C59643cDc3974763aD02D4b3dc0Fa58E5B971FD`
* Impl : `0x6D862be31b1A2C601087dAeE76b2757eDC6AC3c6`
* Admin: `0xa0dbDF4c9F1e6CfE966822BF7E095983Df37fE3e`