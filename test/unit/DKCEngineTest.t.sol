// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DKCEngine} from "../../src/DKCEngine.sol";
import {DecentralizedKenyaCoin} from "../../src/DecentralizedKenyaCoin.sol";
import {DeployDKC} from "../../script/DeployDKC.s.sol";
import {ConfigScript} from "../../script/ConfigScript.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract DKCEngineTest is Test {
    DKCEngine dkcEng;
    DecentralizedKenyaCoin dkc;
    DeployDKC deployer;
    ConfigScript config;
    address ethUsdPriceFeed;
    address wETH;
    address btcUsdPriceFeed;
    address wBTC;

    address[] public tokenAddresses;
    address[] public tokenPriceFeeds;
    

    address public USER = makeAddr("user");
    uint256 public constant COLLATERAL_AMOUNT = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDKC();
        (dkc, dkcEng, config) = deployer.run();
        dkc.transferOwnership(address(dkcEng));
        (ethUsdPriceFeed, btcUsdPriceFeed, wETH, wBTC, ) = config.activeNetworkConfig();

        ERC20Mock(wETH).mint(USER, STARTING_ERC20_BALANCE);
    }


    // constructor tests

    function testContractOwnerIsDKCEngine() public view {
        assertEq(dkc.owner(), address(dkcEng));
    }

    function testDKCEngineRevertsIfTokenAddressesDontEqualPriceFeedsLength() public {
        tokenAddresses.push(wETH);
        tokenPriceFeeds.push(ethUsdPriceFeed);
        tokenPriceFeeds.push(btcUsdPriceFeed);
        vm.expectRevert(DKCEngine.DKCEngine__TokenAddressesSizeShouldEqualPriceFeedsAddressesSize.selector);
        new DKCEngine(tokenAddresses, tokenPriceFeeds, address(dkc));
    }


    // price tests

    function testGetUsdValue() public view {
        // Test that the getUsdValue function returns the correct value
        uint256 ethAmmount = 15e18;
        uint256 expectedValue = 3e22; // 30000e18  ----> fix to use on sepolia
        uint256 actualValue = dkcEng.getUsdValue(wETH, ethAmmount);
        assertEq(expectedValue, actualValue);
    }


    function testGetTokenAmountFromUsd() public view{
        // Test that the getTokenAmountFromUsd function returns the correct value
        uint256 usdAmount = 100 ether;
        uint256 expectedWethAmount = 0.05 ether;
        uint256 actualWethAmount = dkcEng.getTokenAmountFromUsd(wETH, usdAmount);
        assertEq(actualWethAmount, expectedWethAmount);
    }



    //collateral tests

    function testDepositRevertsIfCollateralUnauthorized() public {
        // Test that deposit reverts if collateral is unauthorized
        ERC20Mock cgk = new ERC20Mock("c0deg33k", "CGK", USER, STARTING_ERC20_BALANCE);
        vm.startPrank(USER);
        vm.expectRevert(DKCEngine.DKCEngine__TokenNotAllowed.selector);
        dkcEng.depositCollateral(address(cgk), STARTING_ERC20_BALANCE);
        vm.stopPrank();
    }

    modifier collateralDeposited() {
        vm.startPrank(USER);
        ERC20Mock(wETH).approve(address(dkcEng), STARTING_ERC20_BALANCE);
        dkcEng.depositCollateral(wETH, STARTING_ERC20_BALANCE);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public collateralDeposited {
        // Test that deposit collateral and getAccountInfo work correctly
        (uint256 dkcMinted, uint256 usdCollateralValue) = dkcEng.getUserAccountInfo(USER);
        uint256 expectedDKCMinted = 0;
        uint256 expectedUsdCollateralDeposit = dkcEng.getTokenAmountFromUsd(wETH, usdCollateralValue);
        assertEq(dkcMinted, expectedDKCMinted);
        assertEq(STARTING_ERC20_BALANCE, expectedUsdCollateralDeposit);

    }

    function testRevertsIfCollateralZero() public {
        vm.prank(USER);
        ERC20Mock(wETH).approve(address(dkcEng), COLLATERAL_AMOUNT);
        vm.expectRevert(DKCEngine.DKCEngine__AmountShouldBeMoreThanZero.selector);
        dkcEng.depositCollateral(wETH, 0);
        vm.stopPrank();
    }
}
