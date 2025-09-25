// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Duckly} from "../../../src/MyDuckly/Duckly.sol";

contract UpgradeDuckly is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading Duckly with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("DUCKLY_PROXY");
        console.log("Duckly proxy address:", proxyAddress);

        // Deploy new implementation
        Duckly _newImplementation = new Duckly();
        console.log("New Duckly implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        Duckly duckly = Duckly(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = duckly.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", duckly.name());
        console.log("Contract symbol:", duckly.symbol());
        console.log("Max supply:", duckly.MAX_SUPPLY());
        console.log("Total minted:", duckly.totalMinted());
        console.log("Remaining supply:", duckly.remainingSupply());

        // Perform upgrade
        duckly.upgradeToAndCall(address(_newImplementation), "");
        console.log("\nSUCCESS: Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", duckly.name());
        console.log("Contract symbol:", duckly.symbol());
        console.log("Max supply:", duckly.MAX_SUPPLY());
        console.log("Total minted:", duckly.totalMinted());
        console.log("Remaining supply:", duckly.remainingSupply());
        console.log("Owner:", duckly.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}
