// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "./ISqwidERC1155.sol";

// import "hardhat/console.sol";

// contract SqwidMarketplace is ReentrancyGuard {
//   using Counters for Counters.Counter;
//   Counters.Counter private _itemIds;
//   Counters.Counter private _itemsSold;

//   address payable owner;

//   uint8 public platformFee = 250;

//   constructor () {
//     owner = payable (msg.sender);
//   }

//   struct MarketItem {
//     uint itemId;
//     address nftContract;
//     uint256 tokenId;
//     address payable seller;
//     address payable royaltyReceiver;
//     uint256 royaltyAmount;
//     uint256 price;
//     bool active;
//   }

//   mapping (uint256 => MarketItem) private idToMarketItem;

//   event MarketItemCreated (
//     uint indexed itemId,
//     address indexed nftContract,
//     uint256 indexed tokenId,
//     address seller,
//     address royaltyReceiver,
//     uint256 royaltyAmount,
//     uint256 price,
//     bool active
//   );

//   /* Places an item for sale on the marketplace */
//   function createMarketItem(
//     address nftContract,
//     uint256 tokenId,
//     uint256 price
//   ) public payable nonReentrant {
//     require (price > 0, "Price must be at least 1 wei");
//     require (ISqwidERC1155 (nftContract).balanceOf (msg.sender, tokenId) >= 0, "Not enough tokens");

//     _itemIds.increment ();
//     uint256 itemId = _itemIds.current ();

//     (address royaltyReceiver, uint256 royaltyAmount) = ISqwidERC1155 (nftContract).royaltyInfo (tokenId, price);

//     idToMarketItem[itemId] =  MarketItem(
//       itemId,
//       nftContract,
//       tokenId,
//       payable(msg.sender),
//       payable(royaltyReceiver),
//       royaltyAmount,
//       price,
//       true
//     );

//     // ISqwidERC1155 (nftContract).safeTransferFrom (msg.sender, address(this), tokenId, balance, bytes ('0'));

//     emit MarketItemCreated(
//       itemId,
//       nftContract,
//       tokenId,
//       msg.sender,
//       royaltyReceiver,
//       royaltyAmount,
//       price,
//       true
//     );
//   }

//   function deactivateMarketItem(uint256 itemId) public nonReentrant {
//     require (idToMarketItem[itemId].active, "Item is not active");
//     require (msg.sender == idToMarketItem[itemId].seller, "Only the seller can deactivate an item");
//     idToMarketItem [itemId].active = false;
//   }

//   /* Creates the sale of a marketplace item */
//   /* Transfers ownership of the item, as well as funds between parties */
//   function createMarketSale (
//     address nftContract,
//     uint256 itemId,
//     uint256 amount
//     ) public payable nonReentrant {
//     require (idToMarketItem [itemId].active, "Item is not active");
//     uint256 price = idToMarketItem[itemId].price;
//     uint256 tokenId = idToMarketItem[itemId].tokenId;
//     require (msg.value == price, "Please submit the asking price in order to complete the purchase");
//     require (amount > 0, "Amount must be at least 1");
//     uint256 availableBalance = ISqwidERC1155 (nftContract).balanceOf (idToMarketItem[itemId].seller, tokenId);
//     if (availableBalance == 0) {
//         idToMarketItem[itemId].active = false;
//         require (false, "The seller doesn't have tokens");
//     }
//     require (amount <= availableBalance, "Not enough tokens");

//     uint256 value = amount * price;
//     require (msg.value >= value, "Not enough ETH");

//     uint256 royaltyAmountPercent = idToMarketItem[itemId].royaltyAmount;

//     uint256 royaltyAmount = value * royaltyAmountPercent / 10000;
//     uint256 platformFeeAmount = value * platformFee / 10000;

//     uint256 sellerValue = msg.value - royaltyAmount - platformFeeAmount;

//     idToMarketItem [itemId].seller.transfer (sellerValue);
//     idToMarketItem [itemId].royaltyReceiver.transfer (royaltyAmount);
//     payable (owner).transfer (platformFeeAmount);
//     ISqwidERC1155 (nftContract).safeTransferFrom (idToMarketItem [itemId].seller, msg.sender, tokenId, amount, bytes ('0'));

//     if (availableBalance - amount == 0) {
//         _itemsSold.increment();
//         idToMarketItem[itemId].active = false;
//     }
//   }

//   /* Returns all unsold market items */
//   function fetchMarketItems() public view returns (MarketItem[] memory) {
//     uint itemCount = _itemIds.current();
//     uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
//     uint currentIndex = 0;

//     MarketItem[] memory items = new MarketItem[](unsoldItemCount);
//     for (uint i = 0; i < itemCount; i++) {
//       if (idToMarketItem[i + 1].owner == address(0)) {
//         uint currentId = i + 1;
//         MarketItem storage currentItem = idToMarketItem[currentId];
//         items[currentIndex] = currentItem;
//         currentIndex += 1;
//       }
//     }
//     return items;
//   }

//   /* Returns only items that a user has purchased */
//   function fetchMyNFTs() public view returns (MarketItem[] memory) {
//     uint totalItemCount = _itemIds.current();
//     uint itemCount = 0;
//     uint currentIndex = 0;

//     for (uint i = 0; i < totalItemCount; i++) {
//       if (idToMarketItem[i + 1].owner == msg.sender) {
//         itemCount += 1;
//       }
//     }

//     MarketItem[] memory items = new MarketItem[](itemCount);
//     for (uint i = 0; i < totalItemCount; i++) {
//       if (idToMarketItem[i + 1].owner == msg.sender) {
//         uint currentId = i + 1;
//         MarketItem storage currentItem = idToMarketItem[currentId];
//         items[currentIndex] = currentItem;
//         currentIndex += 1;
//       }
//     }
//     return items;
//   }

//   /* Returns only items a user has created */
//   function fetchItemsCreated() public view returns (MarketItem[] memory) {
//     uint totalItemCount = _itemIds.current();
//     uint itemCount = 0;
//     uint currentIndex = 0;

//     for (uint i = 0; i < totalItemCount; i++) {
//       if (idToMarketItem[i + 1].seller == msg.sender) {
//         itemCount += 1;
//       }
//     }

//     MarketItem[] memory items = new MarketItem[](itemCount);
//     for (uint i = 0; i < totalItemCount; i++) {
//       if (idToMarketItem[i + 1].seller == msg.sender) {
//         uint currentId = i + 1;
//         MarketItem storage currentItem = idToMarketItem[currentId];
//         items[currentIndex] = currentItem;
//         currentIndex += 1;
//       }
//     }
//     return items;
//   }
// }