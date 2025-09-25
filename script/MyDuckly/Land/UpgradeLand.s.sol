// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Land} from "../../../src/MyDuckly/Land.sol";

contract UpgradeLand is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading Land with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("LAND_PROXY");
        console.log("Land proxy address:", proxyAddress);

        // Deploy new implementation
        Land _newImplementation = new Land();
        console.log("New Land implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        Land land = Land(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = land.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", land.name());
        console.log("Contract symbol:", land.symbol());
        console.log("Max supply:", land.MAX_SUPPLY());
        console.log("Total minted:", land.totalMinted());
        console.log("Remaining supply:", land.remainingSupply());

        // Perform upgrade
        land.upgradeToAndCall(address(_newImplementation), "");
        console.log("\n  Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", land.name());
        console.log("Contract symbol:", land.symbol());
        console.log("Max supply:", land.MAX_SUPPLY());
        console.log("Total minted:", land.totalMinted());
        console.log("Remaining supply:", land.remainingSupply());
        console.log("Owner:", land.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}
