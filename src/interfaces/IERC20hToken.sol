// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  ERC20 hToken Branch Contract
 * @author MaiaDAO.
 * @notice ERC20 hToken contract deployed in the Branch Chains of the Ulysses Omnichain Liquidity System.
 *         ERC20 representation of a token deposited in a  Branch Chain's Port. Is only minted upon
 *         user request otherwise underlying tokens are cleared and the matching Root hToken has been burned.
 * @dev    If this is a root hToken, this asset is minted / burned in reflection of it's origin Branch Port balance.
 *         Should not be burned being stored in Root Port instead if Branch hToken mint is requested.
 */
interface IERC20hToken {
    /*///////////////////////////////////////////////////////////////
                                ERC20 LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to mint tokens in the Branch Chain.
     * @param account Address of the account to receive the tokens.
     * @param amount Amount of tokens to be minted.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Function to burn tokens in the Branch Chain.
     * @param account Address of the account to burn the tokens from.
     * @param amount Amount of tokens to be burned.
     */
    function burn(address account, uint256 amount) external;

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error thrown when the Port Address is the zero address.
    error InvalidPortAddress();
}
