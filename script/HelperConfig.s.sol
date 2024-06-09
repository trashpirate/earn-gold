// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    // chain configurations
    NetworkConfig public activeNetworkConfig;

    function getActiveNetworkConfigStruct()
        public
        view
        returns (NetworkConfig memory)
    {
        return activeNetworkConfig;
    }

    struct NetworkConfig {
        address dummy;
    }

    constructor() {
        if (block.chainid == 1 /** ethereum */) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 11155111 /** sepolia */) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function getLocalForkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }
}
