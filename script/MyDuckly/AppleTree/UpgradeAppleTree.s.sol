// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AppleTree} from "../../../src/MyDuckly/AppleTree.sol";

contract UpgradeAppleTree is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading AppleTree with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("APPLE_TREE_PROXY");
        console.log("AppleTree proxy address:", proxyAddress);

        // Deploy new implementation
        AppleTree _newImplementation = new AppleTree();
        console.log("New AppleTree implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        AppleTree appleTree = AppleTree(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = appleTree.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", appleTree.name());
        console.log("Contract symbol:", appleTree.symbol());
        console.log("Max supply:", appleTree.MAX_SUPPLY());
        console.log("Total minted:", appleTree.totalMinted());
        console.log("Remaining supply:", appleTree.remainingSupply());

        // Perform upgrade
        appleTree.upgradeToAndCall(address(_newImplementation), "");
        console.log("\n✅ Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", appleTree.name());
        console.log("Contract symbol:", appleTree.symbol());
        console.log("Max supply:", appleTree.MAX_SUPPLY());
        console.log("Total minted:", appleTree.totalMinted());
        console.log("Remaining supply:", appleTree.remainingSupply());
        console.log("Owner:", appleTree.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}