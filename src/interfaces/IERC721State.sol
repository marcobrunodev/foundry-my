// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IERC721State
 * @dev Interface for ERC721 tokens with state tracking functionality required by Ronin Marketplace
 */
interface IERC721State {
    /**
     * @notice Returns the current state of a token
     * @dev Returns packed bytes containing owner address, nonce, and token ID
     * @param tokenId The token ID to get the state for
     * @return The packed state data as bytes
     */
    function stateOf(uint256 tokenId) external view returns (bytes memory);
}
