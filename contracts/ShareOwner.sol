pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract ShareOwner is PaymentSplitter, InterfaceShareOwner {
    uint256[] private _shares = [
        75, // 75%
        25 // 25%
    ];
    address[] private _payees = [
        0x75552A8202076e707F37cf6c5F0782BCA054a6F3, // Owner 1
        0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35 // Owner 2
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