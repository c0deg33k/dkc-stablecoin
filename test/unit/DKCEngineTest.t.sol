// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DKCEngine} from "../../src/DKCEngine.sol";
import {DecentralizedKenyaCoin} from "../../src/DecentralizedKenyaCoin.sol";
import {DeployDKC} from "../../script/DeployDKC.s.sol";
import {ConfigScript} from "../../script/ConfigScript.s.sol";

contract DKCEngineTest is Test{
    DKCEngine dkcEng;
    DecentralizedKenyaCoin dkc;
    DeployDKC deployer;
    ConfigScript config;
    address ethUsdPriceFeed;
    address wETH;

    function setUp() public {
        deployer = new DeployDKC();
        (dkc, dkcEng, config) = deployer.run();
        dkc.transferOwnership(address(dkcEng));
        (ethUsdPriceFeed, , wETH, , ) = config.activeNetworkConfig();

        assertEq(dkc.owner(), address(dkcEng));
    }

    function testGetUsdValue() public view {
        // Test that the getUsdValue function returns the correct value
        uint256 ethAmmount = 15e18;
        uint256 expectedValue = 30000e18;
        uint256 actualValue = dkcEng.getUsdValue(wETH, ethAmmount);
        assertEq(expectedValue, actualValue);
    }

}