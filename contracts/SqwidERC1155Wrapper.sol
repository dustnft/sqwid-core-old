//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISqwidERC1155.sol";
import "./SqwidMarketplaceV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SqwidWrapper is Ownable {
    SqwidMarketplaceV2 marketplace;
    using Counters for Counters.Counter;
    Counters.Counter private _wrappedIds;

    address private SqwidERC1155Address = address (0);

    struct WrappedToken {
        uint256 id; // wrapped id
        uint256 eip; // 0 - ERC721, 1 - ERC1155
        uint256 originalTokenId; // original token id
        address nftContract; // the original contract address
        uint256 tokenId; // the SqwidERC1155 token id
        bool unwrapped;
    }

    mapping (uint256 => WrappedToken) wrappedTokens;

    function setMarketplace (address marketplaceAddress) public onlyOwner {
        marketplace = SqwidMarketplaceV2 (marketplaceAddress);
    }

    function getWrappedCount () public view returns (uint256) {
        return _wrappedIds.current ();
    }

    function getWrappedTokens () public view returns (WrappedToken [] memory) {
        uint256 len = _wrappedIds.current ();
        WrappedToken [] memory tokens = new WrappedToken [] (len);
        for (uint256 i = 1; i <= len; i++) {
            tokens [i] = wrappedTokens [i];
        }
        return tokens;
    }

    function setSqwidERC1155Address (address _address) public onlyOwner {
        SqwidERC1155Address = _address;
    }

    function getSqwidERC1155Address() public view returns (address) {
        return SqwidERC1155Address;
    }

    function wrapERC721 (address _nftContract, uint256 _tokenId) public returns (uint256) {
        require (IERC721 (_nftContract).ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");
        
        _wrappedIds.increment ();
        uint256 wrappedId = _wrappedIds.current ();

        IERC721 (_nftContract).safeTransferFrom (msg.sender, address (this), _tokenId);
        string memory uri = IERC721Metadata (_nftContract).tokenURI (_tokenId);
        uint256 tokenId = marketplace.mint (msg.sender, 1, uri, msg.sender, 0, SqwidERC1155Address);

        wrappedTokens [wrappedId] = WrappedToken (wrappedId, 0, _tokenId, _nftContract, tokenId, false);
        return tokenId;
    }

    function unwrapERC721 (uint256 _wrappedId) public {
        WrappedToken memory wrappedToken = wrappedTokens [_wrappedId];
        require (wrappedToken.unwrapped == false, "This token has already been unwrapped");
        require (ISqwidERC1155 (SqwidERC1155Address).balanceOf (msg.sender, wrappedToken.tokenId) == 1, "You don't have tokens to unwrap");

        ISqwidERC1155 (SqwidERC1155Address).burn (msg.sender, wrappedToken.tokenId, 1);
        IERC721 (wrappedToken.nftContract).safeTransferFrom (address (this), msg.sender, wrappedToken.originalTokenId);
    }

    function wrapERC1155 (address _nftContract, uint256 _tokenId) public returns (uint256) {
        uint256 bal = ISqwidERC1155 (_nftContract).balanceOf (msg.sender, _tokenId);
        require (bal >= 1, "You don't have tokens to wrap");

        _wrappedIds.increment ();
        uint256 wrappedId = _wrappedIds.current ();

        IERC1155 (_nftContract).safeTransferFrom (msg.sender, address (this), _tokenId, bal, "");

        string memory uri = ISqwidERC1155 (_nftContract).uri (_tokenId);
        uint256 tokenId = marketplace.mint (msg.sender, bal, uri, msg.sender, 0, SqwidERC1155Address);

        wrappedTokens [wrappedId] = WrappedToken (wrappedId, 1, _tokenId, _nftContract, tokenId, false);
        return tokenId;
    }

    function unwrapERC1155 (uint256 _wrappedId) public {
        WrappedToken memory wrappedToken = wrappedTokens [_wrappedId];
        uint256 bal = ISqwidERC1155 (SqwidERC1155Address).balanceOf (msg.sender, wrappedToken.tokenId);
        require (wrappedToken.unwrapped == false, "This token has already been unwrapped");
        require (bal >= 1, "You don't have tokens to unwrap");
        
        ISqwidERC1155 (SqwidERC1155Address).burn (msg.sender, wrappedToken.tokenId, wrappedToken.tokenId);
        IERC1155 (wrappedToken.nftContract).safeTransferFrom (address (this), msg.sender, wrappedToken.originalTokenId, bal, "");
    }

    function getWrappedToken (uint256 _wrappedId) public view returns (WrappedToken memory) {
        return wrappedTokens [_wrappedId];
    }

    function approve (address _nftContract) public {
        IERC721 (_nftContract).setApprovalForAll (address (this), true);
        ISqwidERC1155 (SqwidERC1155Address).setApprovalForAll (address (this), true);
    }
    
    function isApproved (address _nftContract) public view returns (bool) {
        return IERC721 (_nftContract).isApprovedForAll (msg.sender, address (this)) && ISqwidERC1155 (SqwidERC1155Address).isApprovedForAll (msg.sender, address (this));
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) pure external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}