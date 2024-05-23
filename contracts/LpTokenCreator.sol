// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {BitcowLpToken} from './BitcowLpToken.sol';
import {IBitcowERC20} from './interface/IBitcowERC20.sol';

contract LpTokenCreator {
    function createLpToken(address xToken, address yToken) external returns(address){
        uint8 xDecimals = IBitcowERC20(xToken).decimals();
        string memory xSymbol = IBitcowERC20(xToken).symbol();
        string memory ySymbol = IBitcowERC20(yToken).symbol();

        BitcowLpToken lpToken = new BitcowLpToken(string(abi.encodePacked("Bitcow V1 LP ", xSymbol, " ", ySymbol)),string(abi.encodePacked(xSymbol, "-", ySymbol)), xDecimals);
        return address(lpToken);
    }
}
