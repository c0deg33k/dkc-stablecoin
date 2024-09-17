// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/**
 * @title DescentralizedKenyaCoin
 * @author c0deg33k
 *
 * Coin characteristics:
 *  collateral: Exogenious {wBTC & wETH}
 *  Minting: Algorithmic
 *  Relative stability: Pegged to USD (1 DKC == $1)
 *
 *  - This is similar to DAI if DAI had no governance, no fees and was only backed by wETH and wBTC
 *  - Our system should always be overcollateralized at all times.
 *
 * @notice This contract is the core of the DKC system. This handles all the coin logic for minting DKC, burning/redeeming DKC,
 * depositing & withdrawing collateral.
 * @notice This contract is loosely based on MakerDAO DSS (DAI) system.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {DecentralizedKenyaCoin} from "./DecentralizedKenyaCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";

contract DKCEngine is ReentrancyGuard {
    //////////////////////////////////////////////////////
    //////////////          Errors          //////////////
    //////////////////////////////////////////////////////
    error DKCEngine__AmountShouldBeMoreThanZero();
    error DKCEngine__TokenAddressesSizeShouldEqualPriceFeedsAddressesSize();
    error DKCEngine__TokenNotAllowed();
    error DKCEngine__TransferFailed();
    error DKCEngine__HealthFactorIsBroken(uint256 healthFactor);
    error DKCEngine__MintFailed();

    //////////////////////////////////////////////////////
    //////////////       Constructors       //////////////
    //////////////////////////////////////////////////////

    constructor(address[] memory tokenAdresses, address[] memory priceFeedAddresses, address dkcAddress) {
        if (tokenAdresses.length != priceFeedAddresses.length) {
            revert DKCEngine__TokenAddressesSizeShouldEqualPriceFeedsAddressesSize();
        }
        for (uint256 i = 0; i < tokenAdresses.length; i++) {
            s_priceFeeds[tokenAdresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAdresses[i]);
        }
        i_dsc = DecentralizedKenyaCoin(dkcAddress);
    }

    //////////////////////////////////////////////////////
    //////////////     State variables      //////////////
    //////////////////////////////////////////////////////

    uint256 private constant ADDITIONAL_FEED_PRECISSION = 1e10;
    uint256 private constant PRECISSION = 1e18;
    uint256 private constant LIQUIDATION_FACTOR = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MINIMUM_HEALTH_THRESHHOLD = 1;

    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => uint256 dkcMinted) private s_DKCCoins;
    address[] s_collateralTokens;

    DecentralizedKenyaCoin private immutable i_dsc;

    //////////////////////////////////////////////////////
    //////////////          Events          //////////////
    //////////////////////////////////////////////////////

    event collateralDeposited(address indexed user, address indexed tokenAddress, uint256 indexed tokenAmount);

    //////////////////////////////////////////////////////
    //////////////        Modifiers        ///////////////
    //////////////////////////////////////////////////////
    modifier amountGreaterThanZero(uint256 tokenAmount) {
        if (tokenAmount <= 0) {
            revert DKCEngine__AmountShouldBeMoreThanZero();
        }
        _;
    }

    modifier isAllowed(address tokenAddress) {
        if (s_priceFeeds[tokenAddress] == address(0)) {
            revert DKCEngine__TokenNotAllowed();
        }
        _;
    }

    //////////////////////////////////////////////////////
    //////////////     External funcs       //////////////
    //////////////////////////////////////////////////////

    /**
     * @param collateralTokenAddress The address of the token to deposit.
     * @param collateralTokenAmount The amount of collateral amount to deposit.
     */
    function depositCollateral(address collateralTokenAddress, uint256 collateralTokenAmount)
        external
        isAllowed(collateralTokenAddress)
        amountGreaterThanZero(collateralTokenAmount)
        nonReentrant
    {
        //Logic for depositing collateral
        s_collateralDeposited[msg.sender][collateralTokenAddress] += collateralTokenAmount;
        emit collateralDeposited(msg.sender, collateralTokenAddress, collateralTokenAmount);
        bool success = IERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), collateralTokenAmount);
        if (!success) {
            revert DKCEngine__TransferFailed();
        }
    }

    function withdrawCollateral() external {}

    function mintDKC(uint256 dkcToMint) external amountGreaterThanZero(dkcToMint) nonReentrant {
        //Logic for minting DKC
        s_DKCCoins[msg.sender] += dkcToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool mint = i_dsc.mint(msg.sender, dkcToMint);
        if (!mint) {
            revert DKCEngine__MintFailed();
        }
    }

    function burnDKC() external {}

    function liquidate() external {}

    //////////////////////////////////////////////////////
    //////////////       Public funcs       //////////////
    //////////////////////////////////////////////////////
    function getHealthFactor() public view {}

    function getUserCollateralValue(address user) public view returns (uint256 totalCollateralValue) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address collateralToken = s_collateralTokens[i];
            uint256 tokenAmount = s_collateralDeposited[user][collateralToken];
            totalCollateralValue += getUsdValue(collateralToken, tokenAmount);
        }
        return totalCollateralValue;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISSION) * amount) / PRECISSION;
    }

    //////////////////////////////////////////////////////
    ////////////// Private & Internal funcs //////////////
    //////////////////////////////////////////////////////

    function _getUserAccountInfo(address user) private view returns (uint256 dkcMinted, uint256 usdCollateralValue) {
        dkcMinted = s_DKCCoins[user];
        usdCollateralValue = getUserCollateralValue(user);
        return (dkcMinted, usdCollateralValue);
    }

    /**
     * @param user Takes in a user address and calculates the corresponding health factor
     * if the user's health goes below 1 then the user can be liquidated
     */
    function _healthFactor(address user) private view returns (uint256 health) {
        (uint256 dkcMinted, uint256 usdCollateralValue) = _getUserAccountInfo(user);
        uint256 factorAdjustedCollateral = (usdCollateralValue * LIQUIDATION_FACTOR) / LIQUIDATION_PRECISION;
        health = (factorAdjustedCollateral * LIQUIDATION_PRECISION) / dkcMinted;
        return health;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealth = _healthFactor(user);
        if (userHealth < MINIMUM_HEALTH_THRESHHOLD) {
            revert DKCEngine__HealthFactorIsBroken(userHealth);
        }
    }
}
