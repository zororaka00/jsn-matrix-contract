pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/InterfaceWETH9.sol";

contract SwapSC99 is Context {
    ISwapRouter public immutable swapRouter;
    WETH9 private WETH;

    uint256 public constant feeSwap = 4900; // 0.49 %
    uint256 public constant shareOwner = 75; // Owner 1 (75%)
    address[] private payeesOwner = [
        0x886341830b9D467EE4457dF8295e314C53EC70E8, // Owner 1
        0xC9eAB6920731BCe5BfAa4d29A9558161B2197aA9 // Owner 2
    ];

    constructor(address _WETH, address _swapRouter) {
        WETH = WETH9(_WETH);
        swapRouter = ISwapRouter(_swapRouter);
    }

    receive() external payable {}

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) external payable returns (uint256) {
        address who = _msgSender();

        address addressNull = address(0);
        uint256 valueCoin = _tokenIn == addressNull ? msg.value : _amountIn;
        uint256 amountIn = shareFee(_tokenIn, who, valueCoin);

        if (_tokenIn == addressNull) {
            WETH.deposit{ value: amountIn }();
        }
        address tokenOut = _tokenOut;
        address sendTo = who;
        if (_tokenOut == addressNull) {
            tokenOut = address(WETH);
            sendTo = address(this);
        }
        
        uint256 amountOut = swapInternal(who, sendTo, _tokenIn, tokenOut, amountIn, _feeTier);
        if (_tokenOut == addressNull) {
            WETH.withdraw(amountOut);
            Address.sendValue(payable(who), amountOut);
        }
        return amountOut;
    }

    function swapTo(address _tokenIn, address _tokenOut, address _sendTo, uint256 _amountIn, uint24 _feeTier) external payable returns (uint256) {
        address who = _msgSender();

        address addressNull = address(0);
        uint256 valueCoin = _tokenIn == addressNull ? msg.value : _amountIn;
        uint256 amountIn = shareFee(_tokenIn, who, valueCoin);

        if (_tokenIn == addressNull) {
            WETH.deposit{ value: amountIn }();
        }
        address tokenOut = _tokenOut;
        address sendTo = _sendTo;
        if (_tokenOut == addressNull) {
            tokenOut = address(WETH);
            sendTo = address(this);
        }
        
        uint256 amountOut = swapInternal(who, sendTo, _tokenIn, tokenOut, amountIn, _feeTier);
        if (_tokenOut == addressNull) {
            WETH.withdraw(amountOut);
            Address.sendValue(payable(_sendTo), amountOut);
        }
        return amountOut;
    }
    
    function swapInternal(address who, address _sendTo, address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) internal returns (uint256) {
        address addressNull = address(0);
        address tokenIn = _tokenIn == addressNull ? address(WETH) : _tokenIn;
        IERC20 token = IERC20(tokenIn);
        if (_tokenIn != addressNull) {
            token.transferFrom(who, address(this), _amountIn);
        }
        token.approve(address(swapRouter), _amountIn);
        
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: _tokenOut,
                fee: _feeTier,
                recipient: _sendTo,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            
        uint256 amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }

    function shareFee(address _token, address who, uint256 _amount) internal returns (uint256) {
        uint256 fee = _amount * feeSwap / 1e6;
        
        uint256 shareOwner1 = fee * shareOwner / 100;
        uint256 shareOwner2 = fee - shareOwner1;
        if (_token == address(0)) {
            Address.sendValue(payable(payeesOwner[0]), shareOwner1);
            Address.sendValue(payable(payeesOwner[1]), shareOwner2);
        } else {
            IERC20 token = IERC20(_token);
            token.transferFrom(who, payeesOwner[0], shareOwner1);
            token.transferFrom(who, payeesOwner[1], shareOwner2);
        }

        return _amount - fee;
    }
}