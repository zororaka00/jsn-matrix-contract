pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract Matrix is Ownable, ReentrancyGuard {
    enum Tier { LEVEL_LOW, LEVEL_MEDIUM, LEVEL_HARD, LEVEL_EXPERT }

    IERC20 public tokenBUSD;

    // uint256 public constant investmentAmount = 50000e18; // 50,000 MATIC (Production)
    // uint256 public constant maxInvestmentProfit = 75000e18; // 75,000 MATIC (Production)
    uint256 public constant investmentAmount = 2e18; // 2 MATIC (Testnet)
    uint256 public constant maxInvestmentProfit = 3e18; // 3 MATIC (Testnet)
    uint256 private constant sharePercentageOwner = 75; // 75%
    address[] private payeesOwner = [
        0x096222480b6529B0a7cf150846f4D85AEcf6f5bC, // Owner 1
        0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7 // Owner 2
    ];

    address[] private defaultUplineAddress;
    uint256[] public sharePercentage = [
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
    uint256 private constant priceBUSD = 16e18;
    uint256 public pendingClaimInvestor;
    address public investorAddress;

    mapping(address => address) public lineMatrix;

    event Investment(address indexed who, uint256 indexed timestamp);
    event Registration(address indexed who, address indexed uplineAddress, uint256 indexed timestamp);

    constructor(address _addressBUSD, address[] memory _defaultUplineAddress) {
        require(_defaultUplineAddress.length == sharePercentage.length, "Max length is 12");
        tokenBUSD = IERC20(_addressBUSD);
        defaultUplineAddress = _defaultUplineAddress;
        for (uint256 i = 0; i < (_defaultUplineAddress.length - 1); i++) {
            lineMatrix[_defaultUplineAddress[i]] = _defaultUplineAddress[i + 1];
        }
    }

    function releaseShareOwner() external {
        for (uint256 i = 0; i < 12; i++) {
            InterfaceShareOwner(defaultUplineAddress[i]).withdrawToken(address(tokenBUSD));
        }
    }

    function sendToOwner(uint256 _valueCoin) internal {
        uint256 shareInvestOwner1 = _valueCoin * sharePercentageOwner / 100;
        uint256 shareInvestOwner2 = _valueCoin - shareInvestOwner1;
        Address.sendValue(payable(payeesOwner[0]), shareInvestOwner1);
        Address.sendValue(payable(payeesOwner[1]), shareInvestOwner2);
    }

    function investment() external payable nonReentrant {
        require(investorAddress == address(0), "Investment has been filled");
        uint256 valueCoin = msg.value;
        require(valueCoin >= investmentAmount, "Value less than 50,000 MATIC");
        sendToOwner(valueCoin);
        address who = _msgSender();
        investorAddress = who;
        pendingClaimInvestor = maxInvestmentProfit;

        emit Investment(who, block.timestamp);
    }

    function _checkUpline(address _uplineAddress) internal view returns(address) {
        if (_uplineAddress != address(0)) {
            for (uint256 i = 0; i < (defaultUplineAddress.length - 1); i++) {
                require(defaultUplineAddress[i] != _uplineAddress, "Cannot set default upline address");
            }
        }
        
        return _uplineAddress == address(0) ? defaultUplineAddress[0] : _uplineAddress;
    }
    
    function registration(address _uplineAddress) external payable nonReentrant {
        uint256 valueCoin = msg.value;
        require(valueCoin >= 2 ether, "Less than 2 Matic");
        address who = _msgSender();
        address uplineAddress = _checkUpline(_uplineAddress);
        address currentAddress = uplineAddress;
        uint256 shareProfit = priceBUSD;
        sendToOwner(valueCoin);

        lineMatrix[who] = currentAddress;
        for (uint256 i = 0; i < 12; i++) {
            uint256 profit = priceBUSD * sharePercentage[i] / 100000;
            if (investorAddress != address(0) && currentAddress == defaultUplineAddress[0]) {
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