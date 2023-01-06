pragma solidity ^0.8.0;

interface InterfaceMatrixSC99 {
    function lineMatrix(uint256) external view returns(uint256);
    function receivedBUSD(uint256) external view returns(uint256);
    function allTokenIds(address) external view returns (uint256[] memory);
    function allInfo(address) external view returns (uint256[] memory, uint256[] memory);
    function totalReceivedBUSD(address) external view returns(uint256);
}