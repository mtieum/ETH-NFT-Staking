const { expect } = require("chai")
const helpers = require("@nomicfoundation/hardhat-network-helpers")

const toWei = (num) => ethers.utils.parseEther(num.toString())
const fromWei = (num) => Math.round(ethers.utils.formatEther(num))

describe("NFTStaker", async function() {
    let deployer, addr1, addr2, nft, stakedNft, rewardNft, placeholderNft, nftStaker
    let teamWallet = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

    beforeEach(async function() {
        const QuirkiesTestnet = await ethers.getContractFactory("QuirkiesTestnet"); // staked NFT
        const RewardNFT = await ethers.getContractFactory("RewardNFT");
        const PlaceholderNFT = await ethers.getContractFactory("PlaceholderNFT");
        const NFTStaker = await ethers.getContractFactory("NFTStaker");

        [deployer, addr1, addr2] = await ethers.getSigners();
        whitelist = [addr1.address, addr2.address]

        stakedNft = await QuirkiesTestnet.deploy();
        rewardNft = await RewardNFT.deploy();
        placeholderNft = await PlaceholderNFT.deploy();
        nftStaker = await NFTStaker.deploy(teamWallet, stakedNft.address, placeholderNft.address, rewardNft.address);

        await rewardNft.setStakingContract(nftStaker.address);
        await placeholderNft.setStakingContract(nftStaker.address);
    });

    describe("Staking and unstaking", function() {
        it("Should stake and claim rewards", async function() {
            // Stake
            // await stakedNft.connect(addr1).setApprovalForAll(nftStaker.address, true);

            await expect(nftStaker.connect(addr1).stake([])).to.be.revertedWith('Stake amount incorrect');
            await expect(nftStaker.connect(addr1).stake([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])).to.be.revertedWith('Stake amount incorrect');

            await expect(nftStaker.connect(addr1).stake([0])).to.be.revertedWith('ERC721: invalid token ID');
            await stakedNft.connect(addr2).mint(1);
            await expect(nftStaker.connect(addr1).stake([0])).to.be.revertedWith('You do not own this Nft');
            await stakedNft.connect(addr1).mint(3);
            await expect(nftStaker.connect(addr1).stake([3])).to.be.revertedWith('ERC721: caller is not token owner or approved');
            await stakedNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).stake([3]);
            
            expect((await nftStaker.getStakedTokens(addr1.address))[0]).to.equals(3);

            expect((await stakedNft.ownerOf(0))).to.equals(addr2.address);
            expect((await stakedNft.ownerOf(1))).to.equals(addr1.address);
            expect((await stakedNft.ownerOf(2))).to.equals(addr1.address);
            expect((await stakedNft.ownerOf(3))).to.equals(nftStaker.address);
            expect((await stakedNft.balanceOf(addr1.address))).to.equals(2);

            // // Unstake after 10 days
            const days = 10 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);

            await expect(nftStaker.connect(addr1).unstake([0])).to.be.revertedWith('Index not found for this staker.');
            
            {
                expect((await stakedNft.ownerOf(0))).to.equals(addr2.address);
                expect((await stakedNft.ownerOf(1))).to.equals(addr1.address);
                expect((await stakedNft.ownerOf(2))).to.equals(addr1.address);
                expect((await stakedNft.ownerOf(3))).to.equals(nftStaker.address);
                expect((await stakedNft.balanceOf(addr1.address))).to.equals(2);
            }

            await expect(nftStaker.connect(addr1).unstake([3])).to.be.revertedWith('ERC721: caller is not token owner or approved');
            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([3]);
        })

        it("Should track staking wallets and display what is being staked currently", async function() {
        })
    })
})