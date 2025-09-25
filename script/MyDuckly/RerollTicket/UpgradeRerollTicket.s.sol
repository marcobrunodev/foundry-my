// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RerollTicket} from "../../../src/MyDuckly/RerollTicket.sol";

contract UpgradeRerollTicket is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading RerollTicket with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("REROLL_TICKET_PROXY");
        console.log("RerollTicket proxy address:", proxyAddress);

        // Deploy new implementation
        RerollTicket _newImplementation = new RerollTicket();
        console.log("New RerollTicket implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        RerollTicket rerollTicket = RerollTicket(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = rerollTicket.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", rerollTicket.name());
        console.log("Contract symbol:", rerollTicket.symbol());
        console.log("Max supply:", rerollTicket.MAX_SUPPLY());
        console.log("Total minted:", rerollTicket.totalMinted());
        console.log("Remaining supply:", rerollTicket.remainingSupply());

        // Perform upgrade
        rerollTicket.upgradeToAndCall(address(_newImplementation), "");
        console.log("\nSUCCESS: Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", rerollTicket.name());
        console.log("Contract symbol:", rerollTicket.symbol());
        console.log("Max supply:", rerollTicket.MAX_SUPPLY());
        console.log("Total minted:", rerollTicket.totalMinted());
        console.log("Remaining supply:", rerollTicket.remainingSupply());
        console.log("Owner:", rerollTicket.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}
