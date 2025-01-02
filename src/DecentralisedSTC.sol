// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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

/*
* @title: DecentralisedSTC
* @author: DivK
* @ Collateral : EXOGENOUS (ETH & BTC)
* Minting : Algorithmic
* Relative Stability : Pegged to  USD
* Governed  by DSCEngine : Just Implementation of ERC20 Contract
*/
 
 contract DecentralisedSTC is ERC20Burnable,Ownable{
    error DSTC_MUST_BE_MORE_THAN_ZERO();
    error DSTC_ExceedsBurnAmount();
    error DSTC_NotZeroAddress();
     constructor() ERC20 ("DecentralisedSTC1","DSTC"){}

     function burn(uint256 _amount) public override onlyOwner{
        uint256 balance = balanceOf(msg.sender);
        if(_amount <=0){
            revert DSTC_MUST_BE_MORE_THAN_ZERO();
        }
        if(_amount>=balance){
            revert DSTC_ExceedsBurnAmount();
        }
        super.burn(_amount);
     }
     function mint(address _to , uint256 amount) external onlyOwner returns(bool){
        if(_to==address(0)){
            revert DSTC_NotZeroAddress();
        }
        if(amount<=0){
            revert DSTC_MUST_BE_MORE_THAN_ZERO();
        }
        _mint(_to,amount);
        return true;
     }
 }