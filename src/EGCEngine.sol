// SPDX-License Identifier: MIT
pragma solidity 0.8.20;

import {EarnGold} from "./EarnGold.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @title EarnGold
 * @author Nadina Oates
 *
 * The system is desinged to be as minimal as possible, and have the tokens maintain the gold price
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Gold Pegged
 * - Algorithmically stable
 *
 * The EGC systems should always be "overcollateralized". At no point, should the value of all collateral >= the $ backed value of all DSC
 * @notice This contract is the core of the EGC system. It handles all thelogic for mining and redeeming EGC, as well as depositing & withdrawing collteral
 * @notice This contract is VERY loolsely base on the MakerDAO DSS (DAI) system.
 */

contract EGCEngine is ReentrancyGuard {
    /**
     * State variables
     */
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    EarnGold private immutable i_egc;

    /**
     * Events
     */
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    /**
     * Errors
     */
    error EGCEngine__MustBeMoreThanZero();
    error EGCEngine__UnequalNumberOfTokenAndPriceFeedAddresses();
    error EGCEngine__TokenNotAllowed();
    error EGCEngine__TransferFailed();

    /**
     * Modifiers
     */
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert EGCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert EGCEngine__TokenNotAllowed();
        }
        _;
    }

    /**
     * Functions
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address egcAddress) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert EGCEngine__UnequalNumberOfTokenAndPriceFeedAddresses();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_egc = EarnGold(egcAddress);
    }

    /**
     * External Functions
     */
    function depositCollateralAndMintEGC() external {}

    /**
     * @notice follows CEI
     * @param tokenCollateralAddress The address fo the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        isAllowedToken(tokenCollateralAddress)
        moreThanZero(amountCollateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] = amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert EGCEngine__TransferFailed();
        }
    }

    /**
     */
    function redeemCollateralForDSC() external {}
    function redeemCollateral() external {}
    function mintDSC() external {}
    function burnDSC() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}
}
