// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721, Ownable, ReentrancyGuard {
    uint256 public nftPrice = 0 ether;
    uint256 public totalSupply = 0;

    uint256 public nftLimit = 5000;
    uint256 public reserved = 50;
    uint256 public capWhitelist = 2;
    uint256 public capPublic = 5;

    bool public saleWhitelist = false;
    bool public salePublic = true;

    //bytes32 public merkleRoot;

    string public baseURI = "ipfs://";

    mapping(address => uint256) public presaleAddresses;

    constructor() ERC721("quirkiesTestnet", "QRKST") {}

    function mint(uint256 _amount) public payable nonReentrant {
        require(salePublic == true, "Quirkies: Not Started");
        require(_amount <= capPublic, "Quirkies: Amount Limit");
        require(
            totalSupply + _amount <= (nftLimit - reserved),
            "Quirkies: Sold Out"
        );
        _mint(_amount);
    }

    function mintWhitelist(uint256 _amount)
        public
        payable
        nonReentrant
    {
        require(saleWhitelist == true, "Quirkies: Not Started");
        require(
            presaleAddresses[_msgSender()] + _amount <= capWhitelist,
            "Quirkies: Amount Limit"
        );
        _mint(_amount);
        presaleAddresses[_msgSender()] += _amount;
    }

    function _mint(uint256 _amount) internal {
        require(tx.origin == msg.sender, "Quirkies: Self Mint Only");
        require(
            totalSupply + _amount <= (nftLimit - reserved),
            "Quirkies: Sold Out"
        );
        require(msg.value == nftPrice * _amount, "Quirkies: Incorrect Value");
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_msgSender(), totalSupply);
            totalSupply++;
        }
    }

    function reserve(address[] calldata _tos) external onlyOwner nonReentrant {
        require(totalSupply + _tos.length <= nftLimit, "Quirkies: Sold Out");
        for (uint256 i = 0; i < _tos.length; i++) {
            _safeMint(_tos[i], totalSupply);
            totalSupply++;
            if (reserved > 0) {
                reserved--;
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
        for (uint256 i = 0; i < totalSupply; i++) {
            if (ownerOf(i) == _owner) {
                _tokenIds[_tokenIndex] = i;
                _tokenIndex++;
            }
        }
        return _tokenIds;
    }

    function withdraw() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        address TEAM5 = 0x1350BAA348fC0139999C40e5b80FdC26617E3F67;
        address TEAM4 = 0xec19a74D69329C531B133b6Ad752F5EdebDbdBC5;
        address TEAM3 = 0x74faad5e1f9a5B8427F33D5c8924870c949488f7;
        address TEAM2 = 0x761C9BDE27449415C924C64528BFaA01fbC68A6D;
        address TEAM1 = 0x816639f88d7f5405b0CCB0582908b388a1e2c8Bd;

        (bool t5tx, ) = payable(TEAM5).call{value: (_balance * 10) / 100}("");
        require(t5tx, "Quirkies: Transfer 5 Failed");

        (bool t4tx, ) = payable(TEAM4).call{value: (_balance * 5) / 100}("");
        require(t4tx, "Quirkies: Transfer 4 Failed");

        (bool team3tx, ) = payable(TEAM3).call{value: (_balance * 5) / 100}("");
        require(team3tx, "Quirkies: Transfer 3 Failed");

        (bool team2tx, ) = payable(TEAM2).call{value: (_balance * 5) / 100}("");
        require(team2tx, "Quirkies: Transfer 2 Failed");

        (bool _team1tx, ) = payable(TEAM1).call{value: address(this).balance}(
            ""
        );
        require(_team1tx, "Quirkies: Transfer 1 Failed");
    }

    function toggleSaleWhitelist() public onlyOwner {
        saleWhitelist = !saleWhitelist;
    }

    function toggleSalePublic() public onlyOwner {
        salePublic = !salePublic;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNftPrice(uint256 _nftPrice) public onlyOwner {
        nftPrice = _nftPrice;
    }

    function setNftLimit(uint256 _nftLimit) public onlyOwner {
        nftLimit = _nftLimit;
    }

    /* function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    } */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract"));
    }
}