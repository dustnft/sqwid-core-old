//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title Sqwid NFT (ERC1155 With Royalties)
/// @author @andithemudkip @boidushya
interface ISqwidERC1155 is IERC1155 {
    function getTokensByOwner (address owner) external view returns (uint256[] memory);

    function getTokenSupply (uint256 _id) external view returns (uint256);

    function currentId () external view returns (uint256);

    function uri (uint256 _id) external view returns (string memory);

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function mint (
        address to,
        uint256 amount,
        string memory tokenURI,
        address royaltyRecipient,
        uint256 royaltyValue
    ) external returns (uint256);
}