// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PitGueio} from "../../../src/MyDuckly/PitGueio.sol";

contract DeployPitGueio is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying PitGueio with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        PitGueio _implementation = new PitGueio();
        console.log("PitGueio implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(PitGueio.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("PitGueio proxy deployed at:", address(_proxy));

        PitGueio pitGueio = PitGueio(address(_proxy));

        console.log("Contract name:", pitGueio.name());
        console.log("Contract symbol:", pitGueio.symbol());
        console.log("Max supply:", pitGueio.MAX_SUPPLY());
        console.log("Current supply:", pitGueio.totalMinted());
        console.log("Remaining supply:", pitGueio.remainingSupply());
        console.log("Owner:", pitGueio.owner());

        vm.stopBroadcast();

        demonstratePitGueioFunctionality(address(pitGueio));

        return (address(_implementation), address(_proxy));
    }

    function demonstratePitGueioFunctionality(address pitGueioAddress) internal view {
        PitGueio pitGueio = PitGueio(pitGueioAddress);

        console.log("\n=== MYDUCKLY PIT GUEIO NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", pitGueio.name());
        console.log("Symbol:", pitGueio.symbol());
        console.log("Max Supply:", pitGueio.MAX_SUPPLY());
        console.log("Current Owner:", pitGueio.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   pitGueio.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   pitGueio.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   pitGueio.upgradeToAndCall(newImpl, data)");
    }
}