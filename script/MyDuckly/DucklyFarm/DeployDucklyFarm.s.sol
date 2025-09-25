// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DucklyFarm} from "../../../src/MyDuckly/DucklyFarm.sol";

contract DeployDucklyFarm is Script {
    function run() external returns (address implementation, address proxy) {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deploying DucklyFarm with deployer:", deployer);

        // Use INITIAL_OWNER from environment as the contract owner
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        console.log("Contract owner will be:", initialOwner);

        DucklyFarm _implementation = new DucklyFarm();
        console.log("DucklyFarm implementation deployed at:", address(_implementation));

        bytes memory data = abi.encodeWithSelector(DucklyFarm.initialize.selector, initialOwner);

        ERC1967Proxy _proxy = new ERC1967Proxy(address(_implementation), data);
        console.log("DucklyFarm proxy deployed at:", address(_proxy));

        DucklyFarm ducklyFarm = DucklyFarm(address(_proxy));

        console.log("Contract name:", ducklyFarm.name());
        console.log("Contract symbol:", ducklyFarm.symbol());
        console.log("Max supply:", ducklyFarm.MAX_SUPPLY());
        console.log("Current supply:", ducklyFarm.totalMinted());
        console.log("Remaining supply:", ducklyFarm.remainingSupply());
        console.log("Owner:", ducklyFarm.owner());

        vm.stopBroadcast();

        demonstrateDucklyFarmFunctionality(address(ducklyFarm));

        return (address(_implementation), address(_proxy));
    }

    function demonstrateDucklyFarmFunctionality(address ducklyFarmAddress) internal view {
        DucklyFarm ducklyFarm = DucklyFarm(ducklyFarmAddress);

        console.log("\n=== MYDUCKLY DUCKLY FARM NFT CONTRACT ===");
        console.log("Contract Type: ERC721 with UUPS Upgradeability");
        console.log("Name:", ducklyFarm.name());
        console.log("Symbol:", ducklyFarm.symbol());
        console.log("Max Supply:", ducklyFarm.MAX_SUPPLY());
        console.log("Current Owner:", ducklyFarm.owner());

        console.log("\nAvailable Functions:");
        console.log("- mint(address to, string memory uri) - Moderator only");
        console.log("- batchMint(address[] memory to, string[] memory uris) - Moderator only");
        console.log("- totalMinted() - View current minted count");
        console.log("- remainingSupply() - View remaining mintable tokens");
        console.log("- Standard ERC721 functions (transfer, approve, etc.)");
        console.log("- UUPS upgrade functionality (owner only)");

        console.log("\nExample Usage:");
        console.log("1. Mint single NFT:");
        console.log("   ducklyFarm.mint(recipient, 'ipfs://QmHash...')");
        console.log("\n2. Batch mint NFTs:");
        console.log("   address[] memory recipients = [addr1, addr2];");
        console.log("   string[] memory uris = ['ipfs://hash1', 'ipfs://hash2'];");
        console.log("   ducklyFarm.batchMint(recipients, uris)");
        console.log("\n3. Upgrade contract (owner only):");
        console.log("   ducklyFarm.upgradeToAndCall(newImpl, data)");
    }
}
