//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SqwidMarketplaceV2.sol";

contract InkSacs is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _waveIds;
    Counters.Counter private _tokenIds;

    SqwidMarketplaceV2 private _sqwidMarketplaceV2;

    address private SQWID_ERC1155;
    address payable private royaltyFeeRecipient;

    struct Wave {
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 totalPoints;
        uint256 collateral;
        uint256 [] tokenPoints;
        uint256 [] tokenIds;
        string [] tokenURIs;
        bool distributed;
    }

    struct Token {
        uint256 tokenType;
        uint256 waveId;
        uint256 nftTokenId;
        bool claimed;
        bool redeemed;
        bool exists;
    }

    uint256 public buybackFund;

    mapping (uint256 => Token) idToToken;

    mapping (uint256 => Wave) idToWave;
    // wave -> user address -> token
    mapping (uint256 => mapping (address => Token)) userToTokenToClaim;

    event WaveStarted (uint256 indexed id, uint256 indexed start, uint256 indexed end);

    event WaveEnded (uint256 indexed id, uint256 indexed start, uint256 indexed end, uint256 collateral);

    function setRoyaltyFeeRecipient (address payable _royaltyFeeRecipient) external onlyOwner {
        royaltyFeeRecipient = _royaltyFeeRecipient;
    }

    function getRoyaltyFeeRecipient () external view returns (address) {
        return royaltyFeeRecipient;
    }

    function setSqwidERC1155 (address _sqwidERC1155) external onlyOwner {
        SQWID_ERC1155 = _sqwidERC1155;
    }

    function getSqwidERC1155 () external view returns (address) {
        return SQWID_ERC1155;
    }

    function createWave (address [] memory _receivers, uint256 [] memory _tokenTypes, string [] memory _tokenMetaURIs, uint256 [] memory _tokenTypesPoints, uint256 [] memory _tokenSupplies) public onlyOwner {
        if (_waveIds.current () > 0) {
            idToWave [_waveIds.current ()].end = block.timestamp;
            emit WaveEnded (_waveIds.current (), idToWave [_waveIds.current ()].start, idToWave [_waveIds.current ()].end, idToWave [_waveIds.current ()].collateral);
        }

        _waveIds.increment ();
        uint256 id = _waveIds.current ();
        uint256 start = block.timestamp;

        uint256 [] memory tokenIdsByType;

        for (uint16 i = 0; i < _tokenSupplies.length; i++) {
            uint256 tokenId = _sqwidMarketplaceV2.mint (address (this), _tokenSupplies [i], _tokenMetaURIs [i], royaltyFeeRecipient, 250, SQWID_ERC1155);
            tokenIdsByType [i] = tokenId;
        }

        idToWave[id] = Wave (id, start, start, 0, 0, _tokenTypesPoints, tokenIdsByType, _tokenMetaURIs, false);

        _distributeClaimable (_receivers, _tokenTypes);

        emit WaveStarted (id, start, start);
    }

    function _distributeClaimable (address [] memory _receivers, uint256 [] memory _tokenTypes) internal {
        uint256 id = _waveIds.current ();
        require (idToWave [id].distributed == false, "Ink Sacs already distributed for this wave");
        idToWave [id].distributed = true;
        for (uint256 i = 0; i < _receivers.length; i++) {
            _tokenIds.increment ();
            uint256 tokenId = _tokenIds.current ();
            address receiver = _receivers [i];
            uint256 tokenType = _tokenTypes [i];
            idToWave [id].totalPoints += _pointsByTokenId (tokenType, id);
            userToTokenToClaim [id] [receiver] = Token (tokenType, id, idToWave [id].tokenIds [tokenType], false, false, true);
            idToToken [tokenId] = userToTokenToClaim [id] [receiver];
        }
    }

    function _pointsByTokenId (uint256 _tokenId, uint256 _waveId) internal view returns (uint256) {
        return idToWave [_waveId].tokenPoints [_tokenId];
    }

    function _calculateTokenValue (uint256 _tokenId, uint256 _waveId) internal view returns (uint256) {
        uint256 _points = _pointsByTokenId (_tokenId, _waveId);
        uint256 _totalPoints = idToWave [_waveId].totalPoints;
        uint256 _collateral = idToWave [_waveId].collateral;
        uint256 _tokenValue = _collateral * _points / _totalPoints;
        return _tokenValue;
    }

    function _calculateTokenValueWithFee (uint256 _tokenId, uint256 amount, uint256 _waveId) internal view returns (uint256, uint256) {
        uint256 _tokenValue = amount * _calculateTokenValue (_tokenId, _waveId);
        uint256 _fee = _tokenValue * 250 / 10000;
        return (_tokenValue, _fee);
    }

    function _getTokenURI (uint256 _tokenType, uint256 _waveId) internal view returns (string memory _uri) {
        return idToWave [_waveId].tokenURIs [_tokenType];
    }

    function claimToken (uint256 _waveId) public nonReentrant {
        require (idToWave [_waveId].distributed == true, "Ink Sacs not distributed for this wave");
        require (userToTokenToClaim [_waveId] [msg.sender].claimed == false, "Token already claimed");
        require (userToTokenToClaim [_waveId] [msg.sender].exists == true, "Token does not exist");
        userToTokenToClaim [_waveId] [msg.sender].claimed = true;
        // transfer token to user
        uint256 _tokenId = userToTokenToClaim [_waveId] [msg.sender].nftTokenId;
        ISqwidERC1155 (SQWID_ERC1155).safeTransferFrom (address (this), msg.sender, _tokenId, 1, bytes ('0'));
    }

    function redeemToken (uint256 nftTokenId, uint256 amount) public nonReentrant {
        uint256 tokensCount = _tokenIds.current ();
        for (uint256 i = 1; i <= tokensCount; i++) {
            if (idToToken [i].nftTokenId == nftTokenId) {
                require (idToToken [i].redeemed == false, "Token already redeemed");
                require (idToToken [i].claimed == true, "Token not claimed");
                idToToken [i].redeemed = true;
                uint256 bal = ISqwidERC1155 (SQWID_ERC1155).balanceOf (msg.sender, nftTokenId);
                require (bal >= amount, "Amount larger than user balance");
                ISqwidERC1155 (SQWID_ERC1155).burn (msg.sender, nftTokenId, amount);
                (uint256 _tokenValue, uint256 _fee) = _calculateTokenValueWithFee (idToToken [i].tokenType, amount, idToToken [i].waveId);
                _tokenValue = _tokenValue - _fee;
                buybackFund += _fee;
                payable (msg.sender).transfer (_tokenValue);
                return;
            }
        }
    }

    function tokenValue (uint256 _tokenId, uint256 _waveId) public view returns (uint256) {
        return _calculateTokenValue (_tokenId, _waveId);
    }

    function addCollateral () public payable {
        require (msg.value > 0, "Collateral added must be greater than 0");
        uint256 id = _waveIds.current ();
        idToWave [id].collateral += msg.value;
    }

    function getBuybackFund () public view returns (uint256) {
        return buybackFund;
    }

    function addToBuybackFund () public payable {
        require (msg.value > 0, "Collateral added must be greater than 0");
        buybackFund += msg.value;
    }

    function removeFromBuybackFund (uint256 value) public onlyOwner {
        require (buybackFund >= value, "Buyback fund must be greater than or equal to value");
        buybackFund -= value;
        payable (msg.sender).transfer (value);
    }

    // check this again later
    function buyBack (uint256 nftTokenId, uint256 amount) public {
        uint256 tokensCount = _tokenIds.current ();
        for (uint256 i = 1; i <= tokensCount; i++) {
            if (idToToken [i].nftTokenId == nftTokenId) {
                require (idToToken [i].redeemed == false, "Token already redeemed");
                require (idToToken [i].claimed == true, "Token not claimed");
                uint256 bal = ISqwidERC1155 (SQWID_ERC1155).balanceOf (msg.sender, nftTokenId);
                require (bal >= amount, "Amount larger than user balance");
                ISqwidERC1155 (SQWID_ERC1155).safeTransferFrom (msg.sender, address (this), nftTokenId, amount, bytes ('0'));
                (uint256 _tokenValue, uint256 _fee) = _calculateTokenValueWithFee (idToToken [i].tokenType, amount, idToToken [i].waveId);
                _tokenValue = _tokenValue - _fee;
                require (buybackFund >= _tokenValue, "Buyback fund not enough");
                buybackFund -= _tokenValue;
                payable (msg.sender).transfer (_tokenValue);
                return;
            }
        }
    }

    function fetchWave (uint256 id) external view returns (Wave memory wave) {
        return idToWave[id];
    }

    function currentWave () external view returns (uint256) {
        return _waveIds.current ();
    }
}