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
    function depositCollateral(uint256 collateralseed , uint256 amountcollat) public {
        ERC20Mock collateral = _getCollatseed(collateralseed);

        dsce.depositCollateral(address(collateral) , amountcollat);
    }


}