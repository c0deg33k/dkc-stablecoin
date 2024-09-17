// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "lib/forge-std/src/Script.sol";
import {DKCEngine} from "../src/DKCEngine.sol";
import {DecentralizedKenyaCoin} from "../src/DecentralizedKenyaCoin.sol";

contract DeployDKC is Script {
    function run() external returns (DecentralizedKenyaCoin, DKCEngine) {
        // Deploy the contract
        vm.startBroadcast();
        DecentralizedKenyaCoin dkc = new DecentralizedKenyaCoin(msg.sender);

        //DKCEngine engine = new DKCEngine(dkc,);
        vm.stopBroadcast();
    }
}
