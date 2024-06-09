// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EarnGold} from "./../../src/EarnGold.sol";
import {DeployEarnGold} from "./../../script/DeployEarnGold.s.sol";
import {HelperConfig} from "./../../script/HelperConfig.s.sol";

contract EarnGold__UnitTest is Test {
    // configuration
    DeployEarnGold deployment;
    HelperConfig helperConfig;

    // contracts
    EarnGold token;

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
        deployment = new DeployEarnGold();
        token = deployment.run();
    }

    /** INITIALIZATION */
    function test__unit__EarnGold__Initialization() public view {
        assertEq(token.name(), "EarnGold");
        assertEq(token.symbol(), "EG");
        assertEq(token.decimals(), 18);
    }

    /** MINT TOKENS */
    function test__unit__EarnGold__Mint() public {
        uint256 amount = 1000 ether;
        address owner = token.owner();

        vm.prank(owner);
        token.mint(USER, amount);

        assertEq(token.balanceOf(USER), amount);
    }

    function test__unit__EarnGold__RevertsWehn__MintZeroAmount() public {
        address owner = token.owner();

        vm.expectRevert(EarnGold.EarnGold__MustBeMoreThanZero.selector);

        vm.prank(owner);
        token.mint(USER, 0);
    }

    function test__unit__EarnGold__RevertsWehn__MintToZeroAddress() public {
        address owner = token.owner();

        vm.expectRevert(EarnGold.EarnGold__NotZeroAddress.selector);

        vm.prank(owner);
        token.mint(address(0), 1000 ether);
    }

    /** BURN TOKENS */
    function test__unit__EarnGold__Burn() public {
        uint256 mintAmount = 100 ether;
        uint256 burnAmount = 30 ether;
        address owner = token.owner();

        // fund contract
        vm.prank(owner);
        token.mint(owner, mintAmount);
        assertEq(token.balanceOf(owner), mintAmount);

        // burn tokens
        vm.prank(owner);
        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), mintAmount - burnAmount);
    }

    function test__unit__EarnGold__RevertsWehn__BurnZeroAmount() public {
        uint256 mintAmount = 100 ether;
        address owner = token.owner();

        // fund contract
        vm.prank(owner);
        token.mint(owner, mintAmount);
        assertEq(token.balanceOf(owner), mintAmount);

        // test revert
        vm.expectRevert(EarnGold.EarnGold__MustBeMoreThanZero.selector);

        // burn tokens
        vm.prank(owner);
        token.burn(0);
    }

    function test__unit__EarnGold__RevertsWehn__BurnTooManyTokens() public {
        uint256 mintAmount = 100 ether;
        uint256 burnAmount = 110 ether;
        address owner = token.owner();

        // fund contract
        vm.prank(owner);
        token.mint(owner, mintAmount);
        assertEq(token.balanceOf(owner), mintAmount);

        // test revert
        vm.expectRevert(EarnGold.EarnGold__BurnAmountExceedsBalance.selector);

        // burn tokens
        vm.prank(owner);
        token.burn(burnAmount);
    }
}
