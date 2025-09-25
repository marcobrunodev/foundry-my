// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Land} from "../../../src/MyDuckly/Land.sol";

contract DeployLand is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying Land with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        Land _implementation = new Land();
        console.log("Land implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(Land.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("Land proxy deployed at:", address(_proxy));

        Land land = Land(address(_proxy));

        console.log("Contract name:", land.name());
        console.log("Contract symbol:", land.symbol());
        console.log("Max supply:", land.MAX_SUPPLY());
        console.log("Current supply:", land.totalMinted());
        console.log("Remaining supply:", land.remainingSupply());
        console.log("Owner:", land.owner());

        vm.stopBroadcast();

        demonstrateLandFunctionality(address(land));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateLandFunctionality(address landAddress) internal view {
        Land land = Land(landAddress);

        console.log("\n=== MYDUCKLY LAND NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", land.name());
        console.log("Symbol:", land.symbol());
        console.log("Max Supply:", land.MAX_SUPPLY());
        console.log("Current Owner:", land.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   land.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   land.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   land.upgradeToAndCall(newImpl, data)");
    }
}
