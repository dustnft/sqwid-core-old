//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISqwidERC1155.sol";
import "./ISqwidMarketplace.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SqwidMarketUtility is Ownable {
    struct MarketItemReturn {
        uint256 itemId;
        bool isOnSale;
        uint256 price;
        address currentOwner;
        uint256 currentOwnerBalance;
        uint256 totalSupply;
        uint256 highestBid;
        uint256 royalty;
        uint256 tokenId;
        string uri;
    }

    address private _marketplace;
    address private _erc1155;

    ISqwidMarketplace marketplace;
    ISqwidERC1155 erc1155;

    function setMarketplace(address marketplaceAddress) public onlyOwner {
        _marketplace = marketplaceAddress;
        marketplace = ISqwidMarketplace (marketplaceAddress);
    }

    function setERC1155(address erc1155Address) public onlyOwner {
        _erc1155 = erc1155Address;
        erc1155 = ISqwidERC1155 (erc1155Address);
    }

    function getMarketplaceAddress () public view returns (address) {
        return _marketplace;
    }

    function getERC1155Address () public view returns (address) {
        return _erc1155;
    }

    function fetchMarketItem (uint256 itemId) public view returns (MarketItemReturn memory) {
        ISqwidMarketplace.MarketItem memory item = marketplace.fetchMarketItem (itemId);

        uint256 sellerBalance = item.seller != address (0) ? erc1155.balanceOf (item.seller, item.tokenId) : 0;
        uint256 highestBid = marketplace.fetchHighestBid (itemId).price;
        (, uint256 royalty) = erc1155.royaltyInfo (item.tokenId, 10000);
        uint256 totalSupply = erc1155.getTokenSupply (item.tokenId);

        return MarketItemReturn (
            itemId,
            item.onSale,
            item.price,
            item.seller,
            sellerBalance,
            totalSupply,
            highestBid,
            royalty,
            item.tokenId,
            erc1155.uri (item.tokenId)
        );
    }

    function fetchMarketItems () public view returns (MarketItemReturn [] memory) {
        uint256 itemCount = marketplace.currentId ();
        MarketItemReturn [] memory marketItems = new MarketItemReturn [] (itemCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            MarketItemReturn memory item = fetchMarketItem (i);
            if (item.currentOwnerBalance > 0) {
                marketItems[index] = item;
                index++;
            }
        }
        return marketItems;
    }

    function fetchMarketItemsByOwner (address owner) public view returns (MarketItemReturn [] memory) {
        uint256 itemCount = marketplace.currentId ();
        MarketItemReturn [] memory marketItems = new MarketItemReturn [] (itemCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            MarketItemReturn memory item = fetchMarketItem (i);
            if (item.currentOwner == owner && item.currentOwnerBalance > 0) {
                marketItems[index] = item;
                index++;
            }
        }
        return marketItems;
    }
}