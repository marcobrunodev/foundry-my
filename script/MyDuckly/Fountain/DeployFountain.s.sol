// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Fountain} from "../../../src/MyDuckly/Fountain.sol";

contract DeployFountain is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying Fountain with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        Fountain _implementation = new Fountain();
        console.log("Fountain implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(Fountain.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("Fountain proxy deployed at:", address(_proxy));

        Fountain fountain = Fountain(address(_proxy));

        console.log("Contract name:", fountain.name());
        console.log("Contract symbol:", fountain.symbol());
        console.log("Max supply:", fountain.MAX_SUPPLY());
        console.log("Current supply:", fountain.totalMinted());
        console.log("Remaining supply:", fountain.remainingSupply());
        console.log("Owner:", fountain.owner());

        vm.stopBroadcast();

        demonstrateFountainFunctionality(address(fountain));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateFountainFunctionality(address fountainAddress) internal view {
        Fountain fountain = Fountain(fountainAddress);

        console.log("\n=== MYDUCKLY FOUNTAIN NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", fountain.name());
        console.log("Symbol:", fountain.symbol());
        console.log("Max Supply:", fountain.MAX_SUPPLY());
        console.log("Current Owner:", fountain.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   fountain.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   fountain.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   fountain.upgradeToAndCall(newImpl, data)");
    }
}