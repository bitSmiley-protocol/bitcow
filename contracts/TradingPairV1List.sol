// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ISsTradingPairV1} from './interface/ISsTradingPairV1.sol';
import {IBitcowERC20} from './interface/IBitcowERC20.sol';
import "./interface/ITradingPairV1List.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract TradingPairV1List is ITradingPairV1List, Ownable2StepUpgradeable{

    address[] pairs;
    mapping(address => bool) public pairMap;
    address tradingPairCreator;
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTradingPairCreator() {
        require(msg.sender == tradingPairCreator);
        _;
    }

    function initialize()public initializer{
        __Ownable2Step_init();
        __Ownable_init(msg.sender);
    }

    function setTradingPairCreator(address tradingPairCreator_) external{
        require(tradingPairCreator == address(0), 'Only set once');
        tradingPairCreator = tradingPairCreator_;
    }

    function addPair(address pair) external onlyTradingPairCreator {
        require(!pairMap[pair], 'Pair has in PairList');
        pairs.push(pair);
        pairMap[pair] = true;
    }
    function addPairOwner(address pair) external onlyOwner{
        require(!pairMap[pair], 'Pair has in PairList');
        pairs.push(pair);
        pairMap[pair] = true;
    }

    function fetchPairsAddressListPaginate(uint256 start, uint256 end) external view returns(address[] memory pagePairs, uint256 pairCount){
        uint256 length = pairs.length;
        if (start >= length){
            pagePairs = new address[](0);
        } else if (end > length){
            pagePairs = new address[](length-start);
        } else {
            pagePairs = new address[](end-start);
        }
        uint256 count = pagePairs.length;
        for (uint256 i = 0; i<count; i++){
            pagePairs[i] =  pairs[start];
            start++;
        }
        pairCount = pairs.length;
    }

    function fetchPairsStatsListPaginate(uint256 start, uint256 end) external view returns(PairStats[] memory pageStats, uint256 pairCount){
        if (start >= pairs.length){
            pageStats = new PairStats[](0);
        } else if (end > pairs.length){
            pageStats = new PairStats[](pairs.length-start);
        } else {
            pageStats = new PairStats[](end-start);
        }
        for (uint256 i = 0; start < end && start < pairs.length; i++){
            address pair = pairs[start];
            pageStats[i] = PairStats(
                Pair(
                    pair,
                    ISsTradingPairV1(pair).xToken(),
                    ISsTradingPairV1(pair).yToken(),
                    ISsTradingPairV1(pair).lpToken()
                ),
                ISsTradingPairV1(pair).getStats()
            );
            start++;
        }
        pairCount = pairs.length;
    }

    function fetchPairsStatsListPaginateV2(uint256 start, uint256 end) external view returns(PairStatsV2[] memory pageStats, uint256 pairCount){
        if (start >= pairs.length){
            pageStats = new PairStatsV2[](0);
        } else if (end > pairs.length){
            pageStats = new PairStatsV2[](pairs.length-start);
        } else {
            pageStats = new PairStatsV2[](end-start);
        }
        for (uint256 i = 0; start < end && start < pairs.length; i++){
            address pair = pairs[start];
            address xToken =ISsTradingPairV1(pair).xToken();
            address yToken = ISsTradingPairV1(pair).yToken();
            pageStats[i] = PairStatsV2(
                PairV2(
                    pair,
                    xToken,
                    IBitcowERC20(xToken).decimals(),
                    IBitcowERC20(xToken).symbol(),
                    yToken,
                    IBitcowERC20(yToken).decimals(),
                    IBitcowERC20(yToken).symbol(),
                    ISsTradingPairV1(pair).lpToken()
                ),
                ISsTradingPairV1(pair).getStats()
            );
            start++;
        }
        pairCount = pairs.length;
    }

}
