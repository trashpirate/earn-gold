// SPDX-License Identifier: MIT

pragma solidity 0.8.20;

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

contract EGCEngine {
    function depositCollateralAndMintEGC() external {}
    function depositCollateral() external {}
    function redeemCollateralForDSC() external {}
    function redeemCollateral() external {}
    function mintDSC() external {}
    function burnDSC() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}
}
