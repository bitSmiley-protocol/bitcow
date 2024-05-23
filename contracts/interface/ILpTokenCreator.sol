// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILpTokenCreator {
    function createLpToken(address xToken, address yToken) external returns(address);
}
