// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTStaker is ERC721Holder, ReentrancyGuard, Ownable {
    ERC721 public stakedNft;
    ERC721 public rewardNft;

    uint256 stakeMinimum = 1;
    uint256 stakeMaximum = 10;
    uint256 stakePeriodInDays = 30;

    mapping (uint256 => bool) claimedNfts; // After claiming, that staked NFTs wont be able to be staked again ever

    // Staker must be structured this way because of the important function getStakedTokens() below that returns the tokenIds array directly.
    struct Staker { 
        uint256[] tokenIds;
        uint256[] timestamps;
        bool[] tokensReceived;
    }

    mapping(address => Staker) private stakers;
    
    event StakeSuccessful(
        uint256 tokenId,
        uint256 timestamp
    );
    
    event UnstakeSuccessful(
        uint256 tokenId,
        bool rewardClaimed
    );

    constructor(address _ownerAddress, address _stakedNftAddress, address _rewardNftAddress) {
        stakedNft = ERC721(_stakedNftAddress);
        rewardNft = ERC721(_rewardNftAddress);

        transferOwnership(_ownerAddress);
    }

    function stake(uint256 _tokenId) public nonReentrant {
        stakers[msg.sender].tokenIds.push(_tokenId);
        stakers[msg.sender].timestamps.push(block.timestamp);
        stakers[msg.sender].tokensReceived.push(false);
        stakedNft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit StakeSuccessful(_tokenId, block.timestamp);
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

    function unstake(uint256 _tokenId) public nonReentrant {
        Staker memory _staker = stakers[msg.sender];
        (uint256 _tokenIndex, bool _foundIndex) = findIndexForTokenStaker(_tokenId, msg.sender);
        require(_foundIndex, "Index not found for this staker.");

        // Unstake NFT from this smart contract
        stakedNft.safeTransferFrom(address(this), msg.sender, _tokenId);

        bool stakingTimeElapsed = false;
        // if (_staker.tokensReceived[_tokenIndex] == false) {
        //     stakers[msg.sender].tokensReceived[_tokenIndex] = true;
        //     stakers[msg.sender].tokensToClaim += _reward;
        // }
        
        removeStakerElement(_tokenIndex, _staker.tokenIds.length - 1);

        emit UnstakeSuccessful(_tokenId, stakingTimeElapsed);
    }

    function claimReward() external {
        // uint256 _reward = getRewardToClaim(msg.sender);
        // require(_reward > 0, "No tokens to claim.");

        // if (rewardsToken.transfer(msg.sender, _reward) == true) {
        //     uint256 _stakedTokensLength = getStakedTokens(msg.sender).length;
        //     uint256 _currentTimestamp = block.timestamp;
        //     for (uint256 i = 0; i < _stakedTokensLength;) {
        //         bool _isMissionOver = isSpecificMissionOver(stakers[msg.sender].missions[i].startTimestamp, stakers[msg.sender].missions[i].duration, _currentTimestamp);
        //         if (_isMissionOver) { // Don't mark as claimed if the next mission has already been started
        //             stakers[msg.sender].tokensReceived[i] = true;
        //         }
        //         unchecked { ++i; }
        //     }
        //     stakers[msg.sender].tokensToClaim = 0;
        // }
        // else revert();
    }

    function removeStakerElement(uint256 _tokenIndex, uint256 _lastIndex) internal {
        stakers[msg.sender].timestamps[_tokenIndex] = stakers[msg.sender].timestamps[_lastIndex];
        stakers[msg.sender].timestamps.pop();

        stakers[msg.sender].tokenIds[_tokenIndex] = stakers[msg.sender].tokenIds[_lastIndex];
        stakers[msg.sender].tokenIds.pop();

        stakers[msg.sender].tokensReceived[_tokenIndex] = stakers[msg.sender].tokensReceived[_lastIndex];
        stakers[msg.sender].tokensReceived.pop();
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

    function getRewardToClaim(address _user) public view returns (uint256) {
        return 0;

        // uint256 _tokensToClaim = stakers[_user].tokensToClaim;

        // // Find out if some gelatos' missions are over and tokens were not received for them yet
        // uint256 _stakedTokensLength = getStakedTokens(_user).length;

        // uint256 _currentTimestamp = block.timestamp;
        // for (uint256 i = 0; i < _stakedTokensLength;) {
        //     if (!stakers[_user].tokensReceived[i] && isSpecificMissionOver(stakers[_user].missions[i].startTimestamp, stakers[_user].missions[i].duration, _currentTimestamp)) {
        //         _tokensToClaim += getRewardForTokenIndexStaker(i, _user);
        //     }
        //     unchecked { ++i; }
        // }

        // return _tokensToClaim;
    }

}