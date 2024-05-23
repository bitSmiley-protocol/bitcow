// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISsTradingPairV2 {
    function xToken() external view returns(address);
    function yToken() external view returns(address);
    function xLPToken() external view returns(address);
    function yLPToken() external view returns(address);
    event AddLiquidity(address user, uint256 xAmount, uint256 yAmount, uint256 lpAmount);
    event RemoveLiquidity(address user, uint256 lpAmount, uint256 xAmount, uint256 yAmount);
    event Swap(address user, bool isXtoY, uint256 xAmount, uint256 yAmount);
    struct FeeRecords {
        uint256[7] xProtocolFees;
        uint256[7] yProtocolFees;
        uint256[7] volumes;
    }
    struct StatsV2{
        uint64 concentration;
        uint256 feeMillionth;
        uint256 protocolFeeShareThousandth;

        // cumulative
        uint256 totalProtocolFeeX;
        uint256 totalProtocolFeeY;
        uint256 cumulativeVolume;
        FeeRecords feeRecords;
        // stats
        uint256 currentX_;
        uint256 currentY_;
        uint256 multX_;
        uint256 multY_;
        uint256 totalLP_;
    }
    function getStats() external view returns(StatsV2 memory);
    function deposit(uint256 inputX_, uint256 inputY_) external;
}
