// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CanivalTV} from "../../../src/MyDuckly/CanivalTV.sol";

contract DeployCanivalTV is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying CanivalTV with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        CanivalTV _implementation = new CanivalTV();
        console.log("CanivalTV implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(CanivalTV.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("CanivalTV proxy deployed at:", address(_proxy));

        CanivalTV canivalTV = CanivalTV(address(_proxy));

        console.log("Contract name:", canivalTV.name());
        console.log("Contract symbol:", canivalTV.symbol());
        console.log("Max supply:", canivalTV.MAX_SUPPLY());
        console.log("Current supply:", canivalTV.totalMinted());
        console.log("Remaining supply:", canivalTV.remainingSupply());
        console.log("Owner:", canivalTV.owner());

        vm.stopBroadcast();

        demonstrateCanivalTVFunctionality(address(canivalTV));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateCanivalTVFunctionality(address canivalTVAddress) internal view {
        CanivalTV canivalTV = CanivalTV(canivalTVAddress);

        console.log("\n=== MYDUCKLY CANIVAL TV NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", canivalTV.name());
        console.log("Symbol:", canivalTV.symbol());
        console.log("Max Supply:", canivalTV.MAX_SUPPLY());
        console.log("Current Owner:", canivalTV.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   canivalTV.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   canivalTV.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   canivalTV.upgradeToAndCall(newImpl, data)");
    }
}
