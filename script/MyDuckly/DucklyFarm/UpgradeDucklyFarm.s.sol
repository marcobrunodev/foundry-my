// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DucklyFarm} from "../../../src/MyDuckly/DucklyFarm.sol";

contract UpgradeDucklyFarm is Script {
    function run() external returns (address newImplementation) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Upgrading DucklyFarm with deployer:", deployer);

        // Get proxy address from environment
        address proxyAddress = vm.envAddress("DUCKLY_FARM_PROXY");
        console.log("DucklyFarm proxy address:", proxyAddress);

        // Deploy new implementation
        DucklyFarm _newImplementation = new DucklyFarm();
        console.log("New DucklyFarm implementation deployed at:", address(_newImplementation));

        // Get the proxy instance
        DucklyFarm ducklyFarm = DucklyFarm(proxyAddress);

        // Verify current owner before upgrade
        address currentOwner = ducklyFarm.owner();
        console.log("Current contract owner:", currentOwner);

        // Get current state before upgrade
        console.log("\n=== STATE BEFORE UPGRADE ===");
        console.log("Current implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", ducklyFarm.name());
        console.log("Contract symbol:", ducklyFarm.symbol());
        console.log("Max supply:", ducklyFarm.MAX_SUPPLY());
        console.log("Total minted:", ducklyFarm.totalMinted());
        console.log("Remaining supply:", ducklyFarm.remainingSupply());

        // Perform upgrade
        ducklyFarm.upgradeToAndCall(address(_newImplementation), "");
        console.log("\n✅ Upgrade completed successfully!");

        // Verify state after upgrade
        console.log("\n=== STATE AFTER UPGRADE ===");
        console.log("New implementation:", getImplementation(proxyAddress));
        console.log("Contract name:", ducklyFarm.name());
        console.log("Contract symbol:", ducklyFarm.symbol());
        console.log("Max supply:", ducklyFarm.MAX_SUPPLY());
        console.log("Total minted:", ducklyFarm.totalMinted());
        console.log("Remaining supply:", ducklyFarm.remainingSupply());
        console.log("Owner:", ducklyFarm.owner());

        vm.stopBroadcast();

        return address(_newImplementation);
    }

    // Helper function to get implementation address from proxy
    function getImplementation(address proxy) internal view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return address(uint160(uint256(vm.load(proxy, implementationSlot))));
    }
}