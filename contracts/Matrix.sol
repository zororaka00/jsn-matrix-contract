pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract Matrix is Context, ReentrancyGuard {
    IERC20 public tokenBUSD;

    uint256 public constant investmentAmount = 50000 ether; // 50,000 MATIC
    uint256 public constant maxInvestmentProfit = 75000 ether; // 75,000 MATIC
    uint256 private constant sharePercentageOwner = 75; // 75%
    address[] private payeesOwner = [
        0x0fFee57EAA1026857E381BC51B6832735006fc6a, // Owner 1
        0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35 // Owner 2
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
    mapping(address => uint256) public receivedBUSD;

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

    function invest() external payable nonReentrant {
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
        address uplineAddress = _uplineAddress;
        if (uplineAddress != address(0)) {
            for (uint256 i = 0; i < defaultUplineAddress.length; i++) {
                if (uplineAddress == defaultUplineAddress[i]) {
                    uplineAddress = defaultUplineAddress[0];
                    break;
                }
            }
        } else {
            uplineAddress = defaultUplineAddress[0];
        }
        
        return uplineAddress;
    }
    
    function registration(address _uplineAddress) external payable nonReentrant {
        address who = _msgSender();
        require(lineMatrix[who] == address(0), "Address already registration");
        uint256 valueCoin = msg.value;
        require(valueCoin >= 2 ether, "Less than 2 Matic");
        address uplineAddress = _checkUpline(_uplineAddress);
        address currentAddress = uplineAddress;
        uint256 shareProfit = priceBUSD;

        if (investorAddress != address(0)) {
            if (valueCoin >= pendingClaimInvestor) {
                Address.sendValue(payable(investorAddress), pendingClaimInvestor);
                valueCoin -= pendingClaimInvestor;
                pendingClaimInvestor = 0;
                investorAddress = address(0);
            } else {
                Address.sendValue(payable(investorAddress), valueCoin);
                pendingClaimInvestor -= valueCoin;
                valueCoin = 0;
            }
        }

        if (valueCoin > 0) {
            sendToOwner(valueCoin);
        }

        lineMatrix[who] = currentAddress;
        for (uint256 i = 0; i < 12; i++) {
            uint256 profit = priceBUSD * sharePercentage[i] / 100000;
            shareProfit -= profit;
            receivedBUSD[currentAddress] += profit;
            tokenBUSD.transferFrom(who, currentAddress, profit);
            currentAddress = lineMatrix[currentAddress];
        }

        emit Registration(who, uplineAddress, block.timestamp);
    }
}
