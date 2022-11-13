pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract Matrix is Ownable, ReentrancyGuard {
    enum Tier { LEVEL_LOW, LEVEL_MEDIUM, LEVEL_HARD, LEVEL_EXPERT }

    IERC20 public tokenBUSD;

    // uint256 public constant investmentAmount = 50000e18; // 50,000 USDC (Production)
    // uint256 public constant maxInvestmentProfit = 75000e18; // 75,000 USDC (Production)
    uint256 public constant investmentAmount = 2e18; // 2 USDC (Testnet)
    uint256 public constant maxInvestmentProfit = 3e18; // 3 USDC (Testnet)
    uint256 private constant sharePercentageOwner = 75; // 75%
    address[] private payeesOwner = [
        0x096222480b6529B0a7cf150846f4D85AEcf6f5bC, // Owner 1
        0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7 // Owner 2
    ];

    address[] private defaultUplineAddress;
    uint256[] public sharePercentage = [
        500, // 50% = $5
        200, // 20% = $2
        50, // 5% = $0.5
        50, // 5% = $0.5
        200 // 20% = $2
    ];
    uint256 private constant priceBUSD = 10e18;
    uint256 public pendingClaimInvestor;
    address public investorAddress;

    mapping(address => address) public lineMatrix;

    event Registration(address indexed who, address indexed uplineAddress, uint256 indexed timestamp);

    constructor(address _addressBUSD, address[] memory _defaultUplineAddress) {
        tokenBUSD = IERC20(_addressBUSD);
        defaultUplineAddress = _defaultUplineAddress;
        for (uint256 i = 0; i < (_defaultUplineAddress.length - 1); i++) {
            lineMatrix[_defaultUplineAddress[i + 1]] = _defaultUplineAddress[i];
        }
    }

    function releaseShareOwner() external {
        for (uint256 i = 0; i < 5; i++) {
            InterfaceShareOwner(defaultUplineAddress[i]).withdrawToken(address(tokenBUSD));
        }
    }

    function investment() external nonReentrant {
        require(investorAddress == address(0), "Investment has been filled");
        uint256 shareInvestOwner1 = investmentAmount * sharePercentageOwner / 100;
        uint256 shareInvestOwner2 = investmentAmount - shareInvestOwner1;
        address who = _msgSender();
        tokenBUSD.transferFrom(who, payeesOwner[0], shareInvestOwner1);
        tokenBUSD.transferFrom(who, payeesOwner[1], shareInvestOwner2);
        investorAddress = who;
        pendingClaimInvestor = maxInvestmentProfit;

        uint256 currentBalance = tokenBUSD.balanceOf(address(this));
        if (currentBalance > 0) {
            uint256 shareOwner1 = currentBalance * sharePercentageOwner / 100;
            uint256 shareOwner2 = currentBalance - shareOwner1;
            tokenBUSD.transfer(payeesOwner[0], shareOwner1);
            tokenBUSD.transfer(payeesOwner[1], shareOwner2);
        }
    }

    function _checkUpline(address _uplineAddress) internal view returns(address) {
        if (_uplineAddress != address(0)) {
            for (uint256 i = 0; i < (defaultUplineAddress.length - 1); i++) {
                require(defaultUplineAddress[i] != _uplineAddress, "Cannot set default upline address");
            }
        }
        
        return _uplineAddress == address(0) ? defaultUplineAddress[4] : _uplineAddress;
    }
    
    function registration(address _uplineAddress) external payable nonReentrant {
        require(msg.value >= 1.6 ether, "Less than 1.6 Matic");
        address who = _msgSender();
        address uplineAddress = _checkUpline(_uplineAddress);
        address currentAddress = uplineAddress;
        uint256 shareProfit = priceBUSD;

        lineMatrix[who] = currentAddress;
        for (uint256 i = 0; i < 4; i++) {
            uint256 profit = priceBUSD * sharePercentage[i] / 1000;
            if (investorAddress != address(0) && currentAddress == defaultUplineAddress[4]) {
                if (shareProfit > pendingClaimInvestor) {
                    tokenBUSD.transferFrom(who, investorAddress, shareProfit - pendingClaimInvestor);
                    pendingClaimInvestor = 0;
                    investorAddress = address(0);
                } else {
                    tokenBUSD.transferFrom(who, investorAddress, shareProfit);
                    pendingClaimInvestor -= shareProfit;
                }
                break;
            } else {
                shareProfit -= profit;
                tokenBUSD.transferFrom(who, currentAddress, profit);
                currentAddress = lineMatrix[currentAddress];
            }
        }

        emit Registration(who, uplineAddress, block.timestamp);
    }
}