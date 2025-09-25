// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Duckly} from "../../../src/MyDuckly/Duckly.sol";

contract DeployDuckly is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying Duckly with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        Duckly _implementation = new Duckly();
        console.log("Duckly implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(Duckly.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("Duckly proxy deployed at:", address(_proxy));

        Duckly duckly = Duckly(address(_proxy));

        console.log("Contract name:", duckly.name());
        console.log("Contract symbol:", duckly.symbol());
        console.log("Max supply:", duckly.MAX_SUPPLY());
        console.log("Current supply:", duckly.totalMinted());
        console.log("Remaining supply:", duckly.remainingSupply());
        console.log("Owner:", duckly.owner());

        vm.stopBroadcast();

        demonstrateDucklyFunctionality(address(duckly));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateDucklyFunctionality(address ducklyAddress) internal view {
        Duckly duckly = Duckly(ducklyAddress);

        console.log("\n=== MYDUCKLY DUCKLY NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", duckly.name());
        console.log("Symbol:", duckly.symbol());
        console.log("Max Supply:", duckly.MAX_SUPPLY());
        console.log("Current Owner:", duckly.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   duckly.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   duckly.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   duckly.upgradeToAndCall(newImpl, data)");
    }
}