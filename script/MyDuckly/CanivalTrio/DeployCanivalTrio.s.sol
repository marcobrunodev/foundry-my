// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CanivalTrio} from "../../../src/MyDuckly/CanivalTrio.sol";

contract DeployCanivalTrio is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying CanivalTrio with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        CanivalTrio _implementation = new CanivalTrio();
        console.log("CanivalTrio implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(CanivalTrio.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("CanivalTrio proxy deployed at:", address(_proxy));

        CanivalTrio canivalTrio = CanivalTrio(address(_proxy));

        console.log("Contract name:", canivalTrio.name());
        console.log("Contract symbol:", canivalTrio.symbol());
        console.log("Max supply:", canivalTrio.MAX_SUPPLY());
        console.log("Current supply:", canivalTrio.totalMinted());
        console.log("Remaining supply:", canivalTrio.remainingSupply());
        console.log("Owner:", canivalTrio.owner());

        vm.stopBroadcast();

        demonstrateCanivalTrioFunctionality(address(canivalTrio));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateCanivalTrioFunctionality(address canivalTrioAddress) internal view {
        CanivalTrio canivalTrio = CanivalTrio(canivalTrioAddress);

        console.log("\n=== MYDUCKLY CANIVAL TRIO NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", canivalTrio.name());
        console.log("Symbol:", canivalTrio.symbol());
        console.log("Max Supply:", canivalTrio.MAX_SUPPLY());
        console.log("Current Owner:", canivalTrio.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   canivalTrio.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   canivalTrio.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   canivalTrio.upgradeToAndCall(newImpl, data)");
    }
}