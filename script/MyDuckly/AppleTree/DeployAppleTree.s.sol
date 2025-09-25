// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AppleTree} from "../../../src/MyDuckly/AppleTree.sol";

contract DeployAppleTree is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying AppleTree with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        AppleTree _implementation = new AppleTree();
        console.log("AppleTree implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(AppleTree.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("AppleTree proxy deployed at:", address(_proxy));

        AppleTree appleTree = AppleTree(address(_proxy));

        console.log("Contract name:", appleTree.name());
        console.log("Contract symbol:", appleTree.symbol());
        console.log("Max supply:", appleTree.MAX_SUPPLY());
        console.log("Current supply:", appleTree.totalMinted());
        console.log("Remaining supply:", appleTree.remainingSupply());
        console.log("Owner:", appleTree.owner());

        vm.stopBroadcast();

        demonstrateAppleTreeFunctionality(address(appleTree));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateAppleTreeFunctionality(address appleTreeAddress) internal view {
        AppleTree appleTree = AppleTree(appleTreeAddress);

        console.log("\n=== MYDUCKLY APPLE TREE NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", appleTree.name());
        console.log("Symbol:", appleTree.symbol());
        console.log("Max Supply:", appleTree.MAX_SUPPLY());
        console.log("Current Owner:", appleTree.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   appleTree.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   appleTree.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   appleTree.upgradeToAndCall(newImpl, data)");
    }
}