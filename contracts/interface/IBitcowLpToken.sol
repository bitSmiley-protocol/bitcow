// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBitcowLpToken {
    function decimals() external view returns (uint8);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function setTradingPair(address tradingPair_) external;
}
