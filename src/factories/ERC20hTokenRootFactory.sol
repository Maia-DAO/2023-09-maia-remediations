// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20hTokenRootFactory, ERC20hToken} from "../interfaces/IERC20hTokenRootFactory.sol";

/// @title ERC20 hToken Root Factory Contract
/// @author MaiaDAO
contract ERC20hTokenRootFactory is Ownable, IERC20hTokenRootFactory {
    /// @notice Root Port Address.
    address public immutable rootPortAddress;

    /// @notice Root Core Router Address, in charge of the addition of new tokens to the system.
    address public coreRootRouterAddress;

    /// @notice Array of all hTokens created.
    ERC20hToken[] public hTokens;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for ERC20 hToken Root Factory Contract
     *  @param _rootPortAddress Root Port Address.
     */
    constructor(address _rootPortAddress) {
        require(_rootPortAddress != address(0), "Root Port Address cannot be 0");
        rootPortAddress = _rootPortAddress;
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to initialize the contract.
     * @param _coreRouter Address of the Root Chain's Core Router.
     */
    function initialize(address _coreRouter) external onlyOwner {
        require(_coreRouter != address(0), "CoreRouter address cannot be 0");
        renounceOwnership();

        coreRootRouterAddress = _coreRouter;
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to get the array of hTokens.
     * @return Array of hTokens.
     */
    function getHTokens() external view returns (ERC20hToken[] memory) {
        return hTokens;
    }

    /*///////////////////////////////////////////////////////////////
                    hTOKEN FACTORY EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice Function to create a new hToken.
     * @param _name Name of the Token.
     * @param _symbol Symbol of the Token.
     * @param _decimals Decimals of the Token.
     */
    function createToken(string memory _name, string memory _symbol, uint8 _decimals)
        external
        requiresCoreRouterOrPort
        returns (ERC20hToken newToken)
    {
        newToken = new ERC20hToken(
            rootPortAddress,
            _name,
            _symbol,
            _decimals
        );

        hTokens.push(newToken);
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/
    /// @notice Modifier that verifies msg sender is the RootInterface Contract from Root Chain.
    modifier requiresCoreRouterOrPort() {
        if (msg.sender != coreRootRouterAddress) {
            if (msg.sender != rootPortAddress) {
                revert UnrecognizedCoreRouterOrPort();
            }
        }
        _;
    }
}
