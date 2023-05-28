pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./interfaces/InterfaceWMATIC.sol";

contract SwapJSNV2 is UUPSUpgradeable, OwnableUpgradeable {
    ISwapRouter public swapRouter;
    IWMATIC public WMATIC;
    uint256 public versionCode;

    uint256 public feeSwap;
    uint256 public shareOwner;
    address[] public payeesOwner;

    function initialize(address _WMATIC, address _swapRouter) public initializer {
        __Ownable_init();
        WMATIC = IWMATIC(_WMATIC);
        swapRouter = ISwapRouter(_swapRouter);
        feeSwap = 3000; // 0.3 %
        shareOwner = 75; // Owner 1 (75%)
        payeesOwner = [
            0x75552A8202076e707F37cf6c5F0782BCA054a6F3, // Owner 1
            0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35 // Owner 2
        ];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        versionCode += 1;
    }

    receive() external payable {}

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) external payable returns (uint256) {
        address who = _msgSender();

        address addressNull = address(0);
        uint256 valueCoin = _tokenIn == addressNull ? msg.value : _amountIn;
        uint256 amountIn = shareFee(_tokenIn, who, valueCoin);

        address tokenIn = _tokenIn;
        if (_tokenIn == addressNull) {
            tokenIn = address(WMATIC);
            WMATIC.deposit{ value: amountIn }();
        }
        address tokenOut = _tokenOut;
        address sendTo = who;
        if (_tokenOut == addressNull) {
            tokenOut = address(WMATIC);
            sendTo = address(this);
        }
        
        uint256 amountOut = swapInternal(who, sendTo, tokenIn, tokenOut, amountIn, _feeTier);
        if (_tokenOut == addressNull) {
            WMATIC.withdraw(amountOut);
            Address.sendValue(payable(who), amountOut);
        }
        return amountOut;
    }

    function swapTo(address _tokenIn, address _tokenOut, address _sendTo, uint256 _amountIn, uint24 _feeTier) external payable returns (uint256) {
        address who = _msgSender();

        address addressNull = address(0);
        uint256 valueCoin = _tokenIn == addressNull ? msg.value : _amountIn;
        uint256 amountIn = shareFee(_tokenIn, who, valueCoin);

        address tokenIn = _tokenIn;
        if (_tokenIn == addressNull) {
            tokenIn = address(WMATIC);
            WMATIC.deposit{ value: amountIn }();
        }
        address tokenOut = _tokenOut;
        address sendTo = _sendTo;
        if (_tokenOut == addressNull) {
            tokenOut = address(WMATIC);
            sendTo = address(this);
        }
        
        uint256 amountOut = swapInternal(who, sendTo, tokenIn, tokenOut, amountIn, _feeTier);
        if (_tokenOut == addressNull) {
            WMATIC.withdraw(amountOut);
            Address.sendValue(payable(_sendTo), amountOut);
        }
        return amountOut;
    }
    
    function swapInternal(address who, address _sendTo, address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) internal returns (uint256) {
        IERC20 token = IERC20(_tokenIn);
        if (_tokenIn != address(WMATIC)) {
            token.transferFrom(who, address(this), _amountIn);
        }
        token.approve(address(swapRouter), _amountIn);
        
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