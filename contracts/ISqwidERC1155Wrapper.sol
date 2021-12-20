//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISqwidWrapper {
    struct WrappedToken {
        uint256 id; // wrapped id
        uint256 eip; // 0 - ERC721, 1 - ERC1155
        uint256 originalTokenId; // original token id
        address nftContract; // the original contract address
        uint256 tokenId; // the SqwidERC1155 token id
        bool unwrapped;
    }

    function getWrappedCount () external view returns (uint256);

    function getWrappedTokens () external view returns (WrappedToken [] memory);

    function getSqwidERC1155Address() external view returns (address);

    function wrapERC721 (address _nftContract, uint256 _tokenId) external returns (uint256);

    function unwrapERC721 (uint256 _wrappedId) external;

    function wrapERC1155 (address _nftContract, uint256 _tokenId) external returns (uint256);

    function unwrapERC1155 (uint256 _wrappedId) external;

    function getWrappedToken (uint256 _wrappedId) external view returns (WrappedToken memory);

    function approve (address _nftContract) external;
    
    function isApproved (address _nftContract) external view returns (bool);
}