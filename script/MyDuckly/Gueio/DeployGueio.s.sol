// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Gueio} from "../../../src/MyDuckly/Gueio.sol";

contract DeployGueio is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying Gueio with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        Gueio _implementation = new Gueio();
        console.log("Gueio implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(Gueio.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("Gueio proxy deployed at:", address(_proxy));

        Gueio gueio = Gueio(address(_proxy));

        console.log("Contract name:", gueio.name());
        console.log("Contract symbol:", gueio.symbol());
        console.log("Max supply:", gueio.MAX_SUPPLY());
        console.log("Current supply:", gueio.totalMinted());
        console.log("Remaining supply:", gueio.remainingSupply());
        console.log("Owner:", gueio.owner());

        vm.stopBroadcast();

        demonstrateGueioFunctionality(address(gueio));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateGueioFunctionality(address gueioAddress) internal view {
        Gueio gueio = Gueio(gueioAddress);

        console.log("\n=== GUEIO NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", gueio.name());
        console.log("Symbol:", gueio.symbol());
        console.log("Max Supply:", gueio.MAX_SUPPLY());
        console.log("Current Owner:", gueio.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Owner only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Owner only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   gueio.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   gueio.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   gueio.upgradeToAndCall(newImpl, data)");
    }
}
