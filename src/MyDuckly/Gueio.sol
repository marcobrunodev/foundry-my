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

}
