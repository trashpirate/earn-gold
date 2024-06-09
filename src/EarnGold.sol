// SPDX-License Identifier: MIT

pragma solidity 0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EarnGold
 * @author Nadina Oates
 * Collateral: Exogenous (ETH, BTC, EARN)
 * Minting: Algorithmic
 * Relative Stability: Pegged to Gold
 *
 * This is the contract meant to be governed by EGEngine. This contract is just the ERC20 implementation of the stablecoin system.
 */
contract EarnGold is ERC20Burnable, Ownable {
    error EarnGold__MustBeMoreThanZero();
    error EarnGold__BurnAmountExceedsBalance();
    error EarnGold__NotZeroAddress();

    constructor() ERC20("EarnGold", "EG") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert EarnGold__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert EarnGold__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert EarnGold__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert EarnGold__MustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
