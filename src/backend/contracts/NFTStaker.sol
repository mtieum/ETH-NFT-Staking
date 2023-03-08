// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./NFT.sol";

contract NFTStaker is ERC721Holder, ReentrancyGuard, Ownable {
    NFT public stakedNft;
    NFT public rewardNft;

    uint256 stakeMinimum = 1;
    uint256 stakeMaximum = 10;
    uint256 stakePeriodInDays = 30;

    mapping (uint256 => bool) claimedNfts;

    struct Staker { 
        uint256[] tokenIds;
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

    constructor(address _ownerAddress, address _stakedNftAddress, address _rewardNftAddress) {
        stakedNft = NFT(_stakedNftAddress);
        rewardNft = NFT(_rewardNftAddress);

        transferOwnership(_ownerAddress);
    }

    function stake(uint256 _quantity) public nonReentrant {
        uint256 _previousSupply = stakedNft.totalSupply();

        for(uint256 i = 0; i < _quantity; i ++) {
            require(claimedNfts[_previousSupply + i] == false, "NFT already claimed");
        }

        stakedNft.mint(_quantity);
        for(uint256 i = 0; i < _quantity; i ++) {
            uint256 _tokenId = _previousSupply + i;
            stakedNft.safeTransferFrom(address(this), msg.sender, _tokenId);
            stakers[msg.sender].tokenIds.push(_tokenId);
            stakers[msg.sender].timestamps.push(block.timestamp);

            emit StakeSuccessful(_tokenId, block.timestamp);
        }

        stakersAddresses.push(msg.sender);
    }

    function findIndexForTokenStaker(uint256 _tokenId, address _stakerAddress) private view returns(uint256, bool) {
        Staker memory _staker = stakers[_stakerAddress];

        uint256 _tokenIndex = 0;
        bool _foundIndex = false;
        
        uint256 _tokensLength = _staker.tokenIds.length;
        for(uint256 i = 0; i < _tokensLength; i ++) {
            if (_staker.tokenIds[i] == _tokenId) {
                _tokenIndex = i;
                _foundIndex = true;
                break;
            }
        }

        return (_tokenIndex, _foundIndex);
    }

    function unstake(uint256[] memory _tokenIds) public nonReentrant {
        Staker memory _staker = stakers[msg.sender];
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _tokenIndex, bool _foundIndex) = findIndexForTokenStaker(_tokenIds[i], msg.sender);
            require(_foundIndex, "Index not found for this staker.");
            stakedNft.safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenIds[i]);

            bool stakingTimeElapsed = block.timestamp > _staker.timestamps[_tokenIndex] + stakePeriodInDays * 24 * 60 * 60;
            
            if (stakingTimeElapsed) {
                rewardNft.mint(1);
                uint256 _latestId = rewardNft.totalSupply();
                rewardNft.safeTransferFrom(address(this), msg.sender, _latestId);

                claimedNfts[_tokenIds[i]] = true;
            }
            removeStakerElement(_tokenIndex, _staker.tokenIds.length - 1);

            emit UnstakeSuccessful(_tokenIds[i], stakingTimeElapsed);
        }
    }

    function removeStakerElement(uint256 _tokenIndex, uint256 _lastIndex) internal {
        stakers[msg.sender].timestamps[_tokenIndex] = stakers[msg.sender].timestamps[_lastIndex];
        stakers[msg.sender].timestamps.pop();

        stakers[msg.sender].tokenIds[_tokenIndex] = stakers[msg.sender].tokenIds[_lastIndex];
        stakers[msg.sender].tokenIds.pop();
    }

    function isTokenStaked(uint256 _tokenId) public view returns(bool) {
        uint256 _tokensLength = stakers[msg.sender].tokenIds.length;
        for(uint256 i = 0; i < _tokensLength; i ++) {
            if (stakers[msg.sender].tokenIds[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }
    
    function getStakedTokens(address _user) public view returns (uint256[] memory tokenIds) {
        return stakers[_user].tokenIds;
    }
    
    function getStakedTimestamps(address _user) public view returns (uint256[] memory timestamps) {
        return stakers[_user].timestamps;
    }
    
    function getStakerAddresses() public view returns (address[] memory) {
        return stakersAddresses;
    }

}