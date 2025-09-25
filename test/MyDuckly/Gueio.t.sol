// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Gueio} from "../../src/MyDuckly/Gueio.sol";
import {IERC721State} from "../../src/interfaces/IERC721State.sol";
import {IERC721Common} from "../../src/interfaces/IERC721Common.sol";

contract GueioTest is Test {
    Gueio public gueio;
    Gueio public implementation;
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

        implementation = new Gueio();

        bytes memory data = abi.encodeWithSelector(Gueio.initialize.selector, owner);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        gueio = Gueio(address(proxy));

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(gueio.name(), "Gueio");
        assertEq(gueio.symbol(), "GO");
        assertEq(gueio.owner(), owner);
        assertEq(gueio.MAX_SUPPLY(), 512);
        assertEq(gueio.totalMinted(), 0);
        assertEq(gueio.remainingSupply(), 512);

        // Check access control roles
        assertTrue(gueio.hasRole(gueio.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(gueio.hasRole(gueio.MODERATOR_ROLE(), owner));
        assertFalse(gueio.hasRole(gueio.MODERATOR_ROLE(), user1));
        assertFalse(gueio.hasRole(gueio.MODERATOR_ROLE(), user2));
    }

    function test_ContractInitialization() public {
        vm.startPrank(owner);

        Gueio newImplementation = new Gueio();

        vm.expectEmit(true, false, false, true);
        emit ContractInitialized(owner, 512);

        bytes memory data = abi.encodeWithSelector(Gueio.initialize.selector, owner);
        new ERC1967Proxy(address(newImplementation), data);

        vm.stopPrank();
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

        vm.expectEmit(true, true, false, true);
        emit BatchMinted(3, 1, 3);

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

    function test_MintOnlyModerator() public {
        vm.startPrank(user1);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user1, gueio.MODERATOR_ROLE()
            )
        );
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

        vm.expectRevert(abi.encodeWithSignature("ArrayLengthMismatch()"));
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

        vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached()"));
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

        vm.expectRevert(abi.encodeWithSignature("MaxSupplyExceeded()"));
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
        assertTrue(gueio.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(gueio.supportsInterface(0x780e9d63)); // ERC721Enumerable
        assertTrue(gueio.supportsInterface(0x5b5e139f)); // ERC721Metadata
        assertTrue(gueio.supportsInterface(type(IERC721State).interfaceId)); // IERC721State
        assertTrue(gueio.supportsInterface(type(IERC721Common).interfaceId)); // IERC721Common
        assertTrue(gueio.supportsInterface(type(IAccessControl).interfaceId)); // IAccessControl
    }

    function test_Upgrade() public {
        vm.startPrank(owner);

        Gueio newImplementation = new Gueio();

        gueio.upgradeToAndCall(address(newImplementation), "");

        assertEq(gueio.name(), "Gueio");
        assertEq(gueio.symbol(), "GO");
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

    function test_StateOf() public {
        vm.startPrank(owner);

        string memory uri = "ipfs://QmTestHash1";
        gueio.mint(user1, uri);

        bytes memory state = gueio.stateOf(1);
        bytes memory expectedState = abi.encodePacked(user1, uint256(0), uint256(1));

        assertEq(state, expectedState);
        assertEq(gueio.nonces(1), 0);

        vm.stopPrank();
    }

    function test_StateOfNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSignature("QueryForNonexistentToken(uint256)", 999));
        gueio.stateOf(999);
    }

    function test_NoncesIncrementOnTransfer() public {
        vm.startPrank(owner);

        string memory uri = "ipfs://QmTestHash1";
        gueio.mint(user1, uri);

        assertEq(gueio.nonces(1), 0);

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectEmit(true, true, true, true);
        emit NonceIncremented(1, user1, user2, 1);

        gueio.transferFrom(user1, user2, 1);
        vm.stopPrank();

        assertEq(gueio.nonces(1), 1);
    }

    function test_StateChangesAfterTransfer() public {
        vm.startPrank(owner);

        string memory uri = "ipfs://QmTestHash1";
        gueio.mint(user1, uri);

        bytes memory initialState = gueio.stateOf(1);
        bytes memory expectedInitialState = abi.encodePacked(user1, uint256(0), uint256(1));
        assertEq(initialState, expectedInitialState);

        vm.stopPrank();

        vm.startPrank(user1);
        gueio.transferFrom(user1, user2, 1);
        vm.stopPrank();

        bytes memory newState = gueio.stateOf(1);
        bytes memory expectedNewState = abi.encodePacked(user2, uint256(1), uint256(1));
        assertEq(newState, expectedNewState);

        assertTrue(keccak256(initialState) != keccak256(newState));
    }

    function test_MultipleTransfersIncrementNonces() public {
        vm.startPrank(owner);

        string memory uri = "ipfs://QmTestHash1";
        gueio.mint(user1, uri);

        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit NonceIncremented(1, user1, user2, 1);
        gueio.transferFrom(user1, user2, 1);
        vm.stopPrank();

        assertEq(gueio.nonces(1), 1);

        vm.startPrank(user2);
        vm.expectEmit(true, true, true, true);
        emit NonceIncremented(1, user2, owner, 2);
        gueio.transferFrom(user2, owner, 1);
        vm.stopPrank();

        assertEq(gueio.nonces(1), 2);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit NonceIncremented(1, owner, user1, 3);
        gueio.transferFrom(owner, user1, 1);
        vm.stopPrank();

        assertEq(gueio.nonces(1), 3);
    }

    function test_Multicall() public {
        vm.startPrank(owner);

        // Prepare multiple mint calls
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeWithSelector(Gueio.mint.selector, user1, "ipfs://token1");
        calls[1] = abi.encodeWithSelector(Gueio.mint.selector, user2, "ipfs://token2");
        calls[2] = abi.encodeWithSelector(Gueio.mint.selector, owner, "ipfs://token3");

        // Execute all mints in a single transaction
        gueio.multicall(calls);

        // Verify all tokens were minted
        assertEq(gueio.balanceOf(user1), 1);
        assertEq(gueio.balanceOf(user2), 1);
        assertEq(gueio.balanceOf(owner), 1);
        assertEq(gueio.totalMinted(), 3);

        // Verify token URIs
        assertEq(gueio.tokenURI(1), "ipfs://token1");
        assertEq(gueio.tokenURI(2), "ipfs://token2");
        assertEq(gueio.tokenURI(3), "ipfs://token3");

        vm.stopPrank();
    }

    function test_MulticallMixedOperations() public {
        vm.startPrank(owner);

        // First mint a token
        gueio.mint(user1, "ipfs://initial");

        vm.stopPrank();
        vm.startPrank(user1);

        // Now user1 can transfer and owner can mint in single multicall
        vm.stopPrank();
        vm.startPrank(owner);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(Gueio.mint.selector, user2, "ipfs://newtoken");
        calls[1] = abi.encodeWithSelector(Gueio.mint.selector, owner, "ipfs://ownertoken");

        gueio.multicall(calls);

        assertEq(gueio.totalMinted(), 3);
        assertEq(gueio.balanceOf(user2), 1);
        assertEq(gueio.balanceOf(owner), 1);

        vm.stopPrank();
    }

    // ============ Access Control Tests ============

    function test_GrantModeratorRole() public {
        vm.startPrank(owner);

        assertFalse(gueio.hasRole(gueio.MODERATOR_ROLE(), moderator));

        gueio.grantRole(gueio.MODERATOR_ROLE(), moderator);

        assertTrue(gueio.hasRole(gueio.MODERATOR_ROLE(), moderator));

        vm.stopPrank();
    }

    function test_RevokeModeratorRole() public {
        vm.startPrank(owner);

        // First grant the role
        gueio.grantRole(gueio.MODERATOR_ROLE(), moderator);
        assertTrue(gueio.hasRole(gueio.MODERATOR_ROLE(), moderator));

        // Then revoke it
        gueio.revokeRole(gueio.MODERATOR_ROLE(), moderator);
        assertFalse(gueio.hasRole(gueio.MODERATOR_ROLE(), moderator));

        vm.stopPrank();
    }

    function test_OnlyAdminCanGrantRole() public {
        bytes32 moderatorRole = gueio.MODERATOR_ROLE();

        vm.startPrank(user1);

        vm.expectRevert();
        gueio.grantRole(moderatorRole, moderator);

        vm.stopPrank();
    }

    function test_OnlyAdminCanRevokeRole() public {
        bytes32 moderatorRole = gueio.MODERATOR_ROLE();

        vm.startPrank(owner);
        gueio.grantRole(moderatorRole, moderator);
        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert();
        gueio.revokeRole(moderatorRole, moderator);

        vm.stopPrank();
    }

    function test_ModeratorCanMint() public {
        vm.startPrank(owner);
        gueio.grantRole(gueio.MODERATOR_ROLE(), moderator);
        vm.stopPrank();

        vm.startPrank(moderator);

        string memory uri = "ipfs://QmModeratorMint";

        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 1);

        gueio.mint(user1, uri);

        assertEq(gueio.balanceOf(user1), 1);
        assertEq(gueio.ownerOf(1), user1);
        assertEq(gueio.tokenURI(1), uri);

        vm.stopPrank();
    }

    function test_ModeratorCanBatchMint() public {
        vm.startPrank(owner);
        gueio.grantRole(gueio.MODERATOR_ROLE(), moderator);
        vm.stopPrank();

        vm.startPrank(moderator);

        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        string[] memory uris = new string[](2);
        uris[0] = "ipfs://QmModMint1";
        uris[1] = "ipfs://QmModMint2";

        vm.expectEmit(true, true, false, true);
        emit BatchMinted(2, 1, 2);

        gueio.batchMint(recipients, uris);

        assertEq(gueio.balanceOf(user1), 1);
        assertEq(gueio.balanceOf(user2), 1);
        assertEq(gueio.totalMinted(), 2);

        vm.stopPrank();
    }

    function test_RevokedModeratorCannotMint() public {
        vm.startPrank(owner);
        gueio.grantRole(gueio.MODERATOR_ROLE(), moderator);
        vm.stopPrank();

        // Moderator can mint initially
        vm.startPrank(moderator);
        gueio.mint(user1, "ipfs://test1");
        vm.stopPrank();

        // Owner revokes role
        vm.startPrank(owner);
        gueio.revokeRole(gueio.MODERATOR_ROLE(), moderator);
        vm.stopPrank();

        // Moderator can no longer mint
        vm.startPrank(moderator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, moderator, gueio.MODERATOR_ROLE()
            )
        );
        gueio.mint(user2, "ipfs://test2");
        vm.stopPrank();
    }

    function test_SupportsAccessControlInterface() public view {
        assertTrue(gueio.supportsInterface(type(IAccessControl).interfaceId));
    }
}
