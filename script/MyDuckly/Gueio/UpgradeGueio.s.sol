// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Gueio} from "../../../src/MyDuckly/Gueio.sol";

contract UpgradeGueio is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading Gueio with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("GUEIO_PROXY");
        console.log("Gueio proxy address:", proxyAddress);

        // Deploy new implementation
        Gueio _newImplementation = new Gueio();
        console.log("New Gueio implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        Gueio gueio = Gueio(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = gueio.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", gueio.name());
        console.log("Contract symbol:", gueio.symbol());
        console.log("Max supply:", gueio.MAX_SUPPLY());
        console.log("Total minted:", gueio.totalMinted());
        console.log("Remaining supply:", gueio.remainingSupply());

        // Perform upgrade
        gueio.upgradeToAndCall(address(_newImplementation), "");
        console.log("\n  Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", gueio.name());
        console.log("Contract symbol:", gueio.symbol());
        console.log("Max supply:", gueio.MAX_SUPPLY());
        console.log("Total minted:", gueio.totalMinted());
        console.log("Remaining supply:", gueio.remainingSupply());
        console.log("Owner:", gueio.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
    }
}
