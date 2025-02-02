// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeploymentDSTC} from "../script/DeploymentDSTC.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DecentralisedSTC} from "../src/DecentralisedSTC.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";
import {Handler} from "./Handler.t.sol";


contract InvariantTest is StdInvariant, Test {
    // Layout of Contract:
//  struct NetworkConfig {
//         address wbtc;
//         address weth;
//         address wethUSDpricefeed;
//         address wbtcUSDpricefeed;
//         uint256 deployerKey;
//     }

    DeploymentDSTC deployer;
    DSCEngine dsce;
    DecentralisedSTC dsc;
    HelperConfig config;
    Handler handler;
    address wbtc;
    address weth;

    function setUp() external {
    console.log("Starting Deployment...");
    deployer = new DeploymentDSTC();
    (dsc, dsce, config) = deployer.run();
    console.log("Deployment Finished.");


   (wbtc, weth, ,,) = config.activeConfig();
     // Ensure dsce has WETH and WBTC
    // deal(weth, address(dsce), 10e18);
    // deal(wbtc, address(dsce), 5e8);
    console.log("WETH Address:", weth);
    console.log("WBTC Address:", wbtc);
    console.log("DSCE Address:", address(dsce));
    console.log("DSC Address:", address(dsc));

    handler = new Handler(dsce, dsc);
    targetContract(address(handler));
}


    function invariant_protocolMusthaveMoreValueThanTotalSupply() public view{
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDep= IERC20(weth).balanceOf(address(dsce));
        uint256 totalwbtcDep=IERC20(wbtc).balanceOf(address(dsce));
        uint256 wethValue = dsce.getUsdValue(weth, totalWethDep);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalwbtcDep);

        console.log("Total WETH Deposited:", totalWethDep);
        console.log("Total WBTC Deposited:", totalwbtcDep);
        console.log("WETH Value in USD:", wethValue);
        console.log("WBTC Value in USD:", wbtcValue);
        console.log("Total DSC Supply:", totalSupply);
        console.log("Times Mint called: ", handler.timeMintisCalled());


        assert(wethValue + wbtcValue >= totalSupply);
    }
}