pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/InterfaceMatrixSC99.sol";

contract MatrixSC99 is ReentrancyGuard, ERC721Enumerable, InterfaceMatrixSC99 {
    IERC20 private tokenUSDC;

    uint256 private constant shareValuePool = 10e6;
    address private constant addressPool = 0xd513C6a7c18e4C38104CA637b9Dfc77cD8780A84;

    uint256[] private shareValueOwnerUSDC = [6e6, 2e6];
    uint256[] private shareValue = [
        35e6, // $35
        10e6, // $10
        5e6, // $5
        3e6, // $3
        2e6, // $2
        2e6, // $2
        2e6, // $2
        2e6, // $2
        2e6, // $2
        2e6, // $2    
        5e6, // $5
        10e6 // $10
    ];
    address[] private payeesOwner = [
        0x886341830b9D467EE4457dF8295e314C53EC70E8, // Owner 1
        0xC9eAB6920731BCe5BfAa4d29A9558161B2197aA9 // Owner 2
    ];
    uint256[] private defaultUpline;
    string private defaultBaseURI;

    mapping(uint256 => uint256) public override lineMatrix;
    mapping(uint256 => uint256) public override receivedUSDC;

    event Registration(uint256 indexed newTokenId, uint256 indexed uplineTokenId, uint256 indexed timestamp);

    // Address USDC = 0x7f5c764cbc14f9669b88837ca1490cca17c31607
    constructor(address _addressUSDC, string memory _defaultBaseURI, address _defaultUplineAddress) ERC721("Matrix SC99", "MSC99") {
        tokenUSDC = IERC20(_addressUSDC);
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
        tokenUSDC.transferFrom(who, addressPool, shareValuePool);
        tokenUSDC.transferFrom(who, payeesOwner[0], shareValueOwnerUSDC[0]);
        tokenUSDC.transferFrom(who, payeesOwner[1], shareValueOwnerUSDC[1]);
    }

    function _checkUplineTokenId(uint256 _uplineTokenId) internal view returns(uint256) {
        uint256 uplineTokenId = _uplineTokenId;
        if (uplineTokenId > 0) {
            for (uint256 i = defaultUpline.length; i > 0; i--) {
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
        uint256 lengthDefaultUpline = defaultUpline.length;
        require(_newTokenId > lengthDefaultUpline, "Set new tokenId");
        require(_uplineTokenId == 0 || _exists(_uplineTokenId), "Upline tokenId not already minted");
        address who = _msgSender();

        sendToPoolAndOwner(who);
        uint256 uplineTokenId = _checkUplineTokenId(_uplineTokenId);
        lineMatrix[_newTokenId] = uplineTokenId;

        uint256 profit;
        uint256 currentUplineTokenId = uplineTokenId;
        for (uint256 i = 0; i < lengthDefaultUpline; i++) {
            profit = shareValue[i];
            receivedUSDC[currentUplineTokenId] += profit;
            tokenUSDC.transferFrom(who, ownerOf(currentUplineTokenId), profit);
            currentUplineTokenId = lineMatrix[currentUplineTokenId];
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
        uint256[] memory profitUSDCByTokenId = new uint256[](ownedTokenIds.length);
        for (uint i = 0; i < ownedTokenIds.length; i++) {
            profitUSDCByTokenId[i] = receivedUSDC[ownedTokenIds[i]];
        }
        return (ownedTokenIds, profitUSDCByTokenId);
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
        uint256[] memory profitUSDCByTokenId = new uint256[](ownedTokenIds.length);
        for (uint i = 0; i < ownedTokenIds.length; i++) {
            profitUSDCByTokenId[i] = receivedUSDC[ownedTokenIds[i]];
        }
        return (ownedTokenIds, profitUSDCByTokenId);
    }

    function totalReceivedUSDC(address _who) external view override returns (uint256) {
        uint256[] memory ownedTokenIds = allTokenIds(_who);
        uint256 profitUSDC;
        for (uint i = 0; i < ownedTokenIds.length; i++) {
            profitUSDC += receivedUSDC[ownedTokenIds[i]];
        }
        return profitUSDC;
    }
}