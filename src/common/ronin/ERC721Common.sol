// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721URIStorageUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {IERC721State} from "../../interfaces/IERC721State.sol";
import {IERC721Common} from "../../interfaces/IERC721Common.sol";

/**
 * @title ERC721Common
 * @dev Abstract base contract implementing Ronin Marketplace compatibility
 * @notice Provides common functionality for ERC721 tokens compatible with Ronin Marketplace
 * @author Marco Bruno
 */
abstract contract ERC721Common is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    MulticallUpgradeable,
    IERC721Common
{
    /// @dev Error thrown when querying state for a non-existent token
    /// @param tokenId The token ID that was queried
    error QueryForNonexistentToken(uint256 tokenId);

    /// @dev Emitted when a token's nonce is incremented during transfer
    /// @param tokenId The ID of the token whose nonce was incremented
    /// @param from The previous owner of the token
    /// @param to The new owner of the token
    /// @param newNonce The new nonce value
    event NonceIncremented(uint256 indexed tokenId, address indexed from, address indexed to, uint256 newNonce);

    /// @dev Emitted when token state is queried (useful for analytics)
    /// @param tokenId The ID of the token that was queried
    /// @param owner The current owner of the token
    /// @param nonce The current nonce of the token
    event StateQueried(uint256 indexed tokenId, address indexed owner, uint256 nonce);

    /// @dev Mapping to track nonces for each token (required for Ronin Marketplace)
    mapping(uint256 => uint256) public nonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Returns the current state of a token (required for Ronin Marketplace)
     * @dev Returns packed bytes containing owner address, nonce, and token ID
     * @param tokenId The token ID to get the state for
     * @return The packed state data as bytes
     */
    function stateOf(uint256 tokenId) external view returns (bytes memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert QueryForNonexistentToken(tokenId);
        }

        address owner = ownerOf(tokenId);
        uint256 nonce = nonces[tokenId];

        // Note: Events in view functions don't actually emit, but this shows the pattern
        // In a real scenario, you might want to track this off-chain or in a separate function

        return abi.encodePacked(owner, nonce, tokenId);
    }

    /**
     * @dev Authorizes contract upgrades. Only the owner can upgrade the contract
     * @param newImplementation The address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Hook that is called before any token transfer
     * @param to The address the token is being transferred to
     * @param tokenId The ID of the token being transferred
     * @param auth The address authorized to make the transfer
     * @return The previous owner of the token
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        address previousOwner = super._update(to, tokenId, auth);

        // Increment nonce when token is transferred (but not when minted)
        if (previousOwner != address(0)) {
            nonces[tokenId]++;
            emit NonceIncremented(tokenId, previousOwner, to, nonces[tokenId]);
        }

        return previousOwner;
    }

    /**
     * @dev Internal function to increase the balance of an account
     * @param account The address whose balance is being increased
     * @param value The amount to increase the balance by
     */
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._increaseBalance(account, value);
    }

    /**
     * @notice Returns the metadata URI for a given token
     * @param tokenId The ID of the token to get the URI for
     * @return The metadata URI for the token
     * @dev Reverts if the token does not exist
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Checks if the contract supports a given interface
     * @param interfaceId The interface identifier to check
     * @return True if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721State).interfaceId || interfaceId == type(IERC721Common).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
