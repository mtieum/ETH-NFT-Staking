// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./RewardNFT.sol";
import "./PlaceholderNFT.sol";
import "./ReentrancyGuard.sol";
import "./MyOwnable.sol";

contract NFTStakerV2 is ERC721Holder, MyOwnable, ReentrancyGuard {
    ERC721[] public stakedNfts; // 10,000 Quirklings, 5,000 Quirkies

    PlaceholderNFT public placeholderNft;
    RewardNFT public rewardNft;

    uint256 stakeMinimum;
    uint256 stakeMaximum;
    // uint256 stakePeriod = 30 * 24 * 60 * 60; // 30 Days
    uint256 stakePeriod;

    mapping (uint256 => bool) public claimedNfts;

    struct Staker { 
        uint256[] tokenIds;
        uint256[] placeholderTokenIds;
        uint256[] timestamps;
    }

    mapping(address => Staker) private stakers;
    address[] stakersAddresses;
    
    event StakeSuccessful(
        uint256 tokenId,
        uint256 timestamp
    );
    
    event UnstakeSuccessful(
        uint256 tokenId,
        bool rewardClaimed
    );

    function testUpgradedContract() public onlyOwner {
        // delete stakedNfts;
        stakedNfts.pop();
    }
}