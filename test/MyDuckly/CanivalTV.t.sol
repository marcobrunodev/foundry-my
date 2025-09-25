// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {CanivalTV} from "../../src/MyDuckly/CanivalTV.sol";
import {IERC721State} from "../../src/interfaces/IERC721State.sol";
import {IERC721Common} from "../../src/interfaces/IERC721Common.sol";

contract CanivalTVTest is Test {
    CanivalTV public canivalTV;
    CanivalTV public implementation;
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

        implementation = new CanivalTV();

        bytes memory data = abi.encodeWithSelector(CanivalTV.initialize.selector, owner);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        canivalTV = CanivalTV(address(proxy));

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(canivalTV.name(), "MyDuckly Canival TV");
        assertEq(canivalTV.symbol(), "MDCTV");
        assertEq(canivalTV.owner(), owner);
        assertEq(canivalTV.MAX_SUPPLY(), 1024);
        assertEq(canivalTV.totalMinted(), 0);
        assertEq(canivalTV.remainingSupply(), 1024);
        assertTrue(canivalTV.hasRole(canivalTV.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(canivalTV.hasRole(canivalTV.MODERATOR_ROLE(), owner));
    }

    function test_Mint() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 1);

        canivalTV.mint(user1, "ipfs://test1");

        assertEq(canivalTV.totalMinted(), 1);
        assertEq(canivalTV.remainingSupply(), 1023);
        assertEq(canivalTV.ownerOf(1), user1);
        assertEq(canivalTV.tokenURI(1), "ipfs://test1");

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

        canivalTV.batchMint(recipients, uris);

        assertEq(canivalTV.totalMinted(), 3);
        assertEq(canivalTV.remainingSupply(), 1021);
        assertEq(canivalTV.ownerOf(1), user1);
        assertEq(canivalTV.ownerOf(2), user2);
        assertEq(canivalTV.ownerOf(3), owner);

        vm.stopPrank();
    }

    function test_MaxSupplyReached() public {
        vm.startPrank(owner);

        // Set next token ID to max supply + 1
        for (uint256 i = 1; i <= 1024; i++) {
            canivalTV.mint(user1, string(abi.encodePacked("ipfs://test", vm.toString(i))));
        }

        vm.expectRevert(CanivalTV.MaxSupplyReached.selector);
        canivalTV.mint(user1, "ipfs://overflow");

        vm.stopPrank();
    }

    function test_OnlyModeratorCanMint() public {
        vm.expectRevert();
        canivalTV.mint(user1, "ipfs://test");

        vm.startPrank(user1);
        vm.expectRevert();
        canivalTV.mint(user1, "ipfs://test");
        vm.stopPrank();
    }

    function test_GrantModerator() public {
        vm.startPrank(owner);
        canivalTV.grantRole(canivalTV.MODERATOR_ROLE(), moderator);
        vm.stopPrank();

        vm.startPrank(moderator);
        canivalTV.mint(user1, "ipfs://test");
        assertEq(canivalTV.ownerOf(1), user1);
        vm.stopPrank();
    }

    function test_StateOf() public {
        vm.startPrank(owner);
        canivalTV.mint(user1, "ipfs://test");
        vm.stopPrank();

        bytes memory state = canivalTV.stateOf(1);
        bytes memory expected = abi.encodePacked(user1, uint256(0), uint256(1));
        assertEq(state, expected);
    }

    function test_NonceIncrement() public {
        vm.startPrank(owner);
        canivalTV.mint(user1, "ipfs://test");
        vm.stopPrank();

        assertEq(canivalTV.nonces(1), 0);

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit NonceIncremented(1, user1, user2, 1);

        canivalTV.transferFrom(user1, user2, 1);
        assertEq(canivalTV.nonces(1), 1);
        vm.stopPrank();
    }

    function test_SupportsInterface() public view {
        assertTrue(canivalTV.supportsInterface(type(IERC721State).interfaceId));
        assertTrue(canivalTV.supportsInterface(type(IERC721Common).interfaceId));
    }
}
