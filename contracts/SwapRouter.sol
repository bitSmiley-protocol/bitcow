// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./interface/ISsTradingPair.sol";
import {IBitcowERC20} from "./interface/IBitcowERC20.sol";
import "./interface/IWBTC.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";


contract SwapRouter is Ownable2StepUpgradeable, PausableUpgradeable{
    function initialize() public initializer{
        __Ownable2Step_init();
        __Ownable_init(msg.sender);
        __Pausable_init();
    }
    function approve(address token, address spender) public{
        IBitcowERC20(token).approve(spender, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }
    function increaseAllowance(address token, uint256 addedValue, address spender) external onlyOwner returns (bool){
        return IBitcowERC20(token).increaseAllowance(spender, addedValue);
    }
    function swapInternal(address[] memory pools, bool[] memory isXtoYs, uint256 inputAmount) private returns(uint256) {
        uint poolLength = pools.length;
        for(uint i = 0; i < poolLength; i++){
            if (isXtoYs[i]){
                (inputAmount) = ISsTradingPair(pools[i]).swapXtoY(inputAmount);
            } else {
                (inputAmount) = ISsTradingPair(pools[i]).swapYtoX(inputAmount);
            }
        }
        return (inputAmount);
    }
    function swap(uint256 inputAmount, address[] memory pools, bool[] memory isXtoYs, uint256 minOutputAmount) public whenNotPaused returns(uint256){
        address inputToken;
        if (isXtoYs[0]){
            inputToken = ISsTradingPair(pools[0]).xToken();
        } else {
            inputToken = ISsTradingPair(pools[0]).yToken();
        }
        IBitcowERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);

        (uint256 outputAmount) = swapInternal(pools, isXtoYs, inputAmount);
        require(outputAmount >= minOutputAmount, 'Output amount less than min output amount');
        uint lastIndex = pools.length - 1;
        address outputToken;
        if (isXtoYs[lastIndex]){
            outputToken = ISsTradingPair(pools[lastIndex]).yToken();
        } else {
            outputToken = ISsTradingPair(pools[lastIndex]).xToken();
        }

        IBitcowERC20(outputToken).transfer(msg.sender, outputAmount);
        return (outputAmount);
    }
    function swapBTCtoERC20(address[] memory pools, bool[] memory isXtoYs, uint256 minOutputAmount) public whenNotPaused payable returns(uint256) {
        address inputToken;
        if (isXtoYs[0]){
            inputToken = ISsTradingPair(pools[0]).xToken();
        } else {
            inputToken = ISsTradingPair(pools[0]).yToken();
        }
        IWBTC(inputToken).deposit{value: msg.value}();

        (uint256 outputAmount) = swapInternal(pools, isXtoYs, msg.value);
        require(outputAmount >= minOutputAmount, 'Output amount less than min output amount');

        uint lastIndex = pools.length - 1;
        address outputToken;
        if (isXtoYs[lastIndex]){
            outputToken = ISsTradingPair(pools[lastIndex]).yToken();
        } else {
            outputToken = ISsTradingPair(pools[lastIndex]).xToken();
        }
        IBitcowERC20(outputToken).transfer(msg.sender, outputAmount);
        return (outputAmount);
    }
    function swapERC20toBTC(uint256 inputAmount, address[] memory pools, bool[] memory isXtoYs, uint256 minOutputAmount) public returns(uint256){
        address inputToken;
        if (isXtoYs[0]){
            inputToken = ISsTradingPair(pools[0]).xToken();
        } else {
            inputToken = ISsTradingPair(pools[0]).yToken();
        }
        IBitcowERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);

        (uint256 outputAmount) = swapInternal(pools, isXtoYs, inputAmount);
        require(outputAmount >= minOutputAmount, 'Output amount less than min output amount');
        uint lastIndex = pools.length - 1;
        address outputToken;
        if (isXtoYs[lastIndex]){
            outputToken = ISsTradingPair(pools[lastIndex]).yToken();
        } else {
            outputToken = ISsTradingPair(pools[lastIndex]).xToken();
        }
        IWBTC(outputToken).withdraw(outputAmount);
        payable(msg.sender).transfer(outputAmount);
        return (outputAmount);
    }

    function swapERC20toBTCV2(uint256 inputAmount, address[] memory pools, bool[] memory isXtoYs, uint256 minOutputAmount) public returns(uint256){
        address inputToken;
        if (isXtoYs[0]){
            inputToken = ISsTradingPair(pools[0]).xToken();
        } else {
            inputToken = ISsTradingPair(pools[0]).yToken();
        }
        IBitcowERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);

        (uint256 outputAmount) = swapInternal(pools, isXtoYs, inputAmount);
        require(outputAmount >= minOutputAmount, 'Output amount less than min output amount');
        uint lastIndex = pools.length - 1;
        address outputToken;
        if (isXtoYs[lastIndex]){
            outputToken = ISsTradingPair(pools[lastIndex]).yToken();
        } else {
            outputToken = ISsTradingPair(pools[lastIndex]).xToken();
        }
        IWBTC(outputToken).withdrawTo(msg.sender, outputAmount);
        return (outputAmount);
    }

    function swapBTCtoWBTC(address wbtc) public payable{
        IWBTC(wbtc).deposit{value: msg.value}();
        IBitcowERC20(wbtc).transfer(msg.sender, msg.value);
    }

    function swapWBTCtoBTC(address wbtc, uint256 amount) public{
        IBitcowERC20(wbtc).transferFrom(msg.sender, address(this), amount);
        IWBTC(wbtc).withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    function swapBTCtoWBTCV2(address wbtc) public payable {
        IWBTC(wbtc).depositTo{value: msg.value}(msg.sender);
    }

    function swapWBTCtoBTCV2(address wbtc, uint256 amount) public{
        IBitcowERC20(wbtc).transferFrom(msg.sender, address(this), amount);
        IWBTC(wbtc).withdrawTo(msg.sender, amount);
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
