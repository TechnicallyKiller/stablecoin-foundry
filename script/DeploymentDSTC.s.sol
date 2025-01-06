// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DecentralisedSTC} from "../src/DecentralisedSTC.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploymentDSTC is Script{
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralisedSTC, DSCEngine, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();
    
    // Fix the order to match NetworkConfig struct
    (address wbtc, address weth, address wethUsdPriceFeed, address wbtcUsdPriceFeed, uint256 deployerKey) =
        helperConfig.activeConfig();
        
    tokenAddresses = [weth, wbtc];
    priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

    vm.startBroadcast(deployerKey);
    DecentralisedSTC dsc = new DecentralisedSTC();
    DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    dsc.transferOwnership(address(dscEngine));
    vm.stopBroadcast();
    return (dsc, dscEngine, helperConfig);
}
}