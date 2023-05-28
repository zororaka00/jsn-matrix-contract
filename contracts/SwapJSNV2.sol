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
            0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35, // Owner 1
            0x0fFee57EAA1026857E381BC51B6832735006fc6a // Owner 2
        ];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        versionCode += 1;
    }

    receive() external payable {}

    function swapTo(address _tokenIn, address _tokenOut, address _sendTo, uint256 _amountIn, uint24 _feeTier) external payable returns (uint256) {
        address who = _msgSender();

        address addressNull = address(0);
        uint256 amountIn = shareFee(_tokenIn, who, _tokenIn == addressNull ? msg.value : _amountIn);

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
        
        IERC20 token = IERC20(_tokenIn);
        if (_tokenIn != address(WMATIC)) {
            token.transferFrom(who, address(this), _amountIn);
        }
        token.approve(address(swapRouter), _amountIn);

        uint256 amountOut = swapInternal(sendTo, tokenIn, tokenOut, amountIn, _feeTier);
        if (_tokenOut == addressNull) {
            WMATIC.withdraw(amountOut);
            Address.sendValue(payable(_sendTo), amountOut);
        }
        return amountOut;
    }

    function multiSwapTo(address _tokenIn, address[] memory _tokenOut, address _sendTo, uint256 _amountIn, uint24[] memory _feeTier) external payable returns (uint256) {
        require(_tokenOut.length > 1, "Length must be greater than 1");
        require(_tokenOut.length == _feeTier.length, "Different length");
        address who = _msgSender();

        address addressNull = address(0);
        uint256 amountIn = shareFee(_tokenIn, who, _tokenIn == addressNull ? msg.value : _amountIn);

        address tokenIn = _tokenIn;
        if (_tokenIn == addressNull) {
            tokenIn = address(WMATIC);
            WMATIC.deposit{ value: amountIn }();
        } else {
            IERC20(_tokenIn).transferFrom(who, address(this), _amountIn);
        }

        uint256 amountOut;
        address sendTo = address(this);
        address addressSwapRouter = address(swapRouter);
        for (uint i = 0; i < _tokenOut.length; i++) {
            IERC20(tokenIn).approve(addressSwapRouter, amountIn);
            amountOut = swapInternal(sendTo, tokenIn, _tokenOut[i], amountIn, _feeTier[i]);
            if (i < (_tokenOut.length - 1)) {
                amountIn = amountOut;
                tokenIn = _tokenOut[i];
            }
        }

        address tokenOut = _tokenOut[_tokenOut.length - 1];
        if (tokenOut == addressNull) {
            WMATIC.withdraw(amountOut);
            Address.sendValue(payable(_sendTo), amountOut);
        } else {
            IERC20(tokenOut).transfer(_sendTo, amountOut);
        }
        return amountOut;
    }
    
    function swapInternal(address _sendTo, address _tokenIn, address _tokenOut, uint256 _amountIn, uint24 _feeTier) internal returns (uint256) {
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