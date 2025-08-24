require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    very: {
      url: process.env.VERY_RPC_URL || "https://rpc.very.network",
      accounts: process.env.OWNER_KEY ? [process.env.OWNER_KEY] : [],
      chainId: process.env.VERY_CHAIN_ID ? parseInt(process.env.VERY_CHAIN_ID) : 1000,
    }
  }
};
