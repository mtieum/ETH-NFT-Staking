// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./RewardNFT.sol";
import "./PlaceholderNFT.sol";

contract NFTStaker is ERC721Holder, ReentrancyGuard, Ownable {
    ERC721 public stakedNft;
    PlaceholderNFT public placeholderNft;
    RewardNFT public rewardNft;

    uint256 stakeMinimum = 1;
    uint256 stakeMaximum = 10;
    uint256 stakePeriodInDays = 30;

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

    constructor(address _ownerAddress, address _stakedNftAddress, address _placeholderNftAddress, address _rewardNftAddress) {
        stakedNft = ERC721(_stakedNftAddress);
        placeholderNft = PlaceholderNFT(_placeholderNftAddress);
        rewardNft = RewardNFT(_rewardNftAddress);

        transferOwnership(_ownerAddress);
    }

    // take list of stake Nft, mint same amount of placeHolderNft
    // burning optional (only if there)
    function stake(uint256[] memory _tokenIds) public nonReentrant {
        uint256 _quantity = _tokenIds.length;
        require(_quantity >= stakeMinimum && _quantity <= stakeMaximum, "Stake amount incorrect");

        for(uint256 i = 0; i < _quantity; i ++) {
            require(claimedNfts[_tokenIds[i]] == false, "NFT already claimed");
            require(stakedNft.ownerOf(_tokenIds[i]) == msg.sender, "You do not own this Nft");
        }

        for(uint256 i = 0; i < _quantity; i ++) {
            stakedNft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            uint256 _placeholderTokenId = placeholderNft.mintNFT(msg.sender, _tokenIds[i]);
            stakers[msg.sender].tokenIds.push(_tokenIds[i]);
            stakers[msg.sender].placeholderTokenIds.push(_placeholderTokenId);
            stakers[msg.sender].timestamps.push(block.timestamp);

            emit StakeSuccessful(_tokenIds[i], block.timestamp);
        }

        stakersAddresses.push(msg.sender);
    }

    function findIndexForTokenStaker(uint256 _tokenId, address _stakerAddress) private view returns(uint256, bool) {
        Staker memory _staker = stakers[_stakerAddress];

        uint256 _tokenIndex = 0;
        bool _foundIndex = false;
        
        uint256 _tokensLength = _staker.tokenIds.length;
        for(uint256 i = 0; i < _tokensLength; i ++) {
            // console.log("_staker.tokenIds[i]: ", _staker.tokenIds[i]);
            if (_staker.tokenIds[i] == _tokenId) {
                _tokenIndex = i;
                _foundIndex = true;
                break;
            }
        }

        return (_tokenIndex, _foundIndex);
    }

    function unstake(uint256[] memory _tokenIds) public nonReentrant {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _tokenIndex, bool _foundIndex) = findIndexForTokenStaker(_tokenIds[i], msg.sender);
            require(_foundIndex, "Index not found for this staker.");

            stakedNft.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            if (placeholderNft.ownerOf(stakers[msg.sender].placeholderTokenIds[i]) == msg.sender) {
                placeholderNft.safeTransferFrom(
                    msg.sender, 0x000000000000000000000000000000000000dEaD, stakers[msg.sender].placeholderTokenIds[i]);
            }

            bool stakingTimeElapsed = block.timestamp > stakers[msg.sender].timestamps[_tokenIndex] + stakePeriodInDays * 24 * 60 * 60;
            
            if (stakingTimeElapsed) {
                rewardNft.mintNFT(msg.sender, _tokenIds[i]);
                claimedNfts[_tokenIds[i]] = true;
            }
            removeStakerElement(msg.sender, _tokenIndex, stakers[msg.sender].tokenIds.length - 1);

            emit UnstakeSuccessful(_tokenIds[i], stakingTimeElapsed);
        }
    }

    function removeStakerElement(address _user, uint256 _tokenIndex, uint256 _lastIndex) internal {
        stakers[_user].timestamps[_tokenIndex] = stakers[_user].timestamps[_lastIndex];
        stakers[_user].timestamps.pop();

        stakers[_user].tokenIds[_tokenIndex] = stakers[_user].tokenIds[_lastIndex];
        stakers[_user].tokenIds.pop();
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
    
    function getPlaceholderTokenIds(address _user) public view returns (uint256[] memory tokenIds) {
        return stakers[_user].placeholderTokenIds;
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