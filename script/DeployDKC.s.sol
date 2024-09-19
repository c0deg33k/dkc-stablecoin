// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "lib/forge-std/src/Script.sol";
import {DKCEngine} from "../src/DKCEngine.sol";
import {DecentralizedKenyaCoin} from "../src/DecentralizedKenyaCoin.sol";
import {ConfigScript} from "./ConfigScript.s.sol";

contract DeployDKC is Script {
    address[] public tokenAdresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedKenyaCoin, DKCEngine, ConfigScript) {
        // Deploy the contract
        ConfigScript config = new ConfigScript();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            config.activeNetworkConfig();

        tokenAdresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);

        DecentralizedKenyaCoin dkc = new DecentralizedKenyaCoin(msg.sender);

        DKCEngine engine = new DKCEngine(tokenAdresses, priceFeedAddresses, address(dkc));
        // dkc.transferOwnership(address(engine));
        vm.stopBroadcast();

        return (dkc, engine, config);
    }
}
