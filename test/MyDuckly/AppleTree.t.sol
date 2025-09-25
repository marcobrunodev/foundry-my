// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {AppleTree} from "../../src/MyDuckly/AppleTree.sol";
import {IERC721State} from "../../src/interfaces/IERC721State.sol";
import {IERC721Common} from "../../src/interfaces/IERC721Common.sol";

contract AppleTreeTest is Test {
    AppleTree public appleTree;
    AppleTree public implementation;
    address public owner;
    address public moderator;
    address public user1;
    address public user2;

    event TokenMinted(address indexed to, uint256 indexed tokenId);
    event NonceIncremented(uint256 indexed tokenId, address indexed from, address indexed to, uint256 newNonce);
    event BatchMinted(uint256 count, uint256 indexed startTokenId, uint256 indexed endTokenId);
    event ContractInitialized(address indexed owner, uint256 maxSupply);
    event SupplyWarning(uint256 remainingSupply, uint256 totalMinted);

    function setUp() public {
        owner = makeAddr("owner");
        moderator = makeAddr("moderator");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        implementation = new AppleTree();

        bytes memory data = abi.encodeWithSelector(AppleTree.initialize.selector, owner);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        appleTree = AppleTree(address(proxy));

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(appleTree.name(), "MyDuckly Apple Tree");
        assertEq(appleTree.symbol(), "MDAT");
        assertEq(appleTree.owner(), owner);
        assertEq(appleTree.MAX_SUPPLY(), 3000);
        assertEq(appleTree.totalMinted(), 0);
        assertEq(appleTree.remainingSupply(), 3000);
        assertTrue(appleTree.hasRole(appleTree.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(appleTree.hasRole(appleTree.MODERATOR_ROLE(), owner));
    }

    function test_Mint() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 1);

        appleTree.mint(user1, "ipfs://test1");

        assertEq(appleTree.totalMinted(), 1);
        assertEq(appleTree.remainingSupply(), 2999);
        assertEq(appleTree.ownerOf(1), user1);
        assertEq(appleTree.tokenURI(1), "ipfs://test1");

        vm.stopPrank();
    }

    function test_BatchMint() public {
        vm.startPrank(owner);

        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = owner;

        string[] memory uris = new string[](3);
        uris[0] = "ipfs://test1";
        uris[1] = "ipfs://test2";
        uris[2] = "ipfs://test3";

        vm.expectEmit(true, true, false, true);
        emit BatchMinted(3, 1, 3);

        appleTree.batchMint(recipients, uris);

        assertEq(appleTree.totalMinted(), 3);
        assertEq(appleTree.remainingSupply(), 2997);
        assertEq(appleTree.ownerOf(1), user1);
        assertEq(appleTree.ownerOf(2), user2);
        assertEq(appleTree.ownerOf(3), owner);

        vm.stopPrank();
    }

    function test_MaxSupplyReached() public {
        vm.startPrank(owner);

        // Set next token ID to max supply + 1
        for (uint256 i = 1; i <= 3000; i++) {
            appleTree.mint(user1, string(abi.encodePacked("ipfs://test", vm.toString(i))));
        }

        vm.expectRevert(AppleTree.MaxSupplyReached.selector);
        appleTree.mint(user1, "ipfs://overflow");

        vm.stopPrank();
    }

    function test_OnlyModeratorCanMint() public {
        vm.expectRevert();
        appleTree.mint(user1, "ipfs://test");

        vm.startPrank(user1);
        vm.expectRevert();
        appleTree.mint(user1, "ipfs://test");
        vm.stopPrank();
    }

    function test_GrantModerator() public {
        vm.startPrank(owner);
        appleTree.grantRole(appleTree.MODERATOR_ROLE(), moderator);
        vm.stopPrank();

        vm.startPrank(moderator);
        appleTree.mint(user1, "ipfs://test");
        assertEq(appleTree.ownerOf(1), user1);
        vm.stopPrank();
    }

    function test_StateOf() public {
        vm.startPrank(owner);
        appleTree.mint(user1, "ipfs://test");
        vm.stopPrank();

        bytes memory state = appleTree.stateOf(1);
        bytes memory expected = abi.encodePacked(user1, uint256(0), uint256(1));
        assertEq(state, expected);
    }

    function test_NonceIncrement() public {
        vm.startPrank(owner);
        appleTree.mint(user1, "ipfs://test");
        vm.stopPrank();

        assertEq(appleTree.nonces(1), 0);

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit NonceIncremented(1, user1, user2, 1);

        appleTree.transferFrom(user1, user2, 1);
        assertEq(appleTree.nonces(1), 1);
        vm.stopPrank();
    }

    function test_SupportsInterface() public view {
        assertTrue(appleTree.supportsInterface(type(IERC721State).interfaceId));
        assertTrue(appleTree.supportsInterface(type(IERC721Common).interfaceId));
    }
}
