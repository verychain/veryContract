require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    very: {
      url: process.env.VERY_RPC_URL || "https://rpc.very.network",
      accounts: process.env.OWNER_KEY ? [process.env.OWNER_KEY] : [],
      chainId: process.env.VERY_CHAIN_ID ? parseInt(process.env.VERY_CHAIN_ID) : 1000,
    }
  },
  etherscan: {
    apiKey: {
      very: process.env.EXPLORER_API_KEY || "blockscout",         // Blockscout면 빈 문자열도 OK
    },
    customChains: [
      {
        network: "very",
        chainId: 4613,
        urls: {
          apiURL: "https://www.veryscan.io/api", // ✅ 실제 API 엔드포인트
          browserURL: "https://veryscan.io/", // ✅ 브라우저 URL
        },
      },
    ],
  },
  // (선택) Sourcify 자동 업로드 켜기
  sourcify: { enabled: false },
};
