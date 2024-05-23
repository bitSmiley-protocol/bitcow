// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract BitcowLpToken is ERC20 {
    uint8 _decimals;
    address tradingPair;
    /**
        * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTradingPair() {
        require(tradingPair == msg.sender, "caller is not the tradingPair");
        _;
    }
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public onlyTradingPair{
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyTradingPair{
        super._burn(account, amount);
    }

    function setTradingPair(address tradingPair_) external{
        require(tradingPair == address(0), 'trading pair address must be empty while set it');
        tradingPair = tradingPair_;
    }
}
