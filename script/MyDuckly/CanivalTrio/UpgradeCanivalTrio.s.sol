// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CanivalTrio} from "../../../src/MyDuckly/CanivalTrio.sol";

contract UpgradeCanivalTrio is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading CanivalTrio with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("CANIVAL_TRIO_PROXY");
        console.log("CanivalTrio proxy address:", proxyAddress);

        // Deploy new implementation
        CanivalTrio _newImplementation = new CanivalTrio();
        console.log("New CanivalTrio implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        CanivalTrio canivalTrio = CanivalTrio(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = canivalTrio.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", canivalTrio.name());
        console.log("Contract symbol:", canivalTrio.symbol());
        console.log("Max supply:", canivalTrio.MAX_SUPPLY());
        console.log("Total minted:", canivalTrio.totalMinted());
        console.log("Remaining supply:", canivalTrio.remainingSupply());

        // Perform upgrade
        canivalTrio.upgradeToAndCall(address(_newImplementation), "");
        console.log("\nSUCCESS: Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", canivalTrio.name());
        console.log("Contract symbol:", canivalTrio.symbol());
        console.log("Max supply:", canivalTrio.MAX_SUPPLY());
        console.log("Total minted:", canivalTrio.totalMinted());
        console.log("Remaining supply:", canivalTrio.remainingSupply());
        console.log("Owner:", canivalTrio.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}
