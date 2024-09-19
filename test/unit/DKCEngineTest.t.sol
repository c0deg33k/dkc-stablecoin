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

    address public USER = makeAddr("user");
    uint256 public constant COLLATERAL_AMOUNT = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDKC();
        (dkc, dkcEng, config) = deployer.run();
        dkc.transferOwnership(address(dkcEng));
        (ethUsdPriceFeed,, wETH,,) = config.activeNetworkConfig();

        ERC20Mock(wETH).mint(USER, STARTING_ERC20_BALANCE);
    }

    function testContractOwnerIsDKCEngine() public view {
        assertEq(dkc.owner(), address(dkcEng));
    }

    function testGetUsdValue() public view {
        // Test that the getUsdValue function returns the correct value
        uint256 ethAmmount = 15e18;
        uint256 expectedValue = 3e22; // 30000e18  ----> fix to use on sepolia
        uint256 actualValue = dkcEng.getUsdValue(wETH, ethAmmount);
        assertEq(expectedValue, actualValue);
    }

    function testRevertsIfCollateralZero() public {
        vm.prank(USER);
        ERC20Mock(wETH).approve(address(dkcEng), COLLATERAL_AMOUNT);
        vm.expectRevert(DKCEngine.DKCEngine__AmountShouldBeMoreThanZero.selector);
        dkcEng.depositCollateral(wETH, 0);
        vm.stopPrank();
    }
}
