require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  if (!process.env.OWNER_KEY) {
    throw new Error("Missing OWNER_KEY in .env");
  }

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // 1) Treasury 먼저 (owner = deployer)
  const Treasury = await ethers.getContractFactory("VeryPoolTreasury");
  const treasury = await upgrades.deployProxy(Treasury, [deployer.address], {
    initializer: "initialize",
  });
  await treasury.waitForDeployment();
  const treasuryAddr = await treasury.getAddress();
  console.log("VeryPoolTreasury (proxy):", treasuryAddr);

  // 2) Core 배포 (owner = deployer, treasury = treasuryAddr)
  const Core = await ethers.getContractFactory("VeryPoolCore");
  const core = await upgrades.deployProxy(Core, [deployer.address, treasuryAddr], {
    initializer: "initialize",
  });
  await core.waitForDeployment();
  console.log("VeryPoolCore (proxy)   :", await core.getAddress());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
