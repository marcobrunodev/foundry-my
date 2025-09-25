// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PitGueio} from "../../../src/MyDuckly/PitGueio.sol";

contract UpgradePitGueio is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading PitGueio with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("PIT_GUEIO_PROXY");
        console.log("PitGueio proxy address:", proxyAddress);

        // Deploy new implementation
        PitGueio _newImplementation = new PitGueio();
        console.log("New PitGueio implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        PitGueio pitGueio = PitGueio(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = pitGueio.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", pitGueio.name());
        console.log("Contract symbol:", pitGueio.symbol());
        console.log("Max supply:", pitGueio.MAX_SUPPLY());
        console.log("Total minted:", pitGueio.totalMinted());
        console.log("Remaining supply:", pitGueio.remainingSupply());

        // Perform upgrade
        pitGueio.upgradeToAndCall(address(_newImplementation), "");
        console.log("\nSUCCESS: Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", pitGueio.name());
        console.log("Contract symbol:", pitGueio.symbol());
        console.log("Max supply:", pitGueio.MAX_SUPPLY());
        console.log("Total minted:", pitGueio.totalMinted());
        console.log("Remaining supply:", pitGueio.remainingSupply());
        console.log("Owner:", pitGueio.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}
