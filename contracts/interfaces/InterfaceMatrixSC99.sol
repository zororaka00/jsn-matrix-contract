pragma solidity ^0.8.0;

interface InterfaceMatrixSC99 {
    function lineMatrix(uint256) external view returns(uint256);
    function receivedBUSD(address) external view returns(uint256);
}