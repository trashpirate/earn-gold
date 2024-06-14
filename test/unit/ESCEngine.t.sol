// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EarnStableCoin} from "./../../src/EarnStableCoin.sol";
import {ESCEngine} from "./../../src/ESCEngine.sol";
import {DeployESC} from "./../../script/DeployESC.s.sol";
import {HelperConfig} from "./../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract EarnStableCoin__UnitTest is Test {
    // configuration
    DeployESC deployment;
    HelperConfig helperConfig;

    // contracts
    ESCEngine engine;
    EarnStableCoin token;

    // helper config
    address weth;
    address wbtc;

    // helpers
    address USER = makeAddr("user");

    // modifiers
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    modifier funded(address account) {
        // fund user with eth
        deal(account, 1000 ether);
        ERC20Mock(weth).mint(USER, 1000 ether);
        ERC20Mock(wbtc).mint(USER, 1000 ether);
        _;
    }

    modifier minted(address account) {
        uint256 amount = 1000 ether;
        address owner = token.owner();

        vm.prank(owner);
        token.mint(USER, amount);
        _;
    }

    function setUp() external virtual {
        deployment = new DeployESC();
        (engine, helperConfig) = deployment.run();
        token = EarnStableCoin(engine.getESCAddress());

        (,, weth, wbtc) = helperConfig.activeNetworkConfig();
    }

    /**
     * INITIALIZATION
     */
    function test__unit__ESCEngine__Initialization() public view {
        assertEq(token.name(), "EarnStableCoin");
        assertEq(token.symbol(), "ESC");
        assertEq(token.decimals(), 18);
    }

    /**
     * Price Feed
     */
    function test__unit__ESCEngine__GetUsdValue() public view {
        uint256 ethPrice = uint256(helperConfig.ETH_USD_PRICE());

        uint256 ethAmount = 15e18;
        uint256 expectedUsdValue = ethAmount * ethPrice / 1e8; // 52500e18 = 15 * 3500
        uint256 actualUsdValue = engine.getUsdValue(weth, ethAmount);

        assertEq(expectedUsdValue, actualUsdValue);
    }

    /**
     * Deposit Collateral
     */
    function test__unit__ESCEngine__DepositCollateral() public funded(USER) {
        uint256 amount = 200 ether;

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), amount);
        engine.depositCollateral(weth, amount);
        vm.stopPrank();

        assertEq(amount, ERC20Mock(weth).balanceOf(address(engine)));
    }

    function test__unit__ESCEngine__RevertWhen__DepositCollateralIsZero() public funded(USER) {
        uint256 amount = 200 ether;

        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), amount);

        vm.expectRevert(ESCEngine.ESCEngine__MustBeMoreThanZero.selector);

        vm.prank(USER);
        engine.depositCollateral(weth, 0);
    }
}
