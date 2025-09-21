// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Gueio} from "../../src/MyDuckly/Gueio.sol";

contract GueioTest is Test {
    Gueio public gueio;
    Gueio public implementation;
    address public owner;
    address public user1;
    address public user2;

    event TokenMinted(address indexed to, uint256 indexed tokenId);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        implementation = new Gueio();

        bytes memory data = abi.encodeWithSelector(Gueio.initialize.selector, owner);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        gueio = Gueio(address(proxy));

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(gueio.name(), "Gueio");
        assertEq(gueio.symbol(), "GUEIO");
        assertEq(gueio.owner(), owner);
        assertEq(gueio.MAX_SUPPLY(), 512);
        assertEq(gueio.totalMinted(), 0);
        assertEq(gueio.remainingSupply(), 512);
    }

    function test_Mint() public {
        vm.startPrank(owner);

        string memory uri = "ipfs://QmTestHash1";

        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 1);

        gueio.mint(user1, uri);

        assertEq(gueio.balanceOf(user1), 1);
        assertEq(gueio.ownerOf(1), user1);
        assertEq(gueio.tokenURI(1), uri);
        assertEq(gueio.totalMinted(), 1);
        assertEq(gueio.remainingSupply(), 511);

        vm.stopPrank();
    }

    function test_BatchMint() public {
        vm.startPrank(owner);

        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = owner;

        string[] memory uris = new string[](3);
        uris[0] = "ipfs://QmHash1";
        uris[1] = "ipfs://QmHash2";
        uris[2] = "ipfs://QmHash3";

        gueio.batchMint(recipients, uris);

        assertEq(gueio.balanceOf(user1), 1);
        assertEq(gueio.balanceOf(user2), 1);
        assertEq(gueio.balanceOf(owner), 1);
        assertEq(gueio.totalMinted(), 3);
        assertEq(gueio.remainingSupply(), 509);

        assertEq(gueio.tokenURI(1), "ipfs://QmHash1");
        assertEq(gueio.tokenURI(2), "ipfs://QmHash2");
        assertEq(gueio.tokenURI(3), "ipfs://QmHash3");

        vm.stopPrank();
    }

    function test_MintOnlyOwner() public {
        vm.startPrank(user1);

        vm.expectRevert();
        gueio.mint(user1, "ipfs://test");

        vm.stopPrank();
    }

    function test_BatchMintArrayLengthMismatch() public {
        vm.startPrank(owner);

        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        string[] memory uris = new string[](3);
        uris[0] = "ipfs://QmHash1";
        uris[1] = "ipfs://QmHash2";
        uris[2] = "ipfs://QmHash3";

        vm.expectRevert("Gueio: arrays length mismatch");
        gueio.batchMint(recipients, uris);

        vm.stopPrank();
    }

    function test_MaxSupplyReached() public {
        vm.startPrank(owner);

        for (uint256 i = 0; i < 512; i++) {
            gueio.mint(user1, string(abi.encodePacked("ipfs://hash", i)));
        }

        assertEq(gueio.totalMinted(), 512);
        assertEq(gueio.remainingSupply(), 0);

        vm.expectRevert("Gueio: max supply reached");
        gueio.mint(user2, "ipfs://overflow");

        vm.stopPrank();
    }

    function test_BatchMintExceedsSupply() public {
        vm.startPrank(owner);

        for (uint256 i = 0; i < 510; i++) {
            gueio.mint(user1, string(abi.encodePacked("ipfs://hash", i)));
        }

        address[] memory recipients = new address[](5);
        string[] memory uris = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            recipients[i] = user2;
            uris[i] = string(abi.encodePacked("ipfs://batch", i));
        }

        vm.expectRevert("Gueio: max supply exceeded");
        gueio.batchMint(recipients, uris);

        vm.stopPrank();
    }

    function test_TokenEnumeration() public {
        vm.startPrank(owner);

        gueio.mint(user1, "ipfs://token1");
        gueio.mint(user1, "ipfs://token2");
        gueio.mint(user2, "ipfs://token3");

        assertEq(gueio.totalSupply(), 3);
        assertEq(gueio.balanceOf(user1), 2);
        assertEq(gueio.balanceOf(user2), 1);

        assertEq(gueio.tokenOfOwnerByIndex(user1, 0), 1);
        assertEq(gueio.tokenOfOwnerByIndex(user1, 1), 2);
        assertEq(gueio.tokenOfOwnerByIndex(user2, 0), 3);

        vm.stopPrank();
    }

    function test_SupportsInterface() public view {
        assertTrue(gueio.supportsInterface(0x80ac58cd));
        assertTrue(gueio.supportsInterface(0x780e9d63));
        assertTrue(gueio.supportsInterface(0x5b5e139f));
    }

    function test_Upgrade() public {
        vm.startPrank(owner);

        Gueio newImplementation = new Gueio();

        gueio.upgradeToAndCall(address(newImplementation), "");

        assertEq(gueio.name(), "Gueio");
        assertEq(gueio.symbol(), "GUEIO");
        assertEq(gueio.owner(), owner);

        vm.stopPrank();
    }

    function test_UpgradeOnlyOwner() public {
        vm.startPrank(user1);

        Gueio newImplementation = new Gueio();

        vm.expectRevert();
        gueio.upgradeToAndCall(address(newImplementation), "");

        vm.stopPrank();
    }

    function testFuzz_MintValidTokenId(uint8 amount) public {
        vm.assume(amount > 0 && amount <= 10);

        vm.startPrank(owner);

        for (uint256 i = 0; i < amount; i++) {
            gueio.mint(user1, string(abi.encodePacked("ipfs://fuzz", i)));
        }

        assertEq(gueio.balanceOf(user1), amount);
        assertEq(gueio.totalMinted(), amount);

        vm.stopPrank();
    }
}
