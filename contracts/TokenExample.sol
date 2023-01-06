pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenExample is ERC20("BUSD", "BUSD") {
    constructor() {
        _mint(_msgSender(), 1000000000e18);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function faucet(uint256 amount) external {
        _mint(_msgSender(), amount);
    }
}