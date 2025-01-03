// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin
import {DecentralisedSTC} from "./DecentralisedSTC.sol";
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
contract DSCEngine is ReentrancyGuard {
///////////////////
//   Errors  //
///////////////////
error DSCEngine_lessthanZero();
error DSCEngine_NOTallowedToken();
error DSCEngine_pricefeedaddresss_Notequal_tokenaddress_length();
error DSCEngine_transferFailed();

///////////////////
//  State Variables  //
///////////////////

mapping(address token => address pricefeed) private s_priceFeed;
mapping(address user => mapping(address token => uint256 amount)) private s_collatDeposited;
mapping(address user=> uint256 amounttoMint) private s_amountToMint;
mapping(address user => uint256 DSCMinted) private s_DSCMinted;
DecentralisedSTC private i_dsc; //token to pricefeed
address[] private s_collateralTokens;

///////////////////
//   EVENTS  //
///////////////////

event CollateralDeposited(address indexed depositor , address indexed token , uint256 deposited);


///////////////////
//   Modifiers  //
///////////////////

modifier morethanZero(uint256 amount) {
    if(amount==0){
        revert DSCEngine_lessthanZero();
    }
    _;
}

modifier isAllowedToken(address token) {
   if(s_priceFeed[token]==address(0)){
    revert DSCEngine_NOTallowedToken();
   } 
   _;
}


///////////////////
//   Functions   //
///////////////////

constructor(address[] memory tokenAdresses, address[] memory pricefeedAddressess, address DscAddress){
    if(tokenAdresses.length!=pricefeedAddressess.length){
        revert DSCEngine_pricefeedaddresss_Notequal_tokenaddress_length();
    }
    for(uint256 i=0;i< tokenAdresses.length;i++){
        s_priceFeed[tokenAdresses[i]]=pricefeedAddressess[i];
        s_collateralTokens.push(tokenAdresses[i]);
    }
    i_dsc= DecentralisedSTC(DscAddress);

}

///////////////////////////
//   External Functions  //
///////////////////////////
    function depositCollaterAndMintDsc() external {}
    /*
    * @param tokenCollateralAddress the address of token to deposit as collateral
    * @param amountCollateral  the amount to deposit
    * 
    */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) external morethanZero(amountCollateral)
            isAllowedToken(tokenCollateralAddress)
            nonReentrant
     {
        s_collatDeposited[msg.sender] [tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
       bool success =  IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this),amountCollateral);
       if(!success){
            revert DSCEngine_transferFailed();
       }

    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    /*
    * @notice follows CEI
    * @params amountToMintDSC the amount of decentralised stable coin to mint
    * @notice they must have more collateral value than the threshold
    */

    function mintDsc(uint256 amountToMintDSC) external morethanZero(amountToMintDSC) nonReentrant {

    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ///////////////////////////
    //    Internal Functions  //
    ///////////////////////////
    function _getinfo(address user) private view returns(uint256 totalDscMinted , uint256 collateralvalueinUsd){
        uint256 totalDscMinted= s_DSCMinted[user];

    }

    function _HealthFactor(address user) internal view returns(uint256){
        // total dsc minted , total collateral value
        (uint256 totalDscMinted , uint256 collateralvalueInUSD)=_getinfo(user);

    }

    function _revertifHealthFactorisBroken (address user) internal view{
        // check if they have enough collateral(health factor)
        // revert if they dont
    }
    //////////////////////////////////////////
//   Public & External View Functions   //
//////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
         for(uint256 i = 0; i < s_collateralTokens.length; i++){
        address token = s_collateralTokens[i];
        uint256 amount = s_collatDeposited[user][token];
        totalCollateralValueInUsd += amount;
           }
        return totalCollateralValueInUsd;
        }



}