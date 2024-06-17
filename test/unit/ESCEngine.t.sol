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
    uint256 DEPOSIT_AMOUNT = 1000 ether;

    // events
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    // modifiers
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    modifier funded(address account) {
        // fund user with eth
        deal(account, 10000 ether);
        ERC20Mock(weth).mint(USER, 10000 ether);
        ERC20Mock(wbtc).mint(USER, 10000 ether);
        _;
    }

    modifier minted(address account) {
        uint256 amount = 10000 ether;
        address owner = token.owner();

        vm.prank(owner);
        token.mint(USER, amount);
        _;
    }

    modifier deposited(address account) {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), DEPOSIT_AMOUNT);
        engine.depositCollateral(weth, DEPOSIT_AMOUNT);
        vm.stopPrank();
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

    function test__unit__ESCEngine__EmitEvent__DepositCollateral() public funded(USER) {
        uint256 amount = 200 ether;

        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), amount);

        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(USER, weth, amount);

        vm.prank(USER);
        engine.depositCollateral(weth, amount);
    }

    function test__unit__ESCEngine__RevertWhen__DepositCollateralIsZero() public funded(USER) {
        uint256 amount = 200 ether;

        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), amount);

        vm.expectRevert(ESCEngine.ESCEngine__MustBeMoreThanZero.selector);

        vm.prank(USER);
        engine.depositCollateral(weth, 0);
    }

    function test__unit__ESCEngine__RevertWhen__WrongToken() public funded(USER) {
        uint256 amount = 200 ether;
        address tokenAddress = makeAddr("token");

        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), amount);

        vm.expectRevert(ESCEngine.ESCEngine__TokenNotAllowed.selector);

        vm.prank(USER);
        engine.depositCollateral(tokenAddress, amount);
    }

    function test__unit__ESCEngine__RevertWhen__TransferFails() public funded(USER) {
        uint256 amount = 200 ether;

        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), amount);

        vm.mockCall(
            weth,
            abi.encodeWithSelector(ERC20Mock(weth).transferFrom.selector, USER, address(engine), amount),
            abi.encode(false)
        );
        vm.expectRevert(ESCEngine.ESCEngine__TransferFailed.selector);

        vm.prank(USER);
        engine.depositCollateral(weth, amount);
    }

    /**
     * Mint ESC
     */
    function test__unit__ESCEngine__MintESC() public funded(USER) deposited(USER) {
        uint256 amount = 100 ether;

        vm.prank(USER);
        engine.mintESC(amount);

        assertEq(amount, token.balanceOf(USER));
    }

    function test__unit__ESCEngine__RevertWhen__InsufficientHealthFactor() public funded(USER) deposited(USER) {
        uint256 amount = 700 ether;

        vm.prank(USER);
        engine.mintESC(amount);

        assertEq(amount, token.balanceOf(USER));
    }
}
