// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RewardNFT is ERC721, Pausable, Ownable {

    uint256 private _totalSupply = 0;
    address private _stakingContract;

    constructor() ERC721("Reward Nft", "RN") {}

    // Mint an NFT with an incremental ID
    function mintNFT(address _user, uint256 assetId) external onlyStakingContract {
        _safeMint(_user, assetId);
        _totalSupply++;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json"));
    }
    
    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, "NFTCollection: caller is not the staking contract");
        _;
    }

    function setStakingContract(address stakingContract) external onlyOwner {
        _stakingContract = stakingContract;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
