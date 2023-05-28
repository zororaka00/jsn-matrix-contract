pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract ShareOwnerV2 is UUPSUpgradeable, OwnableUpgradeable, PaymentSplitterUpgradeable, InterfaceShareOwner {
    uint256 public versionCode;

    uint256[] public _shares;
    address[] public _payees;

    function initialize(address[] memory _payeesAddress) public initializer {
        __Ownable_init();
        _shares = [
            75, // 75%
            25 // 25%
        ];
        _payees = _payeesAddress;
        __PaymentSplitter_init(_payeesAddress, _shares);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        versionCode += 1;
    }

    function withdraw() external override {
        release(payable(_payees[0]));
        release(payable(_payees[1]));
    }

    function withdrawToken(address _tokenAddress) external override {
        IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
        release(token, _payees[0]);
        release(token, _payees[1]);
    }
}