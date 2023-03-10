// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Quirklings is Ownable, ERC721, ReentrancyGuard {
    uint256 public nftPrice = 0.2 ether;
    uint256 public totalSupply = 0;

    uint256 public constant nftLimit = 10000;
    // uint256 public constant mintLimit = 5000;
    // uint256 public constant claimLimit = 5000;
    uint256 public constant mintLimit = 10000;
    uint256 public constant claimLimit = 0;
    uint256 public reserved = 50;
    uint256 public capWhitelist = 1;
    uint256 public capPublic = 1;

    bool public saleClaim = false;
    bool public saleWhitelist = false;
    bool public salePublic = false;

    address public claimAddress;
    uint256 public mintCount = 0;
    bytes32 public merkleRoot;

    string public baseURI = "http://quirklings-metadata.quirkies.io/";

    mapping(address => uint256) public whitelistAddresses;
    mapping(uint256 => uint256) public claimedTokens;

    constructor(
        // string memory _initURI,
        // bytes32 _merkleRoot,
        // address _claimAddress
    ) ERC721("Quirklings", "QRKL") {
        // baseURI = _initURI;
        // merkleRoot = _merkleRoot;
        // claimAddress = _claimAddress;
    }

    function mint(uint256 _amount) public payable nonReentrant {
        // require(tx.origin == msg.sender, "Quirklings: Self Mint Only");
        // require(salePublic == true, "Quirklings: Not Started");
        // require(_amount <= capPublic, "Quirklings: Amount Limit");
        _mint(_amount);
    }

    function mintWhitelist(uint256 _amount)
        public
        payable
        nonReentrant
    {
        require(saleWhitelist == true, "Quirklings: Not Started");
        // require(
        //     MerkleProof.verify(
        //         proof,
        //         merkleRoot,
        //         keccak256(abi.encodePacked(_msgSender()))
        //     ),
        //     "Quirklings: Not Whitelisted"
        // );
        require(
            whitelistAddresses[_msgSender()] + _amount <= capWhitelist,
            "Quirklings: Amount Limit"
        );
        _mint(_amount);
        whitelistAddresses[_msgSender()] += _amount;
    }

    function mintClaim(uint256[] memory _tokenIds) public nonReentrant {
        require(saleClaim == true, "Quirklings: Not Started");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(
                IERC721(claimAddress).ownerOf(_tokenId) == _msgSender(),
                "Quirklings: Not Token Owner"
            );
            require(
                claimedTokens[_tokenId] == 0,
                "Quirklings: Token Already Claimed"
            );
            claimedTokens[_tokenId] = 1;
            _safeMint(_msgSender(), _tokenId);
        }
        totalSupply += _tokenIds.length;
    }

    function _mint(uint256 _amount) internal {
        // require(msg.value == nftPrice * _amount, "Quirklings: Incorrect Value");
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = claimLimit + mintCount + i;
            require(_tokenId < nftLimit - reserved, "Quirklings: Sold Out");
            _safeMint(_msgSender(), _tokenId);
        }
        totalSupply += _amount;
        mintCount += _amount;
    }

    function reserve(address[] calldata _tos) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < _tos.length; i++) {
            uint256 _tokenId = claimLimit + mintCount + i;
            require(_tokenId < nftLimit, "Quirklings: Sold Out");
            _safeMint(_tos[i], _tokenId);
        }
        if (reserved > _tos.length) {
            reserved -= _tos.length;
        } else {
            reserved = 0;
        }
        mintCount += _tos.length;
        totalSupply += _tos.length;
    }

    function adminClaimIds(
        address _to,
        uint256[] calldata _tokenIds
    ) public onlyOwner nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId < claimLimit, "Quirklings: Invalid Claim");
            if (claimedTokens[_tokenId] == 0) {
                claimedTokens[_tokenId] = 1;
                _safeMint(_to, _tokenId);
            }
        }
    }

    function adminClaimRange(
        address _to,
        uint256 _start,
        uint256 _end
    ) public onlyOwner nonReentrant {
        require(_end < claimLimit, "Quirklings: Invalid Claim");
        for (uint256 i = _start; i <= _end; i++) {
            if (claimedTokens[i] == 0) {
                claimedTokens[i] = 1;
                _safeMint(_to, i);
            }
        }
    }

    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tokensOfOwner(_owner)[_index];
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _tokenCount = balanceOf(_owner);
        uint256[] memory _tokenIds = new uint256[](_tokenCount);
        uint256 _tokenIndex = 0;
        for (uint256 i = 0; i < nftLimit; i++) {
            if (_exists(i) && ownerOf(i) == _owner) {
                _tokenIds[_tokenIndex] = i;
                _tokenIndex++;
            }
        }
        return _tokenIds;
    }

    function tokenClaimStatus(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory claimed = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            claimed[i] = claimedTokens[_tokenIds[i]];
        }
        return claimed;
    }

    function withdraw() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        address TEAM3 = 0xd56f05CaB51a36e5b17a8e06f4bB286a8104aE98;
        address TEAM2 = 0x1c46a964f9404193AFf03769559cAe1cbDE9e82d;
        address TEAM1 = 0xa176cBefedb9dbF436BfEFC102e4120aa2e9FC9b;

        (bool team3tx, ) = payable(TEAM3).call{value: (_balance * 15) / 100}(
            ""
        );
        require(team3tx, "Quirklings: Transfer 3 Failed");

        (bool team2tx, ) = payable(TEAM2).call{value: (_balance * 45) / 100}(
            ""
        );
        require(team2tx, "Quirklings: Transfer 2 Failed");

        (bool team1tx, ) = payable(TEAM1).call{value: address(this).balance}(
            ""
        );
        require(team1tx, "Quirklings: Transfer 1 Failed");
    }

    function toggleSaleWhitelist() public onlyOwner {
        saleWhitelist = !saleWhitelist;
    }

    function toggleSalePublic() public onlyOwner {
        salePublic = !salePublic;
    }

    function toggleSaleClaim() public onlyOwner {
        saleClaim = !saleClaim;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract"));
    }
}