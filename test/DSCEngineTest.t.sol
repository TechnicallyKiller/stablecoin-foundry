// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeploymentDSTC} from "../script/DeploymentDSTC.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralisedSTC} from "../src/DecentralisedSTC.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Layout of Contract:


contract DSCEngineTest is Test {
    DeploymentDSTC deployer;
    DecentralisedSTC dsc;
    DSCEngine dscEngine;
    HelperConfig config;
    address weth;
    address wethUsdfeed;

    function setUp() public {
        deployer = new DeploymentDSTC();
        (dsc,dscEngine,config)= deployer.run();
        (,weth,wethUsdfeed,,)=config.activeConfig();
        
    }

        /////////////////
    // Price Tests //
    /////////////////
    function testGetUsdValue() public {
    // Add debug logs
    console.log("WETH address:", weth);
    console.log("WETH/USD Price Feed address:", wethUsdfeed);
    
    // Get price feed mapping value
    AggregatorV3Interface priceFeed = AggregatorV3Interface(dscEngine.getPriceFeed(weth));
    console.log("Price Feed from mapping:", address(priceFeed));
    
    uint256 ethAmount = 15e18;
    uint256 expectedUsd = 30000e18;
    uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
    assertEq(expectedUsd, actualUsd);
}


}