const { ethers, upgrades } = require("hardhat")
const fromWei = (num) => ethers.utils.formatEther(num)

async function main() {
  const [deployer] = await ethers.getSigners();
  let quirklingsNft, quirkiesNft, rewardNft, placeholderNft, nftStaker

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", fromWei(await deployer.getBalance()).toString());
  
  // goerli | Hardhat
  const stakingPeriod =  5 * 60; // 5 Minutes
  stakeMinimum = 1;
  stakeMaximum = 10;
  // hardhat teamWallet
  let teamWallet = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"; 
  // Goerli teamWallet
  //let teamWallet = "0x923129ECE79Ffb16B3cCb770474f6B672e68d8e0";
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
  // let teamWallet = "";
  // const quirklingsAddress = ""
  // const quirkiesAddress = ""
  //stakeMinimum = 1;
  //stakeMaximum = 10;
  // const stakingPeriod = 30 * 24 * 60 * 60; // 30 Days

  const RewardNFT = await ethers.getContractFactory("RewardNFT");
  const PlaceholderNFT = await ethers.getContractFactory("PlaceholderNFT");
  const NFTStaker = await ethers.getContractFactory("NFTStaker");

  rewardNft = await RewardNFT.deploy();
  console.log("RewardNFT contract address", rewardNft.address);
  saveFrontendFiles(rewardNft, "RewardNFT");

  placeholderNft = await PlaceholderNFT.deploy();
  console.log("PlaceholderNFT contract address", placeholderNft.address);
  saveFrontendFiles(placeholderNft, "PlaceholderNFT");

  nftStaker = await upgrades.deployProxy(
    NFTStaker, 
    [stakeMinimum, stakeMaximum, stakingPeriod, teamWallet, [quirklingsAddress, quirkiesAddress], placeholderNft.address, rewardNft.address],
    {
        initializer: "initialize"
    }
  );
  await nftStaker.deployed();

  console.log("NFTStaker contract address", nftStaker.address);
  saveFrontendFiles(nftStaker, "NFTStaker");

  await rewardNft.setStakingContract(nftStaker.address);
  await placeholderNft.setStakingContract(nftStaker.address);
  
  if (teamWallet != deployer.address) {
    await quirkiesNft.transferOwnership(teamWallet);
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
