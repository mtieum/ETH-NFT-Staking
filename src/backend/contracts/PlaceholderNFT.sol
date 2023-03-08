// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PlaceholderNFT is ERC721, Pausable, Ownable {

    uint256 private _totalSupply = 0;
    address private _stakingContract;

    mapping (uint256 => uint256) idToMetadataMapping;

    constructor() ERC721("Placeholder Nft", "PN") {}

    // Mint an NFT with an incremental ID
    function mintNFT(address _user, uint256 assetId) external onlyStakingContract returns (uint256) {
        uint256 newTokenId = _totalSupply + 1;
        _safeMint(_user, newTokenId);
        idToMetadataMapping[newTokenId] = assetId;
        _totalSupply++;

        return newTokenId;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(idToMetadataMapping[_tokenId]), ".json"))
            : '';
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
