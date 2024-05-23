// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ISsTradingPairV1} from './ISsTradingPairV1.sol';
interface ITradingPairV1List {

    struct PairStats{
        Pair pair;
        ISsTradingPairV1.StatsV1 statsV1;
    }
    struct Pair {
        address pairAddress;
        address xToken;
        address yToken;
        address lpToken;
    }
    struct PairStatsV2{
        PairV2 pair;
        ISsTradingPairV1.StatsV1 statsV1;
    }
    struct PairV2 {
        address pairAddress;
        address xToken;
        uint8 xDecimals;
        string xSymbol;
        address yToken;
        uint8 yDecimals;
        string ySymbol;
        address lpToken;
    }

    function addPair(address pair) external;
    function setTradingPairCreator(address tradingPairCreator_) external;
}
