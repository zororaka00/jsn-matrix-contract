pragma solidity ^0.8.0;

interface InterfaceMatrixSC99 {
    function lineMatrix(uint256) external view returns(uint256);
    function receivedUSDC(uint256) external view returns(uint256);
    function rangeTokenIds(address, uint256, uint256) external view returns (uint256[] memory);
    function rangeInfo(address, uint256, uint256) external view returns (uint256[] memory, uint256[] memory);
    function allTokenIds(address) external view returns (uint256[] memory);
    function allInfo(address) external view returns (uint256[] memory, uint256[] memory);
    function totalReceivedUSDC(address) external view returns(uint256);
}