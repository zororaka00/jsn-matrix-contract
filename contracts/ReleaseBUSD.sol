pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/InterfaceShareOwner.sol";

contract RelaseBUSD {
    IERC20 public constant tokenBUSD = IERC20(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);

    address[] private defaultAddress = [
        0x584FE3EC3BD8F79c5fe9f6799Ed1cF244AF779d2,
        0xc54e5967a2C6E2E56c45B723B3315B4C49250e07,
        0x21a36aD6c913d8Af6b9dd00D204dDAb7903acA44,
        0xDc58C36A9DDe9164465eD62eb57448003E8ce45e,
        0xde65910b07d77c79d0B5114A443f4A39eCfCBb81,
        0x44b0E61e7E67eE8f87a2d609FC9944E28e014A88,
        0xFC48c0a45D3c0a827938ffa0b7bEAC41Bf3D6c44,
        0xd6DAB0E628BBbF4aAfD848a02BcDB176A62c7A36,
        0xe62982728f1561B312750E988D16D6a10Dd33b22,
        0x3122204e1061B2857483B8eB80d316a1016Ffde6,
        0x01b3f7DC5abf41d63A933e343F8CDd42012F289d,
        0x4d71624000b14f5AdE886EA4bBeEfcD00a995275
    ];

    function releaseShareOwner() external {
        address[] memory listDefaultAddress = defaultAddress;
        address addressBUSD = address(tokenBUSD);

        for (uint256 i = 0; i < 12; i++) {
            if (tokenBUSD.balanceOf(listDefaultAddress[i]) > 0) {
                InterfaceShareOwner(listDefaultAddress[i]).withdrawToken(addressBUSD);
            }
        }
    }
}