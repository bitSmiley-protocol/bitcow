// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import {IBitcowERC20} from "./interface/IBitcowERC20.sol";
import {IBitcowLpToken} from "./interface/IBitcowLpToken.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ISsTradingPairV1} from "./interface/ISsTradingPairV1.sol";

contract SsTradingPairV1 is Initializable, Ownable2StepUpgradeable, PausableUpgradeable, ISsTradingPairV1{
    uint256 public MILLIONTH;

    address public xToken;
    address public yToken;
    address public lpToken;
    uint256 public multX;
    uint256 public multY;

    uint64 public concentration;
    uint64 public feeMillionth;
    uint64 public protocolFeeShareThousandth;

    uint256 public totalProtocolFeeX;
    uint256 public totalProtocolFeeY;
    uint256 public cumulativeVolume;
    FeeRecords feeRecords;


    address public protocolFeeAddress;


    function initialize(
        address xToken_,
        address yToken_,
        address lpToken_,
        uint64 concentration_,
        uint64 protocolFeeShareThousandth_,
        uint64 feeMillionth_,
        address protocolFeeAddress_,
        uint64 xPrice_,
        uint64 yPrice_
    )public initializer{
        __Ownable2Step_init();
        __Ownable_init(msg.sender);
        __Pausable_init();
        xToken = xToken_;
        yToken = yToken_;
        MILLIONTH = 1000000;
        require(IBitcowLpToken(lpToken_).decimals() == IBitcowERC20(xToken).decimals(), 'Lp token decimals must equals x token');
        IBitcowLpToken(lpToken_).setTradingPair(address(this));
        lpToken = lpToken_;
        protocolFeeShareThousandth = protocolFeeShareThousandth_;
        concentration = concentration_;
        require(feeMillionth_ <= MILLIONTH, "FeeMillionth must not greate than 1000000");
        feeMillionth = feeMillionth_;
        require(protocolFeeAddress_ != address(0), "ProtocolFeeAddress can not be empty");
        protocolFeeAddress = protocolFeeAddress_;
        updateMult(xPrice_, yPrice_);
    }

    function updatePrice(uint64 xPrice_, uint64 yPrice_) external onlyOwner{
        updateMult(xPrice_, yPrice_);
    }
    //  price has decimals 4, 10000 = 1.0000
    function updateMult(uint64 xPrice_, uint64 yPrice_) private {
        uint8 xDecimals = IBitcowERC20(xToken).decimals();
        uint8 yDecimals = IBitcowERC20(yToken).decimals();
        if (xDecimals > yDecimals){
            multX = xPrice_ ;
            multY = yPrice_ * 10 ** (xDecimals-yDecimals);
        } else if (yDecimals > xDecimals){
            multX = xPrice_ * 10 ** (yDecimals-xDecimals);
            multY = yPrice_;
        } else {
            multX = xPrice_;
            multY = yPrice_;
        }
    }

    function updateConcentration(uint64 concentration_) external onlyOwner{
        require(concentration_ <= 2000, "concentration can not greate than 2000");
        require(concentration_ >= 1, "concentration can not less than 1");
        concentration = concentration_;
    }

    function updateFeeMillionth(uint64 feeMillionth_) external onlyOwner {
        require(feeMillionth_ <= MILLIONTH, "FeeMillionth must not greate than 1000000");
        feeMillionth = feeMillionth_;
    }

    function updateProtocolFeeAddress(address protocolFeeAddress_) external onlyOwner {
        require(protocolFeeAddress_ != address(0), "ProtocolFeeAddress can not be empty");
        protocolFeeAddress = protocolFeeAddress_;
    }

    function deposit(uint256 inputX_, uint256 inputY_) external whenNotPaused{
        uint256 currentX = IBitcowERC20(xToken).balanceOf(address(this));
        uint256 currentY = IBitcowERC20(yToken).balanceOf(address(this));
        uint256 mintLP = inputX_;
        if (currentX > 0){
            inputY_ = inputX_ * currentY / currentX;
            uint256 supplyLP = IBitcowLpToken(lpToken).totalSupply();
            mintLP = supplyLP * inputX_ / currentX;
        } else {
            require(inputX_ > 0, 'input X must more than zeros');
            require(inputY_ > 0, 'input Y must more than zeros');
        }
        emit AddLiquidity(tx.origin, inputX_, inputY_, mintLP);
        IBitcowERC20(xToken).transferFrom(msg.sender, address(this), inputX_);
        IBitcowERC20(yToken).transferFrom(msg.sender, address(this), inputY_);
        IBitcowLpToken(lpToken).mint(msg.sender, mintLP);
    }

    function withdraw(uint256 inputLP) external whenNotPaused {
        uint256 currentX = IBitcowERC20(xToken).balanceOf(address(this));
        uint256 currentY = IBitcowERC20(yToken).balanceOf(address(this));
        uint256 supplyLP = IBitcowLpToken(lpToken).totalSupply();
        uint256 outputX = currentX * inputLP / supplyLP;
        uint256 outputY = currentY * inputLP / supplyLP;
        emit RemoveLiquidity(tx.origin, inputLP, outputX, outputY);
        IBitcowLpToken(lpToken).burn(msg.sender, inputLP);
        IBitcowERC20(xToken).transfer(msg.sender, outputX);
        IBitcowERC20(yToken).transfer(msg.sender, outputY);
    }

    /*
     uint256 currentX_, uint256 currentY_, uint256 targetX_, uint256 targetY_, uint256 multX_, uint256 multY_
    */
    function getPoolValues() private view returns(uint256 currentX_,uint256 currentY_,uint256 multX_,uint256 multY_,uint256 targetX_,uint256 bigK_) {
        currentX_ = IBitcowERC20(xToken).balanceOf(address(this));
        currentY_ = IBitcowERC20(yToken).balanceOf(address(this));
        multX_ = multX;
        multY_ = multY;
        if (concentration == 1) {
            bigK_ = currentX_ * currentY_;
            targetX_ = 0;
        } else {
            targetX_ =  (currentX_ * multX_ + currentY_ * multY_) / 2 / multX;
            uint256 targetY = targetX_ * multX_ / multY_;
            bigK_ = concentration * concentration * targetX_ * targetY;
        }
    }


    function swapXtoY(uint256 inputAmount) external whenNotPaused returns(uint256) {
        (uint256 outputAfterFeeY, uint256 protocolFeeInY, uint256 multX_, uint256 multY_) = quoteXtoY(inputAmount);
        IBitcowERC20(xToken).transferFrom(msg.sender, address(this), inputAmount);
        IBitcowERC20(yToken).transfer(msg.sender, outputAfterFeeY);
        IBitcowERC20(yToken).transfer(protocolFeeAddress, protocolFeeInY);
        totalProtocolFeeY = totalProtocolFeeY + protocolFeeInY;
        if (multY_ == 0){
            cumulativeVolume = cumulativeVolume + inputAmount * multX_;
        } else {
            cumulativeVolume = cumulativeVolume + outputAfterFeeY * multY_;
        }
        updateFeeRecords();
        emit Swap(tx.origin, true, inputAmount, outputAfterFeeY);
        return (outputAfterFeeY);
    }

    function swapYtoX(uint256 inputAmount) external whenNotPaused returns (uint256) {
        (uint256 outputAfterFeeX, uint256 protocolFeeInX, uint256 multX_ ,uint256 multY_) = quoteYtoX(inputAmount);
        IBitcowERC20(yToken).transferFrom(msg.sender, address(this), inputAmount);
        IBitcowERC20(xToken).transfer(msg.sender, outputAfterFeeX);
        IBitcowERC20(xToken).transfer(protocolFeeAddress, protocolFeeInX);
        totalProtocolFeeX = totalProtocolFeeX + protocolFeeInX;
        if (multX_ == 0){
            cumulativeVolume = cumulativeVolume + inputAmount * multY_;
        } else {
            cumulativeVolume = cumulativeVolume + outputAfterFeeX * multX_;
        }
        updateFeeRecords();
        emit Swap(tx.origin, false, outputAfterFeeX, inputAmount);
        return (outputAfterFeeX);
    }

    function quoteXtoY(uint256 inputX) private view returns (uint256, uint256, uint256, uint256){
        (uint256 currentX_,uint256 currentY_, uint256 multX_, uint256 multY_, uint256 targetX_,uint256 bigK_) = getPoolValues();
        uint256 outputBeforeFeeY;
        if (concentration == 1){
            outputBeforeFeeY = currentY_ - bigK_ / (currentX_ + inputX);
        } else {
            // 1. find current (x,y) on curve-K
            uint256 currentXk = sqrt(bigK_ * multY_ / multX_) - targetX_ + currentX_;
            outputBeforeFeeY =  bigK_ / currentXk - bigK_ / (currentXk + inputX);
        }
        require(outputBeforeFeeY < currentY_, "Insufficient active y balance");
        uint256 feeY = outputBeforeFeeY * feeMillionth / MILLIONTH;
        uint256 outputAfterFeeY = outputBeforeFeeY - feeY;
        uint256 protocolFeeInY = feeY * protocolFeeShareThousandth / 1000;
        return (outputAfterFeeY, protocolFeeInY, multX_, multY_);

    }

    function quoteYtoX(uint256 inputY) private view returns (uint256, uint256, uint256, uint256){
        (uint256 currentX_, uint256 currentY_, uint256 multX_, uint256 multY_, uint256 targetX_, uint256 bigK_) = getPoolValues();
        uint256 outputBeforeFeeX;
        if (concentration == 1){
            outputBeforeFeeX = currentX_ - bigK_ / (currentY_ + inputY);
        } else {
            // 1. find current (x, y) on curve-K
            uint256 currentXk = sqrt(bigK_ * multY_ / multX_) - targetX_ + currentX_;
            // 2. find new (x, y) on curve-K
            outputBeforeFeeX = currentXk - bigK_ / (bigK_ / currentXk + inputY);
        }
        //                         currentX_
        require(outputBeforeFeeX < currentX_, "Insufficient active x balance");
        uint256 feeX = outputBeforeFeeX * feeMillionth / MILLIONTH;
        uint256 outputAfterFeeX = outputBeforeFeeX - feeX;
        uint256 protocolFeeInX = feeX * protocolFeeShareThousandth / 1000;
        return (outputAfterFeeX, protocolFeeInX, multX_, multY_);
    }

    function sqrt(uint256 y) private pure returns (uint256) {
        if (y < 4) {
            if (y == 0) {
                return 0;
            } else {
                return 1;
            }
        } else {
            uint256 z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
            return z;
        }
    }

    function updateFeeRecords() private{
        uint seconds_ = block.timestamp;
        uint days_ = seconds_ / 86400;
        uint day_ = days_ % 7;
        feeRecords.xProtocolFees[day_] = totalProtocolFeeX;
        feeRecords.yProtocolFees[day_] = totalProtocolFeeY;
        feeRecords.volumes[day_] = cumulativeVolume;
    }


    // Return all contract stats in one function
    function getStats() external view
        returns(StatsV1 memory){
        return StatsV1(
          concentration,
          feeMillionth,
          protocolFeeShareThousandth,
          totalProtocolFeeX,
          totalProtocolFeeY,
          cumulativeVolume,
          feeRecords,
          IBitcowERC20(xToken).balanceOf(address(this)),
          IBitcowERC20(yToken).balanceOf(address(this)),
          multX,
          multY,
          IBitcowERC20(lpToken).totalSupply()
        );

    }
    function pause() public onlyOwner{
        _pause();
    }
    function unpause() public onlyOwner{
        _unpause();
    }
    receive() external payable {

    }
}
