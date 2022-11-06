pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MLM is Ownable, ERC721Enumerable, ReentrancyGuard {
    enum Level { LEVEL_LOW, LEVEL_MEDIUM, LEVEL_HARD, LEVEL_EXPERT }

    IERC20 public tokenUSDC;

    // uint256 public constant investmentAmount = 50000e6; // 50,000 USDC (Production)
    // uint256 public constant maxInvestmentProfit = 75000e6; // 75,000 USDC (Production)
    uint256 public constant investmentAmount = 20e6; // 20 USDC (Testnet)
    uint256 public constant maxInvestmentProfit = 30e6; // 30 USDC (Testnet)
    uint256 private constant percentageShareOwner = 75; // 75%
    address[] private payeesOwner = [
        0x096222480b6529B0a7cf150846f4D85AEcf6f5bC, // Owner 1
        0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7 // Owner 2
    ];
    string private customURI;

    uint256 public pendingClaimInvestor;
    address public investorAddress;

    mapping(Level => uint256) public priceLevel;
    mapping(uint256 => Level) public levelOf;
    mapping(Level => uint256) public sharePercentage;
    mapping(uint256 => uint256) public lineTree;

    event PurchasePosition(address indexed who, uint256 indexed tokenId, Level indexed level, address uplineAddress, uint256 uplineTokenId);
    event UpgradePosition(address indexed who, uint256 indexed tokenId, Level indexed newLevel, Level previousLevel);

    constructor(address _addressUSDC) ERC721("MLM", "MLM") {
        tokenUSDC = IERC20(_addressUSDC);
        priceLevel[Level.LEVEL_LOW] = 10e6; // 10 USDC
        priceLevel[Level.LEVEL_MEDIUM] = 20e6; // 20 USDC
        priceLevel[Level.LEVEL_HARD] = 50e6; // 50 USDC
        priceLevel[Level.LEVEL_EXPERT] = 100e6; // 100 USDC

        sharePercentage[Level.LEVEL_LOW] = 2; // 2%
        sharePercentage[Level.LEVEL_MEDIUM] = 4; // 4%
        sharePercentage[Level.LEVEL_HARD] = 6; // 6%
        sharePercentage[Level.LEVEL_EXPERT] = 8; // 8%
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        uint8 levelTokenId = uint8(levelOf[tokenId]);
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return Strings.toString(levelTokenId);
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Strings.toString(levelTokenId)));
        }

        return super.tokenURI(tokenId);
    }

    function setCustomURI(string memory _customURI) external onlyOwner {
        customURI = _customURI;
    }

    function releaseShare() external nonReentrant {
        uint256 currentBalance = tokenUSDC.balanceOf(address(this));
        if (investorAddress != address(0)) {
            if (pendingClaimInvestor <= currentBalance) {
                tokenUSDC.transfer(investorAddress, pendingClaimInvestor);
                currentBalance -= pendingClaimInvestor;
                pendingClaimInvestor = 0;
                investorAddress = address(0);
            } else {
                tokenUSDC.transfer(investorAddress, currentBalance);
                pendingClaimInvestor -= currentBalance;
                currentBalance = 0;
            }
        }
        if (currentBalance > 0) {
            uint256 shareOwner1 = currentBalance * percentageShareOwner / 100;
            uint256 shareOwner2 = currentBalance - shareOwner1;
            tokenUSDC.transfer(payeesOwner[0], shareOwner1);
            tokenUSDC.transfer(payeesOwner[1], shareOwner2);
        }
    }

    function investment() external nonReentrant {
        require(investorAddress == address(0), "Investment has been filled");
        uint256 shareInvestOwner1 = investmentAmount * percentageShareOwner / 100;
        uint256 shareInvestOwner2 = investmentAmount - shareInvestOwner1;
        address who = _msgSender();
        tokenUSDC.transferFrom(who, payeesOwner[0], shareInvestOwner1);
        tokenUSDC.transferFrom(who, payeesOwner[1], shareInvestOwner2);
        investorAddress = who;
        pendingClaimInvestor = maxInvestmentProfit;

        uint256 currentBalance = tokenUSDC.balanceOf(address(this));
        if (currentBalance > 0) {
            uint256 shareOwner1 = currentBalance * percentageShareOwner / 100;
            uint256 shareOwner2 = currentBalance - shareOwner1;
            tokenUSDC.transfer(payeesOwner[0], shareOwner1);
            tokenUSDC.transfer(payeesOwner[1], shareOwner2);
        }
    }

    function releaseUpline(address _minter, uint256 _tokenId, uint256 _uplineTokenId, Level _level) internal {
        uint256 price = priceLevel[_level];
        uint256 shareProfit = price;
        if (_uplineTokenId > 0) {
            lineTree[_tokenId] = _uplineTokenId;
            uint256 currentTokenId = _uplineTokenId;
            for (uint256 i = 0; i < 10; i++) {
                uint256 profit = price * sharePercentage[levelOf[currentTokenId]] / 100;
                tokenUSDC.transferFrom(_minter, ownerOf(currentTokenId), profit);
                shareProfit -= profit;
                if (i < 9 && lineTree[currentTokenId] == 0) {
                    profit = price * sharePercentage[levelOf[_uplineTokenId]] / 100 * (9 - i);
                    tokenUSDC.transferFrom(_minter, ownerOf(_uplineTokenId), profit);
                    shareProfit -= profit;
                    break;
                } else {
                    currentTokenId = lineTree[currentTokenId];
                }
            }
        }
        
        tokenUSDC.transferFrom(_minter, address(this), shareProfit);
    }

    function mint(uint256 _uplineTokenId, Level _level) external nonReentrant {
        uint256 supplyTokenId = totalSupply();
        address minter = _msgSender();
        require(uint8(_level) < 4, "Level not available");
        require(_uplineTokenId <= supplyTokenId, "Invalid TokenId");

        uint256 tokenId = supplyTokenId + 1;
        releaseUpline(minter, tokenId, _uplineTokenId, _level);
        _mint(minter, tokenId);
        levelOf[tokenId] = _level;
        
        address uplineAddress = _uplineTokenId > 0 ? ownerOf(_uplineTokenId) : address(0);
        emit PurchasePosition(minter, tokenId, _level, uplineAddress, _uplineTokenId);
    }

    function upgrade(uint256 _tokenId, Level _newLevel) external nonReentrant {
        Level previousLevel = levelOf[_tokenId];
        address owner = ownerOf(_tokenId);
        require(owner == _msgSender(), "Not the owner");
        require(uint8(previousLevel) < 3, "Level not available");
        require(uint8(_newLevel) > uint8(previousLevel), "New Level must be more than the previous level");

        releaseUpline(owner, _tokenId, lineTree[_tokenId], _newLevel);
        levelOf[_tokenId] = _newLevel;

        emit UpgradePosition(owner, _tokenId, _newLevel, previousLevel);
    }
}