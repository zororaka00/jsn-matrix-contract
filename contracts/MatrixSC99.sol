pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/InterfaceMatrixSC99.sol";

contract MatrixSC99 is ReentrancyGuard, ERC721Enumerable, InterfaceMatrixSC99 {
    IERC20 private tokenBUSD;

    uint256 private constant valueUpline = 80e18;
    uint256 private constant shareValuePool = 10e18;
    address private constant addressPool = 0x75552A8202076e707F37cf6c5F0782BCA054a6F3;

    uint256[] private shareValueOwnerBUSD = [4e18, 2e18, 2e18];
    uint256[] private sharePercentage = [
        37500, // 37.5%
        18750, // 18.75%
        6250, // 6.25%
        1250, // 1.25%
        1250, // 1.25%
        1875, // 1.875%
        1875, // 1.875%
        3125, // 3.125%
        4375, // 4.375%
        5000, // 5%
        6250, // 6.25%
        12500 // 12.5%
    ];
    address[] private payeesOwner = [
        0x75552A8202076e707F37cf6c5F0782BCA054a6F3, // Owner 1
        0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35, // Owner 2
        0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35 // Owner 3
    ];
    uint256[] private defaultUpline;
    string private defaultBaseURI;

    mapping(uint256 => uint256) public override lineMatrix;
    mapping(uint256 => uint256) public override receivedBUSD;

    event Registration(uint256 indexed newTokenId, uint256 indexed uplineTokenId, uint256 indexed timestamp);

    constructor(address _addressBUSD, string memory _defaultBaseURI, address _defaultUplineAddress) ERC721("Matrix SC99", "MSC99") {
        tokenBUSD = IERC20(_addressBUSD);
        defaultBaseURI = _defaultBaseURI;
        for (uint256 i = 12; i > 0; i--) {
            lineMatrix[i] = i - 1;
            defaultUpline.push(i);
            _safeMint(_defaultUplineAddress, i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return defaultBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return baseURI;
    }

    function sendToPoolAndOwner(address who) internal {
        tokenBUSD.transferFrom(who, addressPool, shareValuePool);
        tokenBUSD.transferFrom(who, payeesOwner[0], shareValueOwnerBUSD[0]);
        tokenBUSD.transferFrom(who, payeesOwner[1], shareValueOwnerBUSD[1]);
        tokenBUSD.transferFrom(who, payeesOwner[2], shareValueOwnerBUSD[2]);
    }

    function _checkUplineTokenId(uint256 _uplineTokenId) internal view returns(uint256) {
        uint256 uplineTokenId = _uplineTokenId;
        if (uplineTokenId > 0) {
            for (uint256 i = 0; i < defaultUpline.length; i++) {
                if (uplineTokenId == defaultUpline[i]) {
                    uplineTokenId = defaultUpline[0];
                    break;
                }
            }
        } else {
            uplineTokenId = defaultUpline[0];
        }
        
        return uplineTokenId;
    }

    function registration(uint256 _uplineTokenId, uint256 _newTokenId) external nonReentrant {
        require(_exists(_uplineTokenId), "Upline tokenId not already minted");
        address who = _msgSender();

        sendToPoolAndOwner(who);
        uint256 uplineTokenId = _checkUplineTokenId(_uplineTokenId);
        lineMatrix[_newTokenId] = uplineTokenId;

        uint256 value = valueUpline;
        uint256 profit;
        for (uint256 i = 0; i < 12; i++) {
            profit = value * sharePercentage[i] / 100000;
            receivedBUSD[uplineTokenId] += profit;
            tokenBUSD.transferFrom(who, ownerOf(uplineTokenId), profit);
            uplineTokenId = lineMatrix[uplineTokenId];
        }

        _safeMint(who, _newTokenId);
        emit Registration(_newTokenId, uplineTokenId, block.timestamp);
    }

    function rangeTokenIds(address _who, uint256 _startIndex, uint256 _stopIndex) public view override returns (uint256[] memory) {
        uint256 lengthOwned = _stopIndex - _startIndex;
        uint256[] memory ownedTokenIds = new uint256[](lengthOwned);
        uint256 index = 0;
        for (uint i = _startIndex; i < (_stopIndex + 1); i++) {
            ownedTokenIds[index] = tokenOfOwnerByIndex(_who, i);
            index++;
        }
        return ownedTokenIds;
    }

    function rangeInfo(address _who, uint256 _startIndex, uint256 _stopIndex) external view override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ownedTokenIds = rangeTokenIds(_who, _startIndex, _stopIndex);
        uint256[] memory profitBUSDByTokenId = new uint256[](ownedTokenIds.length);
        for (uint i = 0; i < ownedTokenIds.length; i++) {
            profitBUSDByTokenId[i] = receivedBUSD[ownedTokenIds[i]];
        }
        return (ownedTokenIds, profitBUSDByTokenId);
    }

    function allTokenIds(address _who) public view override returns (uint256[] memory) {
        uint256 lengthOwned = balanceOf(_who);
        uint256[] memory ownedTokenIds = new uint256[](lengthOwned);
        for (uint i = 0; i < lengthOwned; i++) {
            ownedTokenIds[i] = tokenOfOwnerByIndex(_who, i);
        }
        return ownedTokenIds;
    }

    function allInfo(address _who) external view override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ownedTokenIds = allTokenIds(_who);
        uint256[] memory profitBUSDByTokenId = new uint256[](ownedTokenIds.length);
        for (uint i = 0; i < ownedTokenIds.length; i++) {
            profitBUSDByTokenId[i] = receivedBUSD[ownedTokenIds[i]];
        }
        return (ownedTokenIds, profitBUSDByTokenId);
    }

    function totalReceivedBUSD(address _who) external view override returns (uint256) {
        uint256[] memory ownedTokenIds = allTokenIds(_who);
        uint256 profitBUSD;
        for (uint i = 0; i < ownedTokenIds.length; i++) {
            profitBUSD += receivedBUSD[ownedTokenIds[i]];
        }
        return profitBUSD;
    }
}