pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CashPrinter is ERC20, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20("CashPrinter", "CashP")
    {
        _mint(msg.sender, initialSupply);
    }
}
