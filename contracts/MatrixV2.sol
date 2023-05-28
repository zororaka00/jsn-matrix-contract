pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract MatrixV2 is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IERC20 public tokenBUSD;

    uint256 public versionCode;
    uint256 private constant priceBUSD = 16e18;
    uint256 private constant sharePercentageOwner = 75; // 75%
    address[] public payeesOwner;

    address[] public defaultUplineAddress;
    uint256[] public sharePercentage;

    mapping(address => address) public lineMatrix;
    mapping(address => uint256) public receivedBUSD;

    event Registration(address indexed who, address indexed uplineAddress, uint256 indexed timestamp);

    function initialize(address _addressBUSD, address[] memory _defaultUplineAddress, address[] memory _payeesOwner) public initializer {
        __Ownable_init();
        require(_defaultUplineAddress.length == 12, "Max length is 12");
        require(_payeesOwner.length == 2, "Share percentage length is 2");
        tokenBUSD = IERC20(_addressBUSD);
        defaultUplineAddress = _defaultUplineAddress;
        for (uint256 i = 0; i < (_defaultUplineAddress.length - 1); i++) {
            lineMatrix[_defaultUplineAddress[i]] = _defaultUplineAddress[i + 1];
        }
        payeesOwner = _payeesOwner;
        sharePercentage = [
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
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        versionCode += 1;
    }

    function addLineMatrix(address[] memory _currentAddress, address[] memory _uplineAddress) external onlyOwner {
        require(_currentAddress.length == _uplineAddress.length, "Different length");
        uint256[] memory share = sharePercentage;
        uint256 price = priceBUSD;

        uint256[] memory profits = new uint256[](12);
        for (uint256 q = 0; q < 12; q++) {
            profits[q] = price * share[q] / 100000;
        }

        for (uint256 a = 0; a < _currentAddress.length; a++) {
            address currentAddress = _checkUpline(_uplineAddress[a]);
            lineMatrix[_currentAddress[a]] = currentAddress;
            for (uint256 i = 0; i < 12; i++) {
                receivedBUSD[currentAddress] += profits[i];
                currentAddress = lineMatrix[currentAddress];
            }
        }
    }

    function releaseShareOwner(address _tokenAddress) external {
        IERC20 token = IERC20(_tokenAddress);
        address[] memory listAddress = defaultUplineAddress;
        for (uint256 i = 0; i < 12; i++) {
            if (token.balanceOf(listAddress[i]) > 0) {
                InterfaceShareOwner(listAddress[i]).withdrawToken(_tokenAddress);
            }
        }
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
        address uplineAddress = _checkUpline(_uplineAddress);
        address currentAddress = uplineAddress;

        if (valueCoin > 0) {
            sendToOwner(valueCoin);
        }

        lineMatrix[who] = currentAddress;
        uint256[] memory share = sharePercentage;
        uint256 price = priceBUSD;
        for (uint256 i = 0; i < 12; i++) {
            uint256 profit = price * share[i] / 100000;
            receivedBUSD[currentAddress] += profit;
            tokenBUSD.transferFrom(who, currentAddress, profit);
            currentAddress = lineMatrix[currentAddress];
        }

        emit Registration(who, uplineAddress, block.timestamp);
    }

    function sendToOwner(uint256 _valueCoin) internal {
        uint256 shareInvestOwner1 = _valueCoin * sharePercentageOwner / 100;
        uint256 shareInvestOwner2 = _valueCoin - shareInvestOwner1;
        Address.sendValue(payable(payeesOwner[0]), shareInvestOwner1);
        Address.sendValue(payable(payeesOwner[1]), shareInvestOwner2);
    }
}