// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISsTradingPair {
    function xToken() external view returns(address);
    function yToken() external view returns(address);
    function swapXtoY(uint256 inputAmount) external returns(uint256);
    function swapYtoX(uint256 inputAmount) external returns (uint256);
}
