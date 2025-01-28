// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin
import {DecentralisedSTC} from "./DecentralisedSTC.sol";
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
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
error DSCEngine_BreakHealthFactor(uint256 userHealthFac);
error DSCEngine_failedMint();
error DSCEngine_HealthFactorOKK();
error DSCEngine_HealtHFactorNotImproved();

///////////////////
//  State Variables  //
///////////////////

mapping(address token => address pricefeed) private s_priceFeed;
mapping(address user => mapping(address token => uint256 amount)) private s_collatDeposited;
mapping(address user=> uint256 amounttoMint) private s_amountToMint;
mapping(address user => uint256 DSCMinted) private s_DSCMinted;
DecentralisedSTC private i_dsc; //token to pricefeed
address[] private s_collateralTokens;

uint256 private LIQUIDATION_THRESHOLD =50;//200% COLLATERISED
uint256 private LIQUIDATION_PRECISION=100;
uint256 private MIN_HEALTH_FACTOR=1;
uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
uint256 private constant PRECISION = 1e18;
uint256 private constant LIQUIDATION_BONUS=10;




///////////////////
//   EVENTS  //
///////////////////

event CollateralDeposited(address indexed depositor , address indexed token , uint256 deposited);
event CollatRedeem(address indexed from ,address indexed to , address indexed token , uint256 amount);


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
///////////////////////////////////////////
//   Private & Internal View Functions   //
///////////////////////////////////////////

function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to) private {
    s_collatDeposited[from][tokenCollateralAddress] -= amountCollateral;
    emit CollatRedeem(from, to , tokenCollateralAddress, amountCollateral);

    bool success = IERC20(tokenCollateralAddress).transfer( to, amountCollateral);
    if(!success){
        revert DSCEngine_transferFailed();
    }
}
function _burnDsc(uint256 DsctoBeBurned, address onBehalfof , address dscFrom) private{
     s_DSCMinted[onBehalfof]-=DsctoBeBurned;
        bool success = i_dsc.transferFrom(dscFrom,address(this),DsctoBeBurned);
        if(!success){
            revert DSCEngine_transferFailed();
        }
        i_dsc.burn(DsctoBeBurned);
}

///////////////////////////
//   External Functions  //
///////////////////////////
    
    /*
    * @param tokenCollateralAddress the address of token to deposit as collateral
    * @param amountCollateral  the amount to deposit
    * 
    */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) public morethanZero(amountCollateral)
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

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollat , uint256 DscToBurn) external {
        burnDsc(DscToBurn);
        redeemCollateral(tokenCollateralAddress,amountCollat);
    }

    /*
    * TWO STEP FUNC (BURN DSC -> REDEEM COLLAT)
    * ALSO NEED TO CHECK HEALTHFACTOR ABOVE 1 AFTER COLLAT REDEEMED
    */

    function redeemCollateral(address tokenCollateralAddress,uint256 amountCollat) public nonReentrant morethanZero(amountCollat) {
        _redeemCollateral( tokenCollateralAddress, amountCollat, msg.sender, msg.sender);
        _revertifHealthFactorisBroken(msg.sender);



    }

    /*
    * @notice follows CEI
    * @params amountToMintDSC the amount of decentralised stable coin to mint
    * @notice they must have more collateral value than the threshold
    */

    function mintDsc(uint256 amountToMintDSC) public morethanZero(amountToMintDSC) nonReentrant {
        s_DSCMinted[msg.sender]+=amountToMintDSC;
        _revertifHealthFactorisBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountToMintDSC);

        if(!minted){
            revert DSCEngine_failedMint();
        }
        
    }

    function depositCollaterAndMintDsc(address tokenCollatAddress , uint256 amountCollateral, uint256 amountDsctoMint) external {
        depositCollateral(tokenCollatAddress,amountCollateral);
        mintDsc(amountDsctoMint);
    }

    function burnDsc(uint256 DscAmount) public nonReentrant morethanZero(DscAmount){
        _burnDsc(DscAmount,msg.sender, msg.sender);
        _revertifHealthFactorisBroken(msg.sender);
    }
   /*
* @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
* This is collateral that you're going to take from the user who is insolvent.
* In return, you have to burn your DSC to pay off their debt, but you don't pay off your own.
* @param user: The user who is insolvent. They have to have a _healthFactor below MIN_HEALTH_FACTOR
* @param debtToCover: The amount of DSC you want to burn to cover the user's debt.
*
* @notice: You can partially liquidate a user.
* @notice: You will get a 10% LIQUIDATION_BONUS for taking the users funds.
* @notice: This function working assumes that the protocol will be roughly 200% overcollateralized in order for this
to work.
* @notice: A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to liquidate
anyone.
* For example, if the price of the collateral plummeted before anyone could be liquidated.
*/
function liquidate(address collateral, address user, uint256 debtToCover) external morethanZero(debtToCover) nonReentrant {
    uint256 startingHealthFactor = _HealthFactor(user);
    if(startingHealthFactor>MIN_HEALTH_FACTOR){
        revert DSCEngine_HealthFactorOKK();
    }
    // we need to burn their Dsc Debt
    // and take their Collat
    // bad user : 130$ ETH AND 100$ DSC
    // DEBT TO COVER 100$ 
    // 100$ OF DSC == ?? $ETH?
    uint256 tokeAmounttoBeCovered = getTokenAmountfromUSD(collateral, debtToCover);
    // give liquidators 10% bonus
    // we give 110$ of ETH for 100$ DSC
    // SWEEP EXTRA AMOUNTS INTO A TREASURY
    uint256 bonusProtocol = (tokeAmounttoBeCovered * LIQUIDATION_BONUS)/LIQUIDATION_PRECISION;
    uint256 tokenCollatRedeemed = bonusProtocol+tokeAmounttoBeCovered;
    _redeemCollateral(collateral,tokenCollatRedeemed,user, msg.sender);
    _burnDsc(debtToCover,user,msg.sender);

    uint256  endingHealthFac= _HealthFactor(user);
    if(endingHealthFac<=startingHealthFactor){
        revert DSCEngine_HealtHFactorNotImproved();
    }
    _revertifHealthFactorisBroken(msg.sender);    

}

    function getHealthFactor() external view {}

    ///////////////////////////
    //    Internal Functions  //
    ///////////////////////////
    function _getinfo(address user) private view returns(uint256 totalDscMinted , uint256 collateralvalueinUsd){
        uint256 totalDscMinted1= s_DSCMinted[user];
        uint collateralvalueinUsd1 = getAccountCollateralValue(user);
        return (totalDscMinted1,collateralvalueinUsd1);

    }
    function _calcHealthFac(uint256 DSC_MINTED, uint256 totalCollatDep) internal view returns(uint256 healthfac){
        if(DSC_MINTED==0) return type(uint256).max;

        uint256 collatAdjustedforThres= (totalCollatDep*LIQUIDATION_THRESHOLD)/LIQUIDATION_PRECISION;
        return (collatAdjustedforThres* 1e18 /DSC_MINTED);
    }

    function _HealthFactor(address user) internal view returns(uint256){
        // total dsc minted , total collateral value
        (uint256 totalDscMinted , uint256 collateralvalueInUSD)=_getinfo(user);
       return(
        _calcHealthFac(totalDscMinted,collateralvalueInUSD)
       );
    }

    function _revertifHealthFactorisBroken (address user) internal view{
        // check if they have enough collateral(health factor)
        // revert if they dont
        uint256 userHealthfactor= _HealthFactor(user);
        if(userHealthfactor< MIN_HEALTH_FACTOR){
            revert DSCEngine_BreakHealthFactor(userHealthfactor);
        }

    }
        //////////////////////////////////////////
    //   Public & External View Functions   //
    //////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
         for(uint256 i = 0; i < s_collateralTokens.length; i++){
        address token = s_collateralTokens[i];
        uint256 amount = s_collatDeposited[user][token];
        totalCollateralValueInUsd += getUsdValue(token,amount);
           }
        return totalCollateralValueInUsd;
        }

    
    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
    (, int256 price,,,) = priceFeed.latestRoundData();
    // Both price and amount have 18 decimals, so we divide by 1e18
    return ((uint256(price) * 1e10) * amount) / 1e18; // Scale price to 18 decimals
}
    function getPriceFeed(address token) public view returns (address) {
    return s_priceFeed[token];
}
    function getTokenAmountfromUSD(address tokenCollat, uint256 usdAmountinWei) public view returns(uint256 tokenAmountUSD) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(s_priceFeed[tokenCollat]);
        (, int256 price ,,,)=pricefeed.latestRoundData();
        return
            (usdAmountinWei*PRECISION)/(uint256(price)*ADDITIONAL_FEED_PRECISION);



    }

    
    function getinfo( address user) external view returns(uint256 totalDscMinted , uint256 collateralvalueinUsd){
        (totalDscMinted,collateralvalueinUsd)= _getinfo(user);
        return(totalDscMinted, collateralvalueinUsd);

    }

}