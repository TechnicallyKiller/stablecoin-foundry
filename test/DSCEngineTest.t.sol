// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeploymentDSTC} from "../script/DeploymentDSTC.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralisedSTC} from "../src/DecentralisedSTC.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Layout of Contract:
//  struct NetworkConfig {
//         address wbtc;
//         address weth;
//         address wethUSDpricefeed;
//         address wbtcUSDpricefeed;
//         uint256 deployerKey;
//     }

contract DSCEngineTest is Test {
    DeploymentDSTC deployer;
    DecentralisedSTC dsc;
    DSCEngine dscEngine;
    HelperConfig config;
    address weth;
    address wethUsdfeed;
    address wbtc;
    address wbtcUSDpriceFeed;
    address[] public TokenAddresses;
    address[] public PriceFeedAddresses;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ACCOUNT_BAL=10 ether;

    function setUp() public {
        deployer = new DeploymentDSTC();
        (dsc,dscEngine,config)= deployer.run();
        (wbtc,weth,wethUsdfeed,wbtcUSDpriceFeed,)=config.activeConfig();
        ERC20Mock(weth).mint(USER,STARTING_ACCOUNT_BAL);
        
    }
     /////////////////
    // Constructor Tests //
    /////////////////


    function testRevertifTokenLnDoesntMatchPriceFeeds() public {
        TokenAddresses.push(weth);
        PriceFeedAddresses.push(wethUsdfeed);
        PriceFeedAddresses.push(wbtcUSDpriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine_pricefeedaddresss_Notequal_tokenaddress_length.selector);
        new DSCEngine(TokenAddresses,PriceFeedAddresses,address(dsc));
    }


     /////////////////
    // Price Tests //
    /////////////////
    function testGetUsdValue() public view  {
    // Add debug logs
    console.log("WETH  :", weth);
    console.log("WETH/USD Price Feed address:", wethUsdfeed);
    
    // Get price feed mapping value
    AggregatorV3Interface priceFeed = AggregatorV3Interface(dscEngine.getPriceFeed(weth));
    console.log("Price Feed from mapping:", address(priceFeed));
    
    uint256 ethAmount = 15e18;
    uint256 expectedUsd = 30000e18;
    uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
    assertEq(expectedUsd, actualUsd);
}

    function testGetUsdValuefromToken() public view {

        uint256 usdAmount = 100 ether;
        uint256 expectedWeth= 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountfromUSD(weth,usdAmount);
        assertEq(expectedWeth,actualWeth);
    }

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine),AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine_lessthanZero.selector);
        dscEngine.depositCollateral(weth,0);
        vm.stopPrank();
    }
    
    function testRevertswithUnapprovedCollat() public{
        ERC20Mock RANToken = new ERC20Mock("RAN", "RAN", USER , AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_NOTallowedToken.selector);
        dscEngine.depositCollateral(address(RANToken),AMOUNT_COLLATERAL);
        vm.stopPrank();
    }
    modifier depositCollateral {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine),AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;

        
    }


    function testCanDepositCollateralandGetAccInfo() public depositCollateral{
        (uint256 collateral , uint256 debt)=dscEngine.getinfo(USER);
    }
        
    


}