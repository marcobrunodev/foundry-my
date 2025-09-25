// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {RerollTicket} from "../../../src/MyDuckly/RerollTicket.sol";

contract DeployRerollTicket is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying RerollTicket with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        RerollTicket _implementation = new RerollTicket();
        console.log("RerollTicket implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(RerollTicket.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("RerollTicket proxy deployed at:", address(_proxy));

        RerollTicket rerollTicket = RerollTicket(address(_proxy));

        console.log("Contract name:", rerollTicket.name());
        console.log("Contract symbol:", rerollTicket.symbol());
        console.log("Max supply:", rerollTicket.MAX_SUPPLY());
        console.log("Current supply:", rerollTicket.totalMinted());
        console.log("Remaining supply:", rerollTicket.remainingSupply());
        console.log("Owner:", rerollTicket.owner());

        vm.stopBroadcast();

        demonstrateRerollTicketFunctionality(address(rerollTicket));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateRerollTicketFunctionality(address rerollTicketAddress) internal view {
        RerollTicket rerollTicket = RerollTicket(rerollTicketAddress);

        console.log("\n=== MYDUCKLY REROLL TICKET NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", rerollTicket.name());
        console.log("Symbol:", rerollTicket.symbol());
        console.log("Max Supply:", rerollTicket.MAX_SUPPLY());
        console.log("Current Owner:", rerollTicket.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   rerollTicket.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   rerollTicket.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   rerollTicket.upgradeToAndCall(newImpl, data)");
    }
}