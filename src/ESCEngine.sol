// SPDX-License Identifier: MIT
pragma solidity 0.8.20;

import {EarnStableCoin} from "./EarnStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title EarnStableCoin
 * @author Nadina Oates
 *
 * The system is desinged to be as minimal as possible, and have the tokens maintain the gold price
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Gold Pegged
 * - Algorithmically stable
 *
 * The ESC systems should always be "overcollateralized". At no point, should the value of all collateral >= the $ backed value of all ESC
 * @notice This contract is the core of the ESC system. It handles all thelogic for mining and redeeming ESC, as well as depositing & withdrawing collteral
 * @notice This contract is VERY loolsely base on the MakerDAO DSS (DAI) system.
 */
contract ESCEngine is ReentrancyGuard {
    /**
     * State variables
     */
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountMinted) private s_minted;

    address[] private s_collateralTokens;

    EarnStableCoin private immutable i_esc;

    /**
     * Events
     */
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    /**
     * Errors
     */
    error ESCEngine__MustBeMoreThanZero();
    error ESCEngine__UnequalNumberOfTokenAndPriceFeedAddresses();
    error ESCEngine__TokenNotAllowed();
    error ESCEngine__TransferFailed();
    error ESCEngine__InsufficientHealthFactor(uint256 healthFactor);
    error ESCEngine__MintFailed();

    /**
     * Modifiers
     */
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert ESCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert ESCEngine__TokenNotAllowed();
        }
        _;
    }

    /**
     * Functions
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses) {
        // Usd Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert ESCEngine__UnequalNumberOfTokenAndPriceFeedAddresses();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_esc = new EarnStableCoin();
    }

    /**
     * External Functions
     */
    function depositCollateralAndMintESC() external {}

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
            revert ESCEngine__TransferFailed();
        }
    }

    /**
     */
    function redeemCollateralForESC() external {}
    function redeemCollateral() external {}

    /**
     * @notice follows CEI
     * @param amount Mint amount
     * @notice must have more collateral value than the minimum threshold
     */
    function mintESC(uint256 amount) external moreThanZero(amount) nonReentrant {
        s_minted[msg.sender] += amount;

        // revert if minted too much
        uint256 healthFactor = _healthFactor(msg.sender);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert ESCEngine__InsufficientHealthFactor(healthFactor);
        }

        bool success = i_esc.mint(msg.sender, amount);
        if (!success) {
            revert ESCEngine__MintFailed();
        }
    }

    function burnESC() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}

    /**
     * Public Functions
     */
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        // returned value by Chainlink will be 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount / PRECISION);
    }

    /**
     * Private Functions
     */
    function _getAccountInfo(address user) private view returns (uint256 totalMinted, uint256 collateralInUsd) {
        totalMinted = s_minted[user];
        collateralInUsd = getAccountCollateralValue(user);
    }

    /**
     * @notice Returns how close to liquidition a user is. Liquidiation occurs at <= 1
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalEscMinted, uint256 collateralValueInUsd) = _getAccountInfo(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // Example liquidiation:
        // $150 EARN / 100 ESC = 1.5
        // 150 * 50 = 7500 => 7500 / 100 = 75 => 75 / 100 = 0.75 < 1

        // Example no liquidation:
        // $1000 EARN / 100 ESC = 1.5
        // 1000 * 50 = 50000 => 50000 / 100 = 500 => 500 / 100 = 5 > 1
        return (collateralAdjustedForThreshold / totalEscMinted);
    }

    // function _revertIfInsufficientHealthFactor(address user) internal view {
    //     uint256 healthFactor = _healthFactor(user);
    //     if (healthFactor < MIN_HEALTH_FACTOR) {
    //         revert ESCEngine__InsufficientHealthFactor(healthFactor);
    //     }
    // }
}
