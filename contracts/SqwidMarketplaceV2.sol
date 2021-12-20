//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISqwidERC1155.sol";
import "./SqwidERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "hardhat/console.sol";

contract SqwidMarketplaceV2 is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;

    bytes4 private constant _ROYALTY_INTERFACE = bytes4 (keccak256 ('royaltyInfo(uint256,uint256)'));
    
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

    address payable platformFeeRecipient;

    uint16 public platformFee = 250;

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

    constructor () {
        platformFeeRecipient = payable (msg.sender);
    }
    
    mapping (uint256 => mapping (uint256 => Bid)) private idToBid;
    // itemToBidCounter [itemId] -> Counter
    mapping (uint256 => Counters.Counter) private itemToBidCounter;

    mapping (uint256 => MarketItem) private idToMarketItem;

    modifier onlySeller (uint256 itemId) {
        require (idToMarketItem [itemId].seller == msg.sender, "Only the seller can do this");
        _;
    }

    modifier tokensAvailable (uint256 itemId) {
        require (tokenBalanceByItemId (itemId) > 0, "Tokens are not available");
        _;
    }

    function setPlatformFeeRecipient (address payable _platformFeeRecipient) external onlyOwner {
        platformFeeRecipient = _platformFeeRecipient;
    }

    function setPlatformFeePercent (uint16 _platformFee) external onlyOwner {
        require (_platformFee <= 500 && _platformFee >= 0, "Platform fee must be between 0% and 5%");
        platformFee = _platformFee;
    }

    function getPlatformFeePercent () external view returns (uint16) {
        return platformFee;
    }

    function mint (
        address to,
        uint256 amount,
        string memory tokenURI,
        address royaltyRecipient,
        uint256 royaltyValue,
        address nftContract
    ) external returns (uint256) {
        require (amount > 0, "Amount must be greater than 0");
        require (to != address(0), "To address cannot be the zero address");
        require (royaltyRecipient != address(0), "Royalty recipient cannot be the zero address");

        uint256 tokenId = ISqwidERC1155 (nftContract).mint (to, amount, tokenURI, royaltyRecipient, royaltyValue);
        
        createMarketItem (nftContract, tokenId);

        return tokenId;
    }

    function currentId () external view returns (uint256) {
        return _itemIds.current ();
    }

    function createMarketItemFor (
        address owner,
        address nftContract,
        uint256 tokenId
    ) internal {
        require (ISqwidERC1155 (nftContract).balanceOf (owner, tokenId) >= 0, "Not enough tokens");

        uint256 count = _itemIds.current ();
        for (uint256 i = 1; i <= count; i++) {
            if (idToMarketItem [i].tokenId == tokenId
                && idToMarketItem [i].nftContract == nftContract
                && idToMarketItem [i].seller == owner
            ) {
                return;
            }
        }

        _itemIds.increment ();
        uint256 itemId = _itemIds.current ();

        
        (address royaltyReceiver, uint256 royaltyAmount) = ISqwidERC1155 (nftContract).royaltyInfo (tokenId, 0);

        idToMarketItem [itemId] = MarketItem (
            itemId,
            nftContract,
            tokenId,
            payable (owner),
            payable (royaltyReceiver),
            royaltyAmount,
            0,
            false
        );

        emit ItemCreated (itemId, nftContract, tokenId, owner, royaltyReceiver, royaltyAmount);
    }

    function createMarketItem (
        address nftContract,
        uint256 tokenId
    ) public nonReentrant {
        require (ISqwidERC1155 (nftContract).balanceOf (msg.sender, tokenId) >= 0, "Not enough tokens");

        uint256 count = _itemIds.current ();
        for (uint256 i = 1; i <= count; i++) {
            if (idToMarketItem [i].tokenId == tokenId
                && idToMarketItem [i].nftContract == nftContract
                && idToMarketItem [i].seller == msg.sender
            ) {
                return;
            }
        }

        _itemIds.increment ();
        uint256 itemId = _itemIds.current ();
        
        (address royaltyReceiver, uint256 royaltyAmount) = ISqwidERC1155 (nftContract).royaltyInfo (tokenId, 0);

        idToMarketItem [itemId] = MarketItem (
            itemId,
            nftContract,
            tokenId,
            payable (msg.sender),
            payable (royaltyReceiver),
            royaltyAmount,
            0,
            false
        );

        emit ItemCreated (itemId, nftContract, tokenId, msg.sender, royaltyReceiver, royaltyAmount);
    }

    function putOnSale (uint256 itemId, uint256 price) public nonReentrant onlySeller (itemId) tokensAvailable (itemId) {
        require (price > 0, "Price must be at least 1 wei");
        require (ERC165 (idToMarketItem [itemId].nftContract).supportsInterface (_ROYALTY_INTERFACE), "NFT contract does not support the Royalty Interface");
        (, uint256 royaltyAmount) = ISqwidERC1155 (idToMarketItem [itemId].nftContract).royaltyInfo (idToMarketItem [itemId].tokenId, price);
        idToMarketItem [itemId].price = price;
        idToMarketItem [itemId].royaltyAmount = royaltyAmount;
        idToMarketItem [itemId].onSale = true;
    }

    function removeFromSale (uint256 itemId) public nonReentrant onlySeller (itemId) {
        require (idToMarketItem [itemId].onSale == true, "Item is not on sale");
        idToMarketItem [itemId].onSale = false;
    }

    /* Buy {amount} of {itemId} at asking price */
    function buyNow (
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant {
        require (idToMarketItem [itemId].onSale == true, "Item is not on sale");
        require (amount > 0, "Amount must be at least 1");
        uint256 price = idToMarketItem [itemId].price;
        uint256 tokenId = idToMarketItem [itemId].tokenId;
        uint256 availableBalance = tokenBalanceByItemId (itemId);
        require (availableBalance >= amount, "Not enough tokens");

        require (msg.value >= amount * price, "Not enough ETH");

        uint256 royaltyAmount = idToMarketItem [itemId].royaltyAmount * amount;

        uint256 platformFeeAmount = amount * price * platformFee / 10000;

        uint256 sellerValue = msg.value - royaltyAmount - platformFeeAmount;

        payable (idToMarketItem [itemId].seller).transfer (sellerValue);
        payable (idToMarketItem [itemId].royaltyReceiver).transfer (royaltyAmount);
        payable (platformFeeRecipient).transfer (platformFeeAmount);
        ISqwidERC1155 (idToMarketItem [itemId].nftContract).safeTransferFrom (idToMarketItem [itemId].seller, msg.sender, tokenId, amount, bytes ('0'));
    
        createMarketItemFor (msg.sender, idToMarketItem [itemId].nftContract, tokenId);
        
        emit ItemSold (itemId, idToMarketItem [itemId].nftContract, tokenId, idToMarketItem [itemId].seller, msg.sender, amount, price);
    }

    function addBid (
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant tokensAvailable (itemId) {
        require (amount > 0, "Amount must be at least 1");
        require (msg.value >= 1, "Price must be at least 1 gwei");
        require (ERC165 (idToMarketItem [itemId].nftContract).supportsInterface (_ROYALTY_INTERFACE), "NFT contract does not support the Royalty Interface");

        itemToBidCounter [itemId].increment ();

        uint256 bidId = itemToBidCounter [itemId].current ();
        uint256 price = msg.value / amount;

        idToBid [itemId] [bidId] = Bid (
            bidId,
            itemId,
            payable (msg.sender),
            amount,
            price,
            true
        );

        emit BidAdded (itemId, bidId, msg.sender, amount, price);
    }
    
    function cancelBid (
        uint256 itemId,
        uint256 bidId
    ) public nonReentrant {
        require (idToBid [itemId] [bidId].bidder == msg.sender, "Only the bidder can cancel the bid");
        require (idToBid [itemId] [bidId].active == true, "Bid is not active");
        idToBid [itemId] [bidId].active = false;
        uint256 price = idToBid [itemId] [bidId].price;
        uint256 amount = idToBid [itemId] [bidId].amount;
        payable (msg.sender).transfer (price * amount);
    }

    // accept bid
    function acceptBid (
        uint256 itemId,
        uint256 bidId
    ) public nonReentrant {
        require (msg.sender == idToMarketItem [itemId].seller, "Only the seller can accept the bid");
        MarketItem storage item = idToMarketItem [itemId];
        require (idToBid [itemId] [bidId].active == true, "Bid is not active");
        require (tokenBalanceByItemId (itemId) >= idToBid [itemId] [bidId].amount, "Not enough tokens");
        idToBid [itemId] [bidId].active = false;
        uint256 bidValue = idToBid [itemId] [bidId].price * idToBid [itemId] [bidId].amount;

        (address royaltyReceiver, uint256 royaltyAmount) = ISqwidERC1155 (item.nftContract).royaltyInfo (item.tokenId, bidValue);

        uint256 platformFeeAmount = bidValue * platformFee / 10000;

        payable (idToMarketItem [itemId].seller).transfer (bidValue - royaltyAmount - platformFeeAmount);
        payable (royaltyReceiver).transfer (royaltyAmount);
        payable (platformFeeRecipient).transfer (platformFeeAmount);
        ISqwidERC1155 (item.nftContract)
            .safeTransferFrom (item.seller, idToBid [itemId] [bidId].bidder, item.tokenId, idToBid [itemId] [bidId].amount, bytes ('0'));
    
        createMarketItemFor (idToBid [itemId] [bidId].bidder, idToMarketItem [itemId].nftContract, idToMarketItem [itemId].tokenId);
        
        emit ItemSold (
            itemId,
            item.nftContract,
            item.tokenId,
            item.seller,
            idToBid [itemId] [bidId].bidder,
            idToBid [itemId] [bidId].amount,
            idToBid [itemId] [bidId].price
        );
    }

    function tokenBalanceByItemId (uint256 itemId) public view returns (uint256) {
        return ISqwidERC1155 (idToMarketItem [itemId].nftContract).balanceOf (idToMarketItem [itemId].seller, idToMarketItem [itemId].tokenId);
    }

    function fetchBid (
        uint256 itemId,
        uint256 bidId
    ) public view returns (Bid memory) {
        return idToBid [itemId] [bidId];
    }

    // returns all active bids for a given item
    function fetchBids (uint256 itemId) external view returns (Bid [] memory bids) {
        uint256 bidCount = itemToBidCounter [itemId].current ();
        Bid [] memory bidsArray = new Bid [] (bidCount);
        uint currentIndex = 0;
        for (uint256 i = 0; i < bidCount; i++) {
            bidsArray [currentIndex] = idToBid [itemId] [i + 1];
            currentIndex++;
        }
        return bidsArray;
    }

    function fetchBidCount (uint256 itemId) external view returns (uint256) {
        return itemToBidCounter [itemId].current ();
    }

    // Returns the highest bid id and the price of the bid
    function fetchHighestBid (uint256 itemId) external view returns (Bid memory) {
        uint256 bidCount = itemToBidCounter [itemId].current ();
        uint256 highestBidId = 0;
        uint256 highestBidPrice = 0;
        for (uint256 i = 0; i < bidCount; i++) {
            if (idToBid [itemId] [i + 1].active == true) {
                if (idToBid [itemId] [i + 1].price > highestBidPrice) {
                    highestBidId = i + 1;
                    highestBidPrice = idToBid [itemId] [i + 1].price;
                }
            }
        }
        return idToBid [itemId] [highestBidId];
    }

    function fetchMarketItem (uint256 itemId) external view returns (MarketItem memory) {
        return idToMarketItem [itemId];
    }

    /* Returns all active market items */
    function fetchMarketItems () external view returns (MarketItem [] memory) {
        uint itemCount = _itemIds.current ();
        uint currentIndex = 0;

        MarketItem [] memory _items = new MarketItem [] (itemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (tokenBalanceByItemId (i + 1) > 0) {
                MarketItem storage currentItem = idToMarketItem [i + 1];
                _items [currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return _items;
    }

    function fetchMarketItemsByTokenId (address nftContract, uint256 tokenId) external view returns (MarketItem [] memory) {
        uint itemCount = _itemIds.current ();
        uint currentIndex = 0;

        MarketItem [] memory _items = new MarketItem [] (itemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (
                tokenBalanceByItemId (i + 1) > 0 &&
                idToMarketItem [i + 1].nftContract == nftContract &&
                idToMarketItem [i + 1].tokenId == tokenId
            ) {
                uint _currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem [_currentId];
                _items [currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return _items;
    }

    /* Returns the specified seller's active market items */
    function fetchMarketItemsFromSeller (address seller) external view returns (MarketItem [] memory) {
        uint itemCount = _itemIds.current ();
        uint currentIndex = 0;

        MarketItem [] memory _items = new MarketItem [] (itemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem [i + 1].seller == seller && tokenBalanceByItemId (i + 1) > 0) {
                uint _currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem [_currentId];
                _items [currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return _items;
    }
}