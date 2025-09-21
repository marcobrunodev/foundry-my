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

/**
 * @title Gueio
 * @dev Upgradeable ERC721 NFT contract with enumerable and URI storage extensions
 * @notice This contract implements a limited supply NFT collection with batch minting capabilities
 * @author Marco Bruno
 */
contract Gueio is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @notice Maximum number of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 512;

    /// @dev Tracks the next token ID to be minted
    uint256 private _nextTokenId;

    /// @notice Emitted when a new token is minted
    /// @param to The address that received the token
    /// @param tokenId The ID of the minted token
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with the given owner
     * @dev This function replaces the constructor for upgradeable contracts
     * @param initialOwner The address that will own the contract
     */
    function initialize(address initialOwner) public initializer {
        __ERC721_init("Gueio", "GUEIO");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        _nextTokenId = 1;
    }

    /**
     * @notice Mints a new token to the specified address with the given URI
     * @dev Only the contract owner can call this function
     * @param to The address that will receive the minted token
     * @param uri The metadata URI for the token
     * @dev Reverts if the maximum supply has been reached
     */
    function mint(address to, string memory uri) public onlyOwner {
        require(_nextTokenId <= MAX_SUPPLY, "Gueio: max supply reached");

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit TokenMinted(to, tokenId);
    }

    /**
     * @notice Mints multiple tokens to multiple addresses with corresponding URIs
     * @dev Only the contract owner can call this function
     * @param to Array of addresses that will receive the minted tokens
     * @param uris Array of metadata URIs for the tokens
     * @dev Reverts if arrays have different lengths or if minting would exceed maximum supply
     */
    function batchMint(address[] memory to, string[] memory uris) public onlyOwner {
        require(to.length == uris.length, "Gueio: arrays length mismatch");
        require(_nextTokenId + to.length - 1 <= MAX_SUPPLY, "Gueio: max supply exceeded");

        for (uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;

            _safeMint(to[i], tokenId);
            _setTokenURI(tokenId, uris[i]);

            emit TokenMinted(to[i], tokenId);
        }
    }

    /**
     * @notice Returns the total number of tokens that have been minted
     * @return The total count of minted tokens
     */
    function totalMinted() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * @notice Returns the number of tokens that can still be minted
     * @return The remaining supply of tokens
     */
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted();
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
        return super._update(to, tokenId, auth);
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
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
