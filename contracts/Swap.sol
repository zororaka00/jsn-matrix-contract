pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/AggregatorInterface.sol";

contract Swap is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    AggregatorInterface public aggregator;
    IERC20Upgradeable public tokenBUSD;
    
    enum SwapTo { MATIC_BUSD, BUSD_MATIC }

    uint256 public constant FEE = 2; // 2%
    uint256 public profitMATIC;
    uint256 public profitBUSD;

    event Swap(address indexed who, SwapTo indexed info, uint256 indexed valueSend, uint256 valueReceived);

    function initialize(address aggregatorAddress, address addressBUSD) public initializer {
        __Ownable_init();
        aggregator = AggregatorInterface(aggregatorAddress);
        tokenBUSD = IERC20Upgradeable(addressBUSD);
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }

    function deposit() external payable onlyOwner {
        AddressUpgradeable.sendValue(payable(address(this)), msg.value);
    }
    
    function depositToken(uint256 _value) external payable onlyOwner {
        address owner = _msgSender();
        SafeERC20Upgradeable.safeTransferFrom(tokenBUSD, owner, address(this), _value);
    }

    function withdraw(uint256 _value) external onlyOwner {
        address owner = owner();
        AddressUpgradeable.sendValue(payable(owner), _value);
    }

    function withdrawToken(address _token, uint256 _value) external onlyOwner {
        address owner = owner();
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        SafeERC20Upgradeable.safeTransfer(token, owner, _value);
    }

    function swapMATICToBUSD() external payable nonReentrant {
        uint256 valueCoin = msg.value;
        uint256 feeValue = valueCoin * FEE / 100;
        uint256 value = valueCoin - feeValue;
        uint256 balance = tokenBUSD.balanceOf(address(this));

        uint256 receivedValue = infoSwap(SwapTo.MATIC_BUSD, value);
        require(receivedValue >= balance, "Balance less than value");

        address who = _msgSender();
        SafeERC20Upgradeable.safeTransfer(tokenBUSD, who, receivedValue);

        emit Swap(who, SwapTo.MATIC_BUSD, valueCoin, receivedValue);
    }

    function swapBUSDToMATIC(uint256 _value) external nonReentrant {
        uint256 feeValue = _value * FEE / 100;
        uint256 value = _value - feeValue;
        uint256 balance = address(this).balance;

        uint256 receivedValue = infoSwap(SwapTo.BUSD_MATIC, value);
        require(receivedValue >= balance, "Balance less than value");

        address who = _msgSender();
        SafeERC20Upgradeable.safeTransferFrom(tokenBUSD, who, address(this), _value);
        payable(who).transfer(receivedValue);

        emit Swap(who, SwapTo.BUSD_MATIC, _value, receivedValue);
    }

    function infoSwap(SwapTo _swapTo, uint256 _value) public view returns(uint256) {
        uint256 latestAnswer = uint256(aggregator.latestAnswer());
        uint256 result = _swapTo == SwapTo.MATIC_BUSD ? _value * latestAnswer / (10 ** 8) : _value * (10 ** 8) / latestAnswer;
        return result;
    }
}