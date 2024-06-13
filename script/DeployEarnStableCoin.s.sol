// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {EarnStableCoin} from "./../src/EarnStableCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEarnStableCoin is Script {
    function run() external returns (EarnStableCoin) {
        vm.startBroadcast();
        EarnStableCoin token = new EarnStableCoin();
        vm.stopBroadcast();
        return token;
    }
}
