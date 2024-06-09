// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {EarnGold} from "./../src/EarnGold.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEarnGold is Script {
    function run() external returns (EarnGold) {
        vm.startBroadcast();
        EarnGold token = new EarnGold();
        vm.stopBroadcast();
        return token;
    }
}
