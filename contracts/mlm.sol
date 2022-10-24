pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MLM is ERC721Enumerable, ReentrancyGuard {
    enum Tier { LEVEL_LOW, LEVEL_MEDIUM, LEVEL_HARD, LEVEL_EXPERT }

    IERC20 public tokenUSDC;

    // uint256 public constant investmentAmount = 80000e6; // 80,000 USDC (Production)
    // uint256 public constant maxInvestmentProfit = 120000e6; // 120,000 USDC (Production)
    uint256 public constant investmentAmount = 20e6; // 20 USDC (Testnet)
    uint256 public constant maxInvestmentProfit = 30e6; // 30 USDC (Testnet)
    uint256 private constant percentageShareOwner = 75; // 75%
    address[] private payeesOwner = [
        0x9586C94d8D058188696Ba82A03DCEfbFfDD206aD, // Owner 1
        0x189E379482a066Ec681924b69CDF248494687c51 // Owner 2
    ];

    uint256 public pendingClaimInvestor;
    address public investorAddress;

    mapping(Tier => uint256) public priceTier;
    mapping(uint256 => Tier) public tierOf;
    mapping(Tier => uint256) public sharePercentage;
    mapping(uint256 => uint256) public lineTree;

    event PurchasePosition(address indexed who, uint256 indexed tokenId, Tier indexed tier, address uplineAddress, uint256 uplineTokenId);
    event UpgradePosition(address indexed who, uint256 indexed tokenId, Tier indexed newTier, Tier previousTier);

    constructor(address _addressUSDC) ERC721("MLM", "MLM") {
        tokenUSDC = IERC20(_addressUSDC);
        priceTier[Tier.LEVEL_LOW] = 10e6; // 10 USDC
        priceTier[Tier.LEVEL_MEDIUM] = 20e6; // 20 USDC
        priceTier[Tier.LEVEL_HARD] = 50e6; // 50 USDC
        priceTier[Tier.LEVEL_EXPERT] = 100e6; // 100 USDC

        sharePercentage[Tier.LEVEL_LOW] = 2; // 2%
        sharePercentage[Tier.LEVEL_MEDIUM] = 4; // 4%
        sharePercentage[Tier.LEVEL_HARD] = 6; // 6%
        sharePercentage[Tier.LEVEL_EXPERT] = 8; // 8%
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
        uint256 shareOwner1 = investmentAmount * percentageShareOwner / 100;
        uint256 shareOwner2 = investmentAmount - shareOwner1;
        address who = _msgSender();
        tokenUSDC.transferFrom(who, payeesOwner[0], shareOwner1);
        tokenUSDC.transferFrom(who, payeesOwner[1], shareOwner2);
        investorAddress = who;
        pendingClaimInvestor = maxInvestmentProfit;
    }

    function releaseUpline(address _minter, uint256 _tokenId, uint256 _uplineTokenId, Tier _tier) internal {
        uint256 price = priceTier[_tier];
        uint256 shareProfit = price;
        if (_uplineTokenId > 0) {
            lineTree[_tokenId] = _uplineTokenId;
            uint256 currentTokenId = _uplineTokenId;
            for (uint256 i = 0; i < 10; i++) {
                uint256 profit = price * sharePercentage[tierOf[currentTokenId]] / 100;
                tokenUSDC.transferFrom(_minter, ownerOf(currentTokenId), profit);
                shareProfit -= profit;
                if (i < 9 && lineTree[currentTokenId] == 0) {
                    profit = price * sharePercentage[tierOf[_uplineTokenId]] / 100 * (9 - i);
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

    function mint(uint256 _uplineTokenId, Tier _tier) external nonReentrant {
        uint256 supplyTokenId = totalSupply();
        address minter = _msgSender();
        require(uint8(_tier) < 4, "Tier not available");
        require(_uplineTokenId <= supplyTokenId, "Invalid TokenId");

        uint256 tokenId = supplyTokenId + 1;
        releaseUpline(minter, tokenId, _uplineTokenId, _tier);
        _mint(minter, tokenId);
        tierOf[tokenId] = _tier;
        
        address uplineAddress = _uplineTokenId > 0 ? ownerOf(_uplineTokenId) : address(0);
        emit PurchasePosition(minter, tokenId, _tier, uplineAddress, _uplineTokenId);
    }

    function upgrade(uint256 _tokenId, Tier _newTier) external nonReentrant {
        Tier previousTier = tierOf[_tokenId];
        address owner = ownerOf(_tokenId);
        require(owner == _msgSender(), "Not the owner");
        require(uint8(previousTier) < 3, "Tier not available");
        require(uint8(_newTier) > uint8(previousTier), "New tier must be more than the previous tier");

        releaseUpline(owner, _tokenId, lineTree[_tokenId], _newTier);
        tierOf[_tokenId] = _newTier;

        emit UpgradePosition(owner, _tokenId, _newTier, previousTier);
    }
}