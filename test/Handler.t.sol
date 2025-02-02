// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralisedSTC} from "../src/DecentralisedSTC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";




contract Handler is Test {
    DSCEngine dsce;
    DecentralisedSTC dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

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

}

    function redeemCollateral (uint256 collateralseed , uint256 amountCollateralToRedeem) public {
        ERC20Mock collateral = _getCollatseed(collateralseed);
        uint256 maxCollateralToRedeem= dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateralToRedeem = bound(amountCollateralToRedeem,0,maxCollateralToRedeem);
        if(amountCollateralToRedeem==0){
            return ;
        }
        dsce.redeemCollateral(address(collateral), amountCollateralToRedeem);

    }

    function mintDsc(uint256 amount) public {
        amount = bound(amount,1,MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
    }



}