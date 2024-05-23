// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IWBTC {
    function depositTo(address to) external payable;
    function deposit() external payable;
    function withdrawTo(address account, uint256 amount) external;
    function withdraw(uint256 value) external;
}
