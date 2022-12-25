pragma solidity >=0.7.5;
pragma abicoder v2;

import "./SwapJSN.sol";

contract SwapJSNAdvanced is SwapJSN {

    constructor(address _wmatic, address _router) SwapJSN(_wmatic, _router) { }

    function swapETH(address _tokenOut, uint24 feeTier) external payable nonReentrant {
        address who = _msgSender();

        uint256 amountIn = shareFeeETH(msg.value);
        WMATIC.deposit{ value: amountIn }();

        swap(who, who, address(WMATIC), _tokenOut, amountIn, feeTier);
    }

    function swapETHGift(address _sendTo, address _tokenOut, uint24 feeTier) external payable nonReentrant {
        address who = _msgSender();

        uint256 amountIn = shareFeeETH(msg.value);
        WMATIC.deposit{ value: amountIn }();

        swap(who, _sendTo, address(WMATIC), _tokenOut, amountIn, feeTier);
    }

    function swapToken(address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) external nonReentrant {
        address who = _msgSender();

        uint256 amountIn = shareFee(_tokenIn, who, _amountIn);
        
        swap(who, who, _tokenIn, _tokenOut, amountIn, _feeTier);
    }

    function swapTokenGift(address _sendTo, address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) external nonReentrant {
        address who = _msgSender();

        uint256 amountIn = shareFee(_tokenIn, who, _amountIn);
        
        swap(who, _sendTo, _tokenIn, _tokenOut, amountIn, _feeTier);
    }

    function swapTokenETH(address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) external nonReentrant {
        address who = _msgSender();

        uint256 amountIn = shareFee(_tokenIn, who, _amountIn);
        
        uint256 amountOut = swap(who, address(this), _tokenIn, _tokenOut, amountIn, _feeTier);
        WMATIC.withdraw(amountOut);
        payable(who).transfer(amountOut);
    }

    function swapTokenETHGift(address _sendTo, address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) external nonReentrant {
        address who = _msgSender();

        uint256 amountIn = shareFee(_tokenIn, who, _amountIn);
        
        uint256 amountOut = swap(who, address(this), _tokenIn, _tokenOut, amountIn, _feeTier);
        WMATIC.withdraw(amountOut);
        payable(_sendTo).transfer(amountOut);
    }
}