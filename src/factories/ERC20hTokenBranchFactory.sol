// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {ERC20} from "../token/ERC20hToken.sol";

import {IERC20hTokenBranchFactory, ERC20hToken} from "../interfaces/IERC20hTokenBranchFactory.sol";

/// @title ERC20hToken Branch Factory Contract
/// @author MaiaDAO
contract ERC20hTokenBranchFactory is Ownable, IERC20hTokenBranchFactory {
    /// @notice Local Port Address
    address public immutable localPortAddress;

    /// @notice Local Branch Core Router Address responsible for the addition of new tokens to the system.
    address public localCoreRouterAddress;

    /// @notice Local hTokens deployed in the current chain.
    ERC20hToken[] public hTokens;

    /// @notice Name of the chain for token name prefix.
    string public chainName;

    /// @notice Symbol of the chain for token symbol prefix.
    string public chainSymbol;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for ERC20 hToken Branch Factory Contract
     *  @param _localPortAddress Local Chain Port Address.
     *  @param _chainName Name of the chain for token name prefix.
     *  @param _chainSymbol Symbol of the chain for token symbol prefix.
     */
    constructor(address _localPortAddress, string memory _chainName, string memory _chainSymbol) {
        require(_localPortAddress != address(0), "Port address cannot be 0");
        chainName = string.concat(_chainName, " Ulysses");
        chainSymbol = string.concat(_chainSymbol, "-u");
        localPortAddress = _localPortAddress;
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to initialize the contract.
     * @param _wrappedNativeTokenAddress Address of the Local Chain's wrapped native token.
     * @param _coreRouter Address of the Local Chain's Core Router.
     */
    function initialize(address _wrappedNativeTokenAddress, address _coreRouter) external onlyOwner {
        require(_coreRouter != address(0), "CoreRouter address cannot be 0");
        renounceOwnership();

        ERC20hToken newToken = new ERC20hToken(
            localPortAddress,
            string.concat(chainName, ERC20(_wrappedNativeTokenAddress).name()),
            string.concat(chainSymbol, ERC20(_wrappedNativeTokenAddress).symbol()),
            ERC20(_wrappedNativeTokenAddress).decimals()
        );

        hTokens.push(newToken);

        localCoreRouterAddress = _coreRouter;
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

    /// @inheritdoc IERC20hTokenBranchFactory
    function createToken(string memory _name, string memory _symbol, uint8 _decimals, bool _addPrefix)
        external
        requiresCoreRouter
        returns (ERC20hToken newToken)
    {
        newToken = _addPrefix
            ?
            new ERC20hToken(localPortAddress, string.concat(chainName, _name), string.concat(chainSymbol, _symbol), _decimals)
            : new ERC20hToken(localPortAddress, _name, _symbol, _decimals);

        hTokens.push(newToken);
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Modifier that verifies msg sender is the RootInterface Contract from Root Chain.
    modifier requiresCoreRouter() {
        if (msg.sender != localCoreRouterAddress) revert UnrecognizedCoreRouter();
        _;
    }
}
