pragma solidity ^0.8.0;

interface IWMATIC {
    function deposit() external payable;
    function withdraw(uint) external;
    function totalSupply() external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}