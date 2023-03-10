const { expect } = require("chai")
const { ethers, upgrades } = require("hardhat")
const helpers = require("@nomicfoundation/hardhat-network-helpers")

const toWei = (num) => ethers.utils.parseEther(num.toString())
const fromWei = (num) => Math.round(ethers.utils.formatEther(num))

describe("NFTStaker", async function() {
    let deployer, addr1, addr2, quirkiesNft, quirklingsNft, rewardNft, placeholderNft, nftStaker
    let teamWallet = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    let baseUriPlaceholder = "ipfs://bafybeiay3rypuv7nvtnon7tetgj36jgtl6n34yk5sfph5umhwm3xdlmera"
    let baseUriReward = "ipfs://bafybeiay3rypuv7nvtnon7tetgj36jgtl6n34yk5sfph5umhwm3xdlmera"

    beforeEach(async function() {
        const Quirkies = await ethers.getContractFactory("Quirkies"); // staked NFT
        const Quirklings = await ethers.getContractFactory("Quirklings"); // staked NFT
        const RewardNFT = await ethers.getContractFactory("RewardNFT");
        const PlaceholderNFT = await ethers.getContractFactory("PlaceholderNFT");
        const NFTStaker = await ethers.getContractFactory("NFTStaker");

        [deployer, addr1, addr2] = await ethers.getSigners();
        whitelist = [addr1.address, addr2.address]

        quirkiesNft = await Quirkies.deploy();
        quirklingsNft = await Quirklings.deploy();
        rewardNft = await RewardNFT.deploy();
        placeholderNft = await PlaceholderNFT.deploy();
        nftStaker = await NFTStaker.deploy(30 * 24 * 60 * 60, teamWallet, [quirklingsNft.address, quirkiesNft.address], placeholderNft.address, rewardNft.address);

        await rewardNft.setStakingContract(nftStaker.address);
        await placeholderNft.setStakingContract(nftStaker.address);
    });

    describe("Staking and unstaking", function() {
        it("Should use the proxy structure", async function() {
            const NFTStaker = await ethers.getContractFactory("NFTStaker");
            // let nftStakerProxy = await upgrades.deployProxy(NFTStaker, [30 * 24 * 60 * 60, teamWallet, [quirklingsNft.address, quirkiesNft.address], placeholderNft.address, rewardNft.address], {
            //     initializer: "initialize"
            // });

            // expect((await nftStakerProxy.placeholderNft())).to.equal(placeholderNft.address);
        })

        it("Should stake and claim no rewards before elapsed time", async function() {
            await expect(nftStaker.connect(addr1).stake([])).to.be.revertedWith('Stake amount incorrect');
            await expect(nftStaker.connect(addr1).stake([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])).to.be.revertedWith('Stake amount incorrect');

            await expect(nftStaker.connect(addr1).stake([0])).to.be.revertedWith('ERC721: invalid token ID');
            await quirklingsNft.connect(addr2).mint(1);
            await expect(nftStaker.connect(addr1).stake([0])).to.be.revertedWith('You do not own this Nft');
            await quirklingsNft.connect(addr1).mint(3);
            await expect(nftStaker.connect(addr1).stake([3])).to.be.revertedWith('ERC721: caller is not token owner or approved');
            await quirklingsNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).stake([3]);
            expect((await placeholderNft.ownerOf(0))).to.equals(addr1.address);
            
            expect((await nftStaker.getStakedTokens(addr1.address))[0]).to.equals(3);

            expect((await quirklingsNft.ownerOf(0))).to.equals(addr2.address);
            expect((await quirklingsNft.ownerOf(1))).to.equals(addr1.address);
            expect((await quirklingsNft.ownerOf(2))).to.equals(addr1.address);
            expect((await quirklingsNft.ownerOf(3))).to.equals(nftStaker.address);
            expect((await quirklingsNft.balanceOf(addr1.address))).to.equals(2);
            expect((await placeholderNft.balanceOf(addr1.address))).to.equals(1);

            // Unstake after 10 days
            const days = 10 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);

            await expect(nftStaker.connect(addr1).unstake([0])).to.be.revertedWith('Index not found for this staker.');
            
            {
                expect((await quirklingsNft.ownerOf(0))).to.equals(addr2.address);
                expect((await quirklingsNft.ownerOf(1))).to.equals(addr1.address);
                expect((await quirklingsNft.ownerOf(2))).to.equals(addr1.address);
                expect((await quirklingsNft.ownerOf(3))).to.equals(nftStaker.address);
                expect((await quirklingsNft.balanceOf(addr1.address))).to.equals(2);
            }

            await expect(nftStaker.connect(addr1).unstake([3])).to.be.revertedWith('ERC721: caller is not token owner or approved');
            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([3]);

            expect((await rewardNft.balanceOf(addr1.address))).to.equals(0);
            expect((await placeholderNft.balanceOf(addr1.address))).to.equals(0);
            expect((await quirklingsNft.balanceOf(addr1.address))).to.equals(3);
        })

        it("Should stake and claim rewards after elapsed time", async function() {
            await quirklingsNft.connect(addr1).mint(3);
            await quirklingsNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).stake([2]);

            // Unstake after 30 days
            const days = 30 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);

            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([2]);
            
            expect((await rewardNft.balanceOf(addr1.address))).to.equals(1);
            expect((await placeholderNft.balanceOf(addr1.address))).to.equals(0);
            expect((await quirklingsNft.balanceOf(addr1.address))).to.equals(3);
        })

        it("Should set correct metadata for placeholder and reward", async function() {
            await quirklingsNft.connect(addr1).mint(3);
            await quirklingsNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).stake([2]);
            
            expect((await placeholderNft.idToMetadataMapping(0))).to.equals(2);
            expect((await placeholderNft.tokenURI(0))).to.equals(baseUriPlaceholder + "2.json");

            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([2]);
            await nftStaker.connect(addr1).stake([2]);
            
            expect((await placeholderNft.idToMetadataMapping(1))).to.equals(2);
            expect((await placeholderNft.tokenURI(1))).to.equals(baseUriPlaceholder + "2.json");

            // Unstake after 30 days
            const days = 30 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);

            await nftStaker.connect(addr1).unstake([2]);

            expect((await rewardNft.ownerOf(2))).to.equals(addr1.address);
            expect((await rewardNft.tokenURI(2))).to.equals(baseUriReward + "2.json");
        })

        it("Should track staking wallets and display what is being staked currently", async function() {
            await quirklingsNft.connect(addr1).mint(3);
            await quirklingsNft.connect(addr2).mint(3);
            await quirklingsNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await quirklingsNft.connect(addr2).setApprovalForAll(nftStaker.address, true);

            await nftStaker.connect(addr1).stake([2]);

            expect((await nftStaker.getStakedTokens(addr1.address))[0]).to.equals(2);
            expect((await nftStaker.getPlaceholderTokenIds(addr1.address))[0]).to.equals(0);
            expect((await nftStaker.getStakerAddresses())[0]).to.equals(addr1.address);

            await nftStaker.connect(addr2).stake([4]);

            expect((await nftStaker.getStakedTokens(addr2.address))[0]).to.equals(4);
            expect((await nftStaker.getPlaceholderTokenIds(addr2.address))[0]).to.equals(1);
            expect((await nftStaker.getStakerAddresses())[1]).to.equals(addr2.address);
        })

        it("Should not be able to re stake the same Nft", async function() {
            await quirklingsNft.connect(addr1).mint(3);
            await quirklingsNft.connect(addr1).setApprovalForAll(nftStaker.address, true);

            await nftStaker.connect(addr1).stake([2]);

            const days = 30 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);
            
            expect((await nftStaker.claimedNfts(2))).to.equals(false);

            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([2]);

            expect((await nftStaker.claimedNfts(2))).to.equals(true);
            
            await expect(nftStaker.connect(addr1).stake([2])).to.be.revertedWith('NFT already claimed');
        })

        it("Should stake and claim from the 2nd collection", async function() {
            await quirkiesNft.connect(addr1).mint(3);
            await quirkiesNft.connect(addr1).setApprovalForAll(nftStaker.address, true);

            await nftStaker.connect(addr1).stake([10_002]);

            const days = 30 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);
            
            expect((await nftStaker.claimedNfts(10_002))).to.equals(false);

            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([10_002]);

            expect((await nftStaker.claimedNfts(10_002))).to.equals(true);
            
            await expect(nftStaker.connect(addr1).stake([10_002])).to.be.revertedWith('NFT already claimed');
        })

        it("Should from 2 different collections in one transaction", async function() {
            await quirkiesNft.connect(addr1).mint(3);
            await quirkiesNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await quirklingsNft.connect(addr1).mint(3);
            await quirklingsNft.connect(addr1).setApprovalForAll(nftStaker.address, true);

            await nftStaker.connect(addr1).stake([1, 10_002]);

            const days = 30 * 24 * 60 * 60 + 10;
            await helpers.time.increase(days);
            
            expect((await nftStaker.claimedNfts(1))).to.equals(false);
            expect((await nftStaker.claimedNfts(10_002))).to.equals(false);

            await placeholderNft.connect(addr1).setApprovalForAll(nftStaker.address, true);
            await nftStaker.connect(addr1).unstake([1, 10_002]);

            expect((await nftStaker.claimedNfts(1))).to.equals(true);
            expect((await nftStaker.claimedNfts(10_002))).to.equals(true);
            
            await expect(nftStaker.connect(addr1).stake([1])).to.be.revertedWith('NFT already claimed');
            await expect(nftStaker.connect(addr1).stake([10_002])).to.be.revertedWith('NFT already claimed');
        })
    })
})