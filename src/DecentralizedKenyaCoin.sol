// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.22;

/**
 *  @title DescentralizedKenyaCoin
 *  @author c0deg33k
 *  collateral: Exogenious {BTC & ETH}
 *  Minting: Algorithmic
 *  Relative stability: Pegged to USD
 *
 *  This is a contract meant to be governed by DKCEngine. This is just the ERC20 implementation of our stablecoin system
 */
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedKenyaCoin is ERC20Burnable, Ownable {
    //Errors
    error DecentralizedKenyaCoin__AmountMustBeMoreThanZero();
    error DecentralizedKenyaCoin__AmountMustBeMoreThanBalance();
    error DecentralizedKenyaCoin__AddressCantBeZeroAddress();

    // TODO: change ownable address before deploying
    constructor(address owner) ERC20("DecentralizedKenyaCoin", "DKC") Ownable(owner) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 userBalance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedKenyaCoin__AmountMustBeMoreThanZero();
        }
        if (userBalance < _amount) {
            revert DecentralizedKenyaCoin__AmountMustBeMoreThanBalance();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedKenyaCoin__AddressCantBeZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedKenyaCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
