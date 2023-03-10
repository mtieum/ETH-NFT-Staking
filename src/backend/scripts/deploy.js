const { ethers, upgrades } = require("hardhat")

async function main() {
  const [deployer] = await ethers.getSigners();
  let quirklingsNft, quirkiesNft, rewardNft, placeholderNft, nftStaker

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // goerli
  const stakingPeriod =  5 * 60; // 5 Minutes
  let teamWallet = "0x923129ECE79Ffb16B3cCb770474f6B672e68d8e0";
  const Quirkies = await ethers.getContractFactory("Quirkies");
  quirkiesNft = await Quirkies.deploy();
  console.log("Quirkies contract address", quirkiesNft.address);
  saveFrontendFiles(quirkiesNft, "Quirkies");

  const Quirklings = await ethers.getContractFactory("Quirklings");
  quirklingsNft = await Quirklings.deploy();
  console.log("Quirklings contract address", quirklingsNft.address);
  saveFrontendFiles(quirklingsNft, "Quirklings");

  const quirklingsAddress = quirklingsNft.address;
  const quirkiesAddress = quirkiesNft.address;

  // mainnet
  // let teamWallet = "0xD71E736a7eF7a9564528D41c5c656c46c18a2AEd";
  // const quirklingsAddress = ""
  // const quirkiesAddress = ""
  // const stakingPeriod = 30 * 24 * 60 * 60; 30 Days

  const RewardNFT = await ethers.getContractFactory("RewardNFT");
  const PlaceholderNFT = await ethers.getContractFactory("PlaceholderNFT");
  const NFTStaker = await ethers.getContractFactory("NFTStaker");

  rewardNft = await RewardNFT.deploy();
  console.log("RewardNFT contract address", rewardNft.address)
  saveFrontendFiles(rewardNft, "RewardNFT");

  placeholderNft = await PlaceholderNFT.deploy();
  console.log("PlaceholderNFT contract address", placeholderNft.address)
  saveFrontendFiles(placeholderNft, "PlaceholderNFT");

  const useProxy = false;
  if (useProxy) {
    nftStaker = await upgrades.deployProxy(NFTStaker, stakingPeriod, teamWallet, [quirklingsAddress, quirkiesAddress], placeholderNft.address, rewardNft.address, {
      initializer: "constructor"
    });
    await nftStaker.deployed();
  } else {
    nftStaker = await NFTStaker.deploy(stakingPeriod, teamWallet, [quirklingsAddress, quirkiesAddress], placeholderNft.address, rewardNft.address);
  }
  console.log("NFTStaker contract address", nftStaker.address)
  saveFrontendFiles(nftStaker, "NFTStaker");

  await rewardNft.setStakingContract(nftStaker.address);
  await placeholderNft.setStakingContract(nftStaker.address);
  
  if (teamWallet != deployer.address) {
    await quirklingsNft.transferOwnership(teamWallet);
    await rewardNft.transferOwnership(teamWallet);
    await placeholderNft.transferOwnership(teamWallet);
    await nftStaker.transferOwnership(teamWallet);
  }

  console.log("Setter calls done")
}

function saveFrontendFiles(contract, name) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../../frontend/contractsData";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + `/${name}-address.json`,
    JSON.stringify({ address: contract.address }, undefined, 2)
  );

  const contractArtifact = artifacts.readArtifactSync(name);

  fs.writeFileSync(
    contractsDir + `/${name}.json`,
    JSON.stringify(contractArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
