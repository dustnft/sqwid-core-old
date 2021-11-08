//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISqwidERC1155.sol";

import "hardhat/console.sol";

interface ISqwidMarketplace {
    event ItemCreated (
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address royaltyRecipient,
        uint256 royaltyAmount    
    );

    event ItemSold (
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 amount,
        uint256 price
    );

    event BidAdded (
        uint256 indexed itemId,
        uint256 indexed bidId,
        address bidder,
        uint256 amount,
        uint256 price
    );

    struct Bid {
        uint256 bidId;
        uint256 itemId;
        address payable bidder;
        uint256 amount;
        uint256 price;
        bool active;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable royaltyReceiver;
        uint256 royaltyAmount;
        uint256 price;
        bool onSale;
    }

    function getPlatformFeePercent () external view returns (uint16);

    function tokenBalanceByItemId (uint256 itemId) external view returns (uint256);

    function fetchBid (
        uint256 itemId,
        uint256 bidId
    ) external view returns (Bid memory);

    function currentId () external view returns (uint256);
    // returns all active bids for a given item
    function fetchBids (uint256 itemId) external view returns (Bid [] memory bids);

    function fetchBidCount (uint256 itemId) external view returns (uint256);

    // Returns the highest bid id and the price of the bid
    function fetchHighestBid (uint256 itemId) external view returns (Bid memory);

    function fetchMarketItem (uint256 itemId) external view returns (MarketItem memory);

    /* Returns all active market items */
    function fetchMarketItems () external view returns (MarketItem [] memory);

    function fetchMarketItemsByTokenId (address nftContract, uint256 tokenId) external view returns (MarketItem [] memory);

    /* Returns the specified seller's active market items */
    function fetchMarketItemsFromSeller (address seller) external view returns (MarketItem [] memory);
}