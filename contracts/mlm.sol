pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract mlm is ERC721Enumerable, ReentrancyGuard {
    enum Tier { LEVEL_LOW, LEVEL_MEDIUM, LEVEL_HARD, LEVEL_EXPERT }

    IERC20 public tokenUSDC;

    uint256 public constant investmentAmount = 80000e6; // 80,000 USDC
    uint256 public constant maxInvestmentProfit = 120000e6; // 120,000 USDC
    uint256 private constant percentageShareOwner = 60; // 60%
    address[] private payeesOwner = [
        0x9586C94d8D058188696Ba82A03DCEfbFfDD206aD, // Owner 1
        0x189E379482a066Ec681924b69CDF248494687c51 // Owner 2
    ];

    uint256 public balanceOwner;
    uint256 public pendingClaimInvestor;
    address public investorAddress;

    mapping(address => uint256) public balance;
    mapping(Tier => uint256) public priceTier;
    mapping(uint256 => Tier) public tierOf;
    mapping(Tier => uint256) public sharePercentage;
    mapping(uint256 => uint256) public lineTree;

    event PurchasePosition(address indexed who, uint256 indexed tokenId, Tier indexed tier, address uplineAddress, uint256 uplineTokenId);
    event WithdrawProfit(address indexed who, uint256 indexed amount);

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
        uint256 currentBalance = balanceOwner;
        balanceOwner = 0;
        if (investorAddress != address(0)) {
            if (pendingClaimInvestor <= currentBalance) {
                SafeERC20.safeTransfer(tokenUSDC, investorAddress, currentBalance - pendingClaimInvestor);
                pendingClaimInvestor = 0;
                currentBalance -= pendingClaimInvestor;
                investorAddress = address(0);
            } else {
                SafeERC20.safeTransfer(tokenUSDC, investorAddress, currentBalance);
                pendingClaimInvestor -= currentBalance;
                currentBalance = 0;
            }
        }
        if (currentBalance > 0) {
            uint256 shareOwner1 = currentBalance * percentageShareOwner / 100;
            uint256 shareOwner2 = currentBalance - shareOwner1;
            SafeERC20.safeTransfer(tokenUSDC, payeesOwner[0], shareOwner1);
            SafeERC20.safeTransfer(tokenUSDC, payeesOwner[1], shareOwner2);
        }
    }

    function investment() external nonReentrant {
        require(investorAddress == address(0), "Investment has been filled");
        uint256 shareOwner1 = investmentAmount * percentageShareOwner / 100;
        uint256 shareOwner2 = investmentAmount - shareOwner1;
        SafeERC20.safeTransfer(tokenUSDC, payeesOwner[0], shareOwner1);
        SafeERC20.safeTransfer(tokenUSDC, payeesOwner[1], shareOwner2);
        investorAddress = _msgSender();
        pendingClaimInvestor = maxInvestmentProfit;
    }

    function releaseUpline(uint256 _tokenId, uint256 _uplineTokenId, Tier _tier) internal {
        if (ownerOf(_uplineTokenId) != address(0)) {
            lineTree[_tokenId] = _uplineTokenId;
        }

        uint256 shareProfit = priceTier[_tier];
        uint256 currentTokenId = _uplineTokenId;
        for (uint256 i = 0; i < 10; i++) {
            uint256 profit = shareProfit * sharePercentage[tierOf[currentTokenId]] / 100;
            balance[ownerOf(currentTokenId)] += profit;
            shareProfit -= profit;
            if (i < 9 && lineTree[currentTokenId] == 0) {
                profit = shareProfit * sharePercentage[tierOf[_uplineTokenId]] / 100 * (9 - i);
                balance[ownerOf(_uplineTokenId)] += profit;
                shareProfit -= profit;
                break;
            } else {
                currentTokenId = lineTree[currentTokenId];
            }
        }
        
        balanceOwner += shareProfit;
    }

    function mint(uint256 _uplineTokenId, Tier _tier) external nonReentrant {
        address minter = _msgSender();
        require(uint8(_tier) < 4, "Tier not available");
        SafeERC20.safeTransferFrom(tokenUSDC, minter, address(this), priceTier[_tier]);

        uint256 tokenId = totalSupply() + 1;
        tierOf[tokenId] = _tier;

        releaseUpline(tokenId, _uplineTokenId, _tier);
        _mint(minter, tokenId);
        
        emit PurchasePosition(minter, tokenId, _tier, ownerOf(_uplineTokenId), _uplineTokenId);
    }

    function withdraw(address _withdrawAddress) external nonReentrant {
        uint256 currentBalance = balance[_withdrawAddress];
        require(_withdrawAddress != address(0) && currentBalance > 0, "Withdraw cannot be processed");
        SafeERC20.safeTransfer(tokenUSDC, _withdrawAddress, currentBalance);
        balance[_withdrawAddress] = 0;

        emit WithdrawProfit(_withdrawAddress, currentBalance);
    }
}