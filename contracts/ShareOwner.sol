pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract ShareOwner is PaymentSplitter, InterfaceShareOwner {
    uint256[] private _shares = [
        75, // 75%
        25 // 25%
    ];
    address[] private _payees = [
        0x096222480b6529B0a7cf150846f4D85AEcf6f5bC, // Owner 1
        0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7 // Owner 2
    ];

    constructor() PaymentSplitter(_payees, _shares) { }

    function withdraw() external override {
        release(payable(_payees[0]));
        release(payable(_payees[1]));
    }

    function withdrawToken(address _tokenAddress) external override {
        IERC20 token = IERC20(_tokenAddress);
        release(token, _payees[0]);
        release(token, _payees[1]);
    }
}