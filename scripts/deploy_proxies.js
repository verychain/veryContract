// scripts/deploy_split.js
require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

// ----- 설정 -----
const NODE_TX_FEE_CAP_ETH = "1.0";
const TIP_GWEI = "2";
const GL_TREASURY = 1_800_000n;
const GL_CORE     = 2_500_000n;

// (옵션) 이미 배포된 Treasury 프록시 주소를 여기에 넣으면, core만 배포 가능
const EXISTING_TREASURY_PROXY = process.env.TREASURY_PROXY || ""; // 예: "0x...."

// ===== 공통: 수수료 오버라이드 =====
async function feeOverrides(gasLimitHint) {
  const latest = await ethers.provider.getBlock("latest");
  const baseFee = latest.baseFeePerGas ?? ethers.parseUnits("1", "gwei");
  const tip = ethers.parseUnits(TIP_GWEI, "gwei");

  const reasonableMaxFee = baseFee * 2n + tip; // 보수적 상한
  const capWei = ethers.parseEther(NODE_TX_FEE_CAP_ETH);
  const maxAllowedByCap = capWei / gasLimitHint;

  const maxFeePerGas = reasonableMaxFee < maxAllowedByCap ? reasonableMaxFee : maxAllowedByCap;
  const maxPriorityFeePerGas = tip > maxFeePerGas ? maxFeePerGas : tip;

  const expectedMaxCost = gasLimitHint * maxFeePerGas;
  console.log(
    `gasLimit=${gasLimitHint} baseFee=${ethers.formatUnits(baseFee,"gwei")} gwei ` +
    `maxFee=${ethers.formatUnits(maxFeePerGas,"gwei")} gwei tip=${ethers.formatUnits(maxPriorityFeePerGas,"gwei")} gwei ` +
    `maxCost<=${ethers.formatEther(expectedMaxCost)} ETH`
  );

  return { maxFeePerGas, maxPriorityFeePerGas, gasLimit: gasLimitHint };
}

// ===== 헬퍼: 프록시 정보 로그 =====
async function logProxyInfo(label, proxyAddress) {
  const impl = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  const admin = await upgrades.erc1967.getAdminAddress(proxyAddress);
  console.log(`${label} Proxy: ${proxyAddress}`);
  console.log(`${label} Impl : ${impl}`);
  console.log(`${label} Admin: ${admin}`);
}

// ===== 1) Treasury 배포 =====
async function deployTreasury() {
  if (!process.env.OWNER_KEY) throw new Error("Missing OWNER_KEY in .env");
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const treasuryOv = await feeOverrides(GL_TREASURY);
  const Treasury = await ethers.getContractFactory("VeryPoolTreasury");
  const treasury = await upgrades.deployProxy(
    Treasury,
    [deployer.address],
    {
      initializer: "initialize",
      txOverrides: treasuryOv, // 버전에 따라 미지원이면 아래 줄로 대체
      // ...treasuryOv,
    }
  );
  await treasury.waitForDeployment();
  const proxy = await treasury.getAddress();

  console.log("VeryPoolTreasury 배포 완료");
  await logProxyInfo("Treasury", proxy);
  return proxy;
}

// ===== 2) Core 배포 (기존 Treasury 프록시 주소 필요) =====
async function deployCore(treasuryProxyAddress) {
  if (!treasuryProxyAddress) throw new Error("treasuryProxyAddress required");
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const coreOv = await feeOverrides(GL_CORE);
  const Core = await ethers.getContractFactory("VeryPoolCore");
  const core = await upgrades.deployProxy(
    Core,
    [deployer.address, treasuryProxyAddress],
    {
      initializer: "initialize",
      txOverrides: coreOv,
      // ...coreOv,
    }
  );
  await core.waitForDeployment();
  const proxy = await core.getAddress();

  console.log("VeryPoolCore 배포 완료");
  await logProxyInfo("Core", proxy);
  return proxy;
}

// ===== 3) 임의 프록시 주소의 Impl/Admin 확인 전용 =====
async function inspect(proxyAddress, label="Proxy") {
  await logProxyInfo(label, proxyAddress);
}

// ===== 엔트리포인트 =====
async function main() {
  // 시나리오 A) 트레저리 새로 배포 후, 그 주소로 코어 배포
  // const treasuryProxy = await deployTreasury();
  // await deployCore(treasuryProxy);

  // 시나리오 B) 이미 있는 트레저리 주소(EXISTING_TREASURY_PROXY)로 코어만 배포
  if (EXISTING_TREASURY_PROXY) {
    console.log("Using existing Treasury proxy:", EXISTING_TREASURY_PROXY);
    await inspect(EXISTING_TREASURY_PROXY, "Treasury");
    await deployCore(EXISTING_TREASURY_PROXY);
    return;
  }

  // 시나리오 C) 둘 다 새로
  const treasuryProxy = await deployTreasury();
  await deployCore(treasuryProxy);

  // (옵션) 임의 프록시 검사
  // await inspect("0xYourProxy", "Any");
}

main().catch((e) => { console.error(e); process.exit(1); });
