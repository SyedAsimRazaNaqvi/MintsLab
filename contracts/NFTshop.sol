// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// import "./base/ERC721.sol";
// import "./base/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./interface/INFTShop.sol";
import "./interface/IMintsLab.sol";

contract NFTstore is ERC721URIStorage, INFTShop {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _postIds;

    address owner;
    address mintslabFactory;

    mapping(uint256 => Post) public idToPost;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier newOwner(uint256 postId) {
        require(msg.sender == idToPost[postId].newOwner);
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function createPost(
        uint256 price,
        fileType ftype,
        string memory tokenURI
    ) external override onlyOwner returns (uint256) {
        _postIds.increment();
        uint256 postId = _postIds.current();
        Post storage post = idToPost[postId];
        post.postId = postId;
        post.price = price;
        post.newOwner = msg.sender;
        post.ftype = ftype;
        _mint(msg.sender, postId);
        _setTokenURI(postId, tokenURI);
        return (postId);
    }

    function updatePost(
        uint256 _postId,
        uint256 price,
        string memory tokenURI
    ) external newOwner(_postId) {
        Post storage post = idToPost[_postId];
        post.price = price;
        _setTokenURI(_postId, tokenURI);
    }

    function updateOwner(address _newOwner) external onlyOwner {
        emit Owner(address(this), owner, owner = _newOwner);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NA");

        Post memory cache = idToPost[tokenId];

        (bool royalityStatus, uint256 royality) = IMintsLab(mintslabFactory).checkRoyality(uint256(cache.ftype));

        if (royalityStatus) {
            (address wallet, address dev, uint256 govShare) = IMintsLab(mintslabFactory).governanceDetails();
            _payRoyality(wallet, dev, royality, govShare);
        }

        safeTransferFrom(from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NA");

        (bool royalityStatus, uint256 royality) = IMintsLab(mintslabFactory).checkRoyality(
            uint256(idToPost[tokenId].ftype)
        );

        if (royalityStatus) {
            (address wallet, address dev, uint256 govShare) = IMintsLab(mintslabFactory).governanceDetails();
            _payRoyality(wallet, dev, royality, govShare);
        }

        safeTransferFrom(from, to, tokenId);
    }

    function _payRoyality(
        address wallet,
        address dev,
        uint256 _royalityFee,
        uint256 govShare
    ) internal {
        uint256 share = (govShare / _royalityFee) * 100;

        (bool success1, ) = payable(wallet).call{ value: share }("");

        require(success1);

        share = 100 - govShare;

        share = (share / _royalityFee) * 100;

        (success1, ) = payable(dev).call{ value: share }("");

        require(success1);
    }
}
