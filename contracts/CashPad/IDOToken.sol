pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract IDOToken is ERC20, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20("IDOToken", "IDO")
    {
        _mint(msg.sender, initialSupply);
    }
}
