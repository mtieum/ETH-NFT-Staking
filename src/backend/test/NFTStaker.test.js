const { expect } = require("chai")
const helpers = require("@nomicfoundation/hardhat-network-helpers")

const toWei = (num) => ethers.utils.parseEther(num.toString())
const fromWei = (num) => Math.round(ethers.utils.formatEther(num))

describe("NFTStaker", async function() {
    let deployer, addr1, addr2, nft, stakedNft, rewardNft, nftStaker
    let teamWallet = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

    beforeEach(async function() {
        const NFT = await ethers.getContractFactory("NFT");
        const NFTStaker = await ethers.getContractFactory("NFTStaker");

        [deployer, addr1, addr2] = await ethers.getSigners();
        whitelist = [addr1.address, addr2.address]

        stakedNft = await NFT.deploy();
        rewardNft = await NFT.deploy();
        nftStaker = await NFTStaker.deploy(teamWallet, stakedNft.address, rewardNft.address);
    });

    describe("Staking and unstaking", function() {
        it("Should stake and claim rewards", async function() {
            // Stake
            // await stakedNft.connect(addr1).setApprovalForAll(nftStaker.address, true);

            await expect(nftStaker.connect(addr1).stake(0)).to.be.revertedWith('Stake amount incorrect');
            await expect(nftStaker.connect(addr1).stake(11)).to.be.revertedWith('Stake amount incorrect');

            // await nftStaker.connect(addr1).stake(8);
            
            // expect((await nftStaker.getStakedTokens(addr1.address))[0]).to.equals(333);

            // expect((await nft.ownerOf(333))).to.equals(nftStaker.address);
            // expect((await token.balanceOf(addr1.address))).to.equals(0);
            // expect((await token.balanceOf(nftStaker.address))).to.equals(stakerTokenAmount);

            // // Unstake after 11 days
            // const elevenDays = 11 * 24 * 60 * 60 + 10;
            // await helpers.time.increase(elevenDays);

            // // await nftStaker.connect(addr1).unstake(333);

            // const expectedReward = 10 * (24 / hoursForUnitReward);
            // expect((await nftStaker.getRewardToClaim(addr1.address))).to.equals(expectedReward);
            // await nftStaker.connect(addr1).claimReward();
            // expect((await nft.ownerOf(333))).to.equals(nftStaker.address);

            // // Expecting 50 units as reward
            // console.log("Expected Reward: " + expectedReward)
            // console.log("Staker actual new balance: " + fromWei(await token.balanceOf(addr1.address)))

            // expect((await token.balanceOf(addr1.address))).to.equals(expectedReward);
            // expect((await token.balanceOf(nftStaker.address))).to.equals(stakerTokenAmount - expectedReward);
            
            // expect((await nftStaker.getRewardToClaim(addr1.address))).to.equals(0);
            // await expect(nftStaker.connect(addr1).claimReward()).to.be.revertedWith('No tokens to claim.');
            
            // await nftStaker.connect(addr1).unstake(333);

            // expect((await token.balanceOf(addr1.address))).to.equals(expectedReward);
            // expect((await token.balanceOf(nftStaker.address))).to.equals(stakerTokenAmount - expectedReward);
            
            // await expect(nftStaker.connect(addr1).claimReward()).to.be.revertedWith('No tokens to claim.');

            // expect((await token.balanceOf(addr1.address))).to.equals(expectedReward);
            // expect((await token.balanceOf(nftStaker.address))).to.equals(stakerTokenAmount - expectedReward);
        })

        it("Should track staking wallets and display what is being staked currently", async function() {
        })
    })
})