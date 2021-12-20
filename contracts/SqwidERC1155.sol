//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./sERC1155.sol";
import './ERC2981PerTokenRoyalties.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/// @title Sqwid NFT (ERC1155 With Royalties)
/// @author @andithemudkip @boidushya
contract SqwidERC1155 is sERC1155, ERC2981PerTokenRoyalties, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => string) public _tokenURIs;

    constructor () sERC1155("ipfs://") {
        // setApprovalForAll (marketplaceAddress, true);
    }

    function setMarketplaceAddress (address marketplaceAddress) public onlyOwner {
        setApprovalForAll (marketplaceAddress, true);
    }

    function _baseURI () internal view virtual returns (string memory) {
        return "ipfs://";
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (sERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mint amount token of type `id` to `to`
    /// @param to the recipient of the token
    /// @param amount amount of the token type to mint
    /// @param tokenURI the URI of the token's metadata
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    function mint (
        address to,
        uint256 amount,
        string memory tokenURI,
        address royaltyRecipient,
        uint256 royaltyValue
    ) external returns (uint256) {
        _tokenIds.increment ();
        uint256 id = _tokenIds.current ();
        _mint (to, id, amount, '');

        if (royaltyValue > 0) {
            _setTokenRoyalty (id, royaltyRecipient, royaltyValue);
        }

        _setTokenURI (id, tokenURI);
        return id;
    }


    /// @notice Mint several tokens at once
    /// @param to the recipient of the tokens
    /// @param amounts array of amount to mint for each token type
    /// @param royaltyRecipients an array of recipients for royalties (if royaltyValues[i] > 0)
    /// @param royaltyValues an array of royalties asked for (EIP2981)
    function mintBatch(
        address to,
        uint256[] memory amounts,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues
    ) external {
        require(
            amounts.length == royaltyRecipients.length &&
                amounts.length == royaltyValues.length,
            'ERC1155: Arrays length mismatch'
        );

        uint256[] memory ids = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            _tokenIds.increment ();
            ids[i] = _tokenIds.current ();
        }

        _mintBatch(to, ids, amounts, '');

        for (uint256 i; i < ids.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    ids[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
        }
    }

    function burn (
        address account,
        uint256 id,
        uint256 value
    ) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function getTokensByOwner (address owner) public view returns (uint256[] memory) {
        uint256 [] memory tokens = new uint256 [] (_tokenIds.current () + 1);
        for (uint256 i = 1; i <= _tokenIds.current (); i++) {
            uint256 balance = balanceOf (owner, i);
            if (balance > 0) {
                tokens [i] = balance;
            }
        }
        return tokens;
    }

    function getTokenSupply (uint256 _id) public view returns (uint256) {
        uint256 tokenSupply = 0;
        for (uint256 i = 0; i < getOwners (_id).length; i++) {
            if (getOwners (_id)[i] != address (0)) {
                tokenSupply += balanceOf (getOwners (_id)[i], _id);
            }
        }
        return tokenSupply;
    }

    function currentId () external view returns (uint256) {
        return _tokenIds.current ();
    }

    function _setTokenURI (uint256 id, string memory tokenURI) internal {
        _tokenURIs [id] = tokenURI;
    }

    function uri (uint256 _id) public view virtual override returns (string memory) {
        require(_exists (_id), "ERC1155Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI ();
        return bytes (baseURI).length > 0 ? string (abi.encodePacked (baseURI, _tokenURIs [_id])) : "";
    }

    function _exists (uint256 _id) internal view returns (bool) {
        return bytes (_tokenURIs [_id]).length > 0;
    }
}