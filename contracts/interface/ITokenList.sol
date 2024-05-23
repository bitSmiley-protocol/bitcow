// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITokenList {
    struct TokenInfo{
        uint256 index;
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
        string description;
        string projectUrl;
        string logoUrl;
        string coingeckoId;
    }

    struct CreateTokenInfo{
        string name;
        string symbol;
        uint8 decimals;
        string description;
        string projectUrl;
        string logoUrl;
        string coingeckoId;
    }

    function isIn(address tokenAddress) view external returns(bool);

}
