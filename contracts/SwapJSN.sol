pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/InterfaceWMATIC.sol";

contract SwapJSN is Context, ReentrancyGuard {
    ISwapRouter public immutable swapRouter;
    IWMATIC public WMATIC;

    uint256 public constant feeSwap = 7000; // 0.7 %
    uint256 public constant shareOwner = 75; // Owner 1 (75%)
    address[] private payeesOwner = [
        0x75552A8202076e707F37cf6c5F0782BCA054a6F3, // Owner 1
        0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35 // Owner 2
    ];

    constructor(address _addressWMATIC, address _swapRouter) {
        WMATIC = IWMATIC(_addressWMATIC);
        swapRouter = ISwapRouter(_swapRouter);
    }
    
    function swap(address who, address _sendTo, address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) internal returns (uint256 amountOut) {

        IERC20 tokenIn = IERC20(_tokenIn);

        if (_tokenIn != address(WMATIC)) {
            tokenIn.transferFrom(who, address(this), _amountIn);
        }
        tokenIn.approve(address(swapRouter), _amountIn);
        
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _feeTier,
                recipient: _sendTo,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            
        amountOut = swapRouter.exactInputSingle(params);
    }

    function shareFeeETH(uint256 _amount) internal returns (uint256) {
        uint256 fee = _amount * feeSwap / 1e6;

        uint256 shareOwner1 = fee * shareOwner / 100;
        uint256 shareOwner2 = fee - shareOwner1;
        Address.sendValue(payable(payeesOwner[0]), shareOwner1);
        Address.sendValue(payable(payeesOwner[1]), shareOwner2);

        return _amount - fee;
    }

    function shareFee(address _token, address who, uint256 _amount) internal returns (uint256) {
        uint256 fee = _amount * feeSwap / 1e6;
        
        IERC20 token = IERC20(_token);
        uint256 shareOwner1 = fee * shareOwner / 100;
        uint256 shareOwner2 = fee - shareOwner1;
        token.transferFrom(who, payeesOwner[0], shareOwner1);
        token.transferFrom(who, payeesOwner[1], shareOwner2);

        return _amount - fee;
    }
}