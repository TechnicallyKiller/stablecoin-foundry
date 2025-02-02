// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralisedSTC} from "../src/DecentralisedSTC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {console} from "forge-std/console.sol";




contract Handler is Test {
    DSCEngine dsce;
    DecentralisedSTC dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public timeMintisCalled;
    address[] usersWithCollateralDeposited;

    constructor( DSCEngine _dsce , DecentralisedSTC _dsc) 
    {
     dsce= _dsce;
     dsc=_dsc;
     address[] memory collatTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collatTokens[0]);
        wbtc = ERC20Mock(collatTokens[1]);
    }

    function _getCollatseed(uint256 collatseed) internal view returns (ERC20Mock ){
        if(collatseed%2==0){
            return weth;
        }
        else {
            return wbtc;
        }
    }
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
    amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
    ERC20Mock collateral = _getCollatseed(collateralSeed);

    // mint and approve!
    vm.startPrank(msg.sender);
    collateral.mint(msg.sender, amountCollateral);
    collateral.approve(address(dsce), amountCollateral); 

    dsce.depositCollateral(address(collateral), amountCollateral);
    vm.stopPrank();

    usersWithCollateralDeposited.push(msg.sender);

}

    function redeemCollateral (uint256 collateralseed , uint256 amountCollateralToRedeem) public {
        ERC20Mock collateral = _getCollatseed(collateralseed);
        uint256 maxCollateralToRedeem= dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateralToRedeem = bound(amountCollateralToRedeem,0,maxCollateralToRedeem);
        if(amountCollateralToRedeem==0){
            return ;
        }
        console.log("Collateral Type:", address(collateral));
console.log("User's Max Collateral:", maxCollateralToRedeem);
console.log("Requested Collateral Redemption:", amountCollateralToRedeem);

        dsce.redeemCollateral(address(collateral), amountCollateralToRedeem);

    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        address sender = usersWithCollateralDeposited[addressSeed% usersWithCollateralDeposited.length];
        console.log("Minting DSC:", amount);

        if(usersWithCollateralDeposited.length ==0){
            return;
        }

        (uint256 totalDscMinted , uint256 collateralvalueinUsd)= dsce.getinfo(msg.sender);
        uint256 maxDscToMint = (collateralvalueinUsd/2)-totalDscMinted;
        if(maxDscToMint<0){
            return;
        }
         vm.startPrank(sender);
        amount = bound(amount,0,maxDscToMint);
        if(amount==0){
            return;
        }
        dsce.mintDsc(amount);
    
        vm.stopPrank();

        timeMintisCalled++;
    }



}