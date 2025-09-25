// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Fountain} from "../../../src/MyDuckly/Fountain.sol";

contract UpgradeFountain is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading Fountain with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("FOUNTAIN_PROXY");
        console.log("Fountain proxy address:", proxyAddress);

        // Deploy new implementation
        Fountain _newImplementation = new Fountain();
        console.log("New Fountain implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        Fountain fountain = Fountain(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = fountain.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", fountain.name());
        console.log("Contract symbol:", fountain.symbol());
        console.log("Max supply:", fountain.MAX_SUPPLY());
        console.log("Total minted:", fountain.totalMinted());
        console.log("Remaining supply:", fountain.remainingSupply());

        // Perform upgrade
        fountain.upgradeToAndCall(address(_newImplementation), "");
        console.log("\n✅ Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", fountain.name());
        console.log("Contract symbol:", fountain.symbol());
        console.log("Max supply:", fountain.MAX_SUPPLY());
        console.log("Total minted:", fountain.totalMinted());
        console.log("Remaining supply:", fountain.remainingSupply());
        console.log("Owner:", fountain.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}