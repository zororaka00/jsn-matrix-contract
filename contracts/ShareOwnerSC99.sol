pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract ShareOwnerSC99 is PaymentSplitter {
    uint256[] private _shares = [
        75, // 75%
        25 // 25%
    ];
    address[] private _payees = [
        0x886341830b9D467EE4457dF8295e314C53EC70E8, // Owner 1
        0xC9eAB6920731BCe5BfAa4d29A9558161B2197aA9 // Owner 2
    ];

    constructor() PaymentSplitter(_payees, _shares) { }

    function withdraw() external {
        release(payable(_payees[0]));
        release(payable(_payees[1]));
    }

    function withdrawToken(address _tokenAddress) external {
        IERC20 token = IERC20(_tokenAddress);
        release(token, _payees[0]);
        release(token, _payees[1]);
    }
}