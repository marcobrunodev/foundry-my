// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721Common} from "../common/ronin/ERC721Common.sol";

/**
 * @title Gueio
 * @dev Upgradeable ERC721 NFT contract with enumerable and URI storage extensions
 * @notice This contract implements a limited supply NFT collection with batch minting capabilities
 * @author Marco Bruno
 */
contract Gueio is ERC721Common
{
    /// @dev Error thrown when trying to mint beyond the maximum supply
    error MaxSupplyReached();

    /// @dev Error thrown when batch mint arrays have different lengths
    error ArrayLengthMismatch();

    /// @dev Error thrown when batch minting would exceed maximum supply
    error MaxSupplyExceeded();

    /// @notice Maximum number of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 512;

    /// @dev Tracks the next token ID to be minted
    uint256 private _nextTokenId;

    /// @notice Emitted when a new token is minted
    /// @param to The address that received the token
    /// @param tokenId The ID of the minted token
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    /// @dev Emitted when multiple tokens are minted in a batch operation
    /// @param count The number of tokens minted in the batch
    /// @param startTokenId The first token ID in the batch
    /// @param endTokenId The last token ID in the batch
    event BatchMinted(uint256 count, uint256 indexed startTokenId, uint256 indexed endTokenId);

    /// @dev Emitted when the contract is initialized
    /// @param owner The initial owner of the contract
    /// @param maxSupply The maximum supply of tokens
    event ContractInitialized(address indexed owner, uint256 maxSupply);

    /// @dev Emitted when supply warning thresholds are reached
    /// @param remainingSupply The remaining tokens that can be minted
    /// @param totalMinted The total tokens minted so far
    event SupplyWarning(uint256 remainingSupply, uint256 totalMinted);

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

        emit ContractInitialized(initialOwner, MAX_SUPPLY);
    }

    /**
     * @notice Mints a new token to the specified address with the given URI
     * @dev Only the contract owner can call this function
     * @param to The address that will receive the minted token
     * @param uri The metadata URI for the token
     * @dev Reverts if the maximum supply has been reached
     */
    function mint(address to, string memory uri) public onlyOwner {
        if (_nextTokenId > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit TokenMinted(to, tokenId);

        // Emit supply warning when approaching limits
        uint256 remaining = remainingSupply();
        if (remaining <= 50 && remaining > 0) {
            emit SupplyWarning(remaining, totalMinted());
        }
    }

    /**
     * @notice Mints multiple tokens to multiple addresses with corresponding URIs
     * @dev Only the contract owner can call this function
     * @param to Array of addresses that will receive the minted tokens
     * @param uris Array of metadata URIs for the tokens
     * @dev Reverts if arrays have different lengths or if minting would exceed maximum supply
     */
    function batchMint(address[] memory to, string[] memory uris) public onlyOwner {
        if (to.length != uris.length) {
            revert ArrayLengthMismatch();
        }
        if (_nextTokenId + to.length - 1 > MAX_SUPPLY) {
            revert MaxSupplyExceeded();
        }

        uint256 startTokenId = _nextTokenId;

        for (uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;

            _safeMint(to[i], tokenId);
            _setTokenURI(tokenId, uris[i]);

            emit TokenMinted(to[i], tokenId);
        }

        uint256 endTokenId = _nextTokenId - 1;
        emit BatchMinted(to.length, startTokenId, endTokenId);

        // Emit supply warning when approaching limits
        uint256 remaining = remainingSupply();
        if (remaining <= 50 && remaining > 0) {
            emit SupplyWarning(remaining, totalMinted());
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

}
