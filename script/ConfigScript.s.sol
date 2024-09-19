// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";

contract ConfigScript is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;
    uint256 public constant INITIAL_ACCOUNT_BALANCE = 1000e8;
    NetworkConfig public activeNetworkConfig;
    

    constructor() {
        if (block.chainid == 11155111){
            activeNetworkConfig = getSepoliaETHConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    /**
     * @notice Uses Chainlink pricefeed addresses
     * @dev Feel free to use whichever oracle provider you prefer
     */
    function getSepoliaETHConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wETHMock = new ERC20Mock("WETH", "WETH", msg.sender, INITIAL_ACCOUNT_BALANCE);

        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wBTCMock = new ERC20Mock("WBTC", "WBTC", msg.sender, INITIAL_ACCOUNT_BALANCE);

        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(ethUsdPriceFeed),
            wbtcUsdPriceFeed: address(btcUsdPriceFeed),
            weth: address(wETHMock),
            wbtc: address(wBTCMock),
            deployerKey: vm.envUint("ANVIL_PRIVATE_KEY")
        });
    }
}
