// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ESCEngine} from "./../src/ESCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployESC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (ESCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address ethUsdPriceFeed, address btcUsdPriceFeed, address weth, address wbtc) = config.activeNetworkConfig();

        priceFeedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];
        tokenAddresses = [weth, wbtc];

        vm.startBroadcast();
        ESCEngine escEngine = new ESCEngine(tokenAddresses, priceFeedAddresses);
        vm.stopBroadcast();

        return (escEngine, config);
    }
}
