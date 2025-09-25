// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CanivalTV} from "../../../src/MyDuckly/CanivalTV.sol";

contract UpgradeCanivalTV is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading CanivalTV with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("CANIVAL_TV_PROXY");
        console.log("CanivalTV proxy address:", proxyAddress);

        // Deploy new implementation
        CanivalTV _newImplementation = new CanivalTV();
        console.log("New CanivalTV implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        CanivalTV canivalTV = CanivalTV(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = canivalTV.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", canivalTV.name());
        console.log("Contract symbol:", canivalTV.symbol());
        console.log("Max supply:", canivalTV.MAX_SUPPLY());
        console.log("Total minted:", canivalTV.totalMinted());
        console.log("Remaining supply:", canivalTV.remainingSupply());

        // Perform upgrade
        canivalTV.upgradeToAndCall(address(_newImplementation), "");
        console.log("\n✅ Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", canivalTV.name());
        console.log("Contract symbol:", canivalTV.symbol());
        console.log("Max supply:", canivalTV.MAX_SUPPLY());
        console.log("Total minted:", canivalTV.totalMinted());
        console.log("Remaining supply:", canivalTV.remainingSupply());
        console.log("Owner:", canivalTV.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}