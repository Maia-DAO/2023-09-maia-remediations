// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {GasParams} from "../interfaces/IRootBridgeAgent.sol";

import {VirtualAccount} from "../VirtualAccount.sol";

interface ICoreRootRouter {
    function bridgeAgentAddress() external view returns (address);
    function hTokenFactoryAddress() external view returns (address);
    function setCoreBranch(
        address _gasRefundee,
        address _coreBranchRouter,
        address _coreBranchBridgeAgent,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable;
}

/**
 * @title  Root Port - Omnichain Token Management Contract
 * @author MaiaDAO
 * @notice Ulysses `RootPort` implementation for Root Omnichain Environment deployment.
 *         This contract is used to manage the deposit and withdrawal of assets
 *         between the Root Omnichain Environment and every Branch Chain in response to
 *         Root Bridge Agents requests. Manages Bridge Agents and their factories as well as
 *         key governance enabled actions such as adding new chains and bridge agent factories.
 */
interface IRootPort {
    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice View Function returns True if the chain Id has been added to the system.
     *  @param _chainId The Layer Zero chainId of the chain.
     * @return bool True if the chain Id has been added to the system.
     */
    function isChainId(uint256 _chainId) external view returns (bool);

    /**
     * @notice View Function returns bridge agent manager for a given root bridge agent.
     *  @param _rootBridgeAgent address of the root bridge agent.
     * @return address address of the bridge agent manager.
     */
    function getBridgeAgentManager(address _rootBridgeAgent) external view returns (address);

    /**
     * @notice View Function returns True if the bridge agent factory has been added to the system.
     *  @param _bridgeAgentFactory The address of the bridge agent factory.
     * @return bool True if the bridge agent factory has been added to the system.
     */
    function isBridgeAgentFactory(address _bridgeAgentFactory) external view returns (bool);

    /**
     * @notice View Function returns True if the address corresponds to a global token.
     *  @param _globalAddress The address of the token in the global chain.
     * @return bool True if the address corresponds to a global token.
     */
    function isGlobalAddress(address _globalAddress) external view returns (bool);

    /**
     * @notice View Function returns Token's Global Address from it's local address.
     *  @param _localAddress The address of the token in the local chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return address The address of the global token.
     */
    function getGlobalTokenFromLocal(address _localAddress, uint256 _srcChainId) external view returns (address);

    /**
     * @notice View Function returns Token's Local Address from it's global address.
     *  @param _globalAddress The address of the token in the global chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return address The address of the local token.
     */
    function getLocalTokenFromGlobal(address _globalAddress, uint256 _srcChainId) external view returns (address);

    /**
     * @notice View Function that returns the local token address from the underlying token address.
     *  @param _underlyingAddress The address of the underlying token.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return address The address of the local token.
     */
    function getLocalTokenFromUnderlying(address _underlyingAddress, uint256 _srcChainId)
        external
        view
        returns (address);

    /**
     * @notice Function that returns Local Token's Local Address on another chain.
     *  @param _localAddress The address of the token in the local chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     *  @param _dstChainId The chainId of the chain where the token is deployed.
     * @return address The address of the local token in the destination chain.
     */
    function getLocalToken(address _localAddress, uint256 _srcChainId, uint256 _dstChainId)
        external
        view
        returns (address);

    /**
     * @notice View Function returns a underlying token address from it's local address.
     *  @param _localAddress The address of the token in the local chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return address The address of the underlying token.
     */
    function getUnderlyingTokenFromLocal(address _localAddress, uint256 _srcChainId) external view returns (address);

    /**
     * @notice Returns the underlying token address given it's global address.
     *  @param _globalAddress The address of the token in the global chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return address The address of the underlying token.
     */
    function getUnderlyingTokenFromGlobal(address _globalAddress, uint256 _srcChainId)
        external
        view
        returns (address);

    /**
     * @notice View Function returns True if Global Token is already added in current chain, false otherwise.
     *  @param _globalAddress The address of the token in the global chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return bool True if Global Token is already added in current chain, false otherwise.
     */
    function isGlobalToken(address _globalAddress, uint256 _srcChainId) external view returns (bool);

    /**
     * @notice View Function returns True if Local Token is already added in current chain, false otherwise.
     *  @param _localAddress The address of the token in the local chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return bool True if Local Token is already added in current chain, false otherwise.
     */
    function isLocalToken(address _localAddress, uint256 _srcChainId) external view returns (bool);

    /**
     * @notice View Function returns True if Local Token is already added in destination chain, false otherwise.
     *  @param _localAddress The address of the token in the local chain.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     *  @param _dstChainId The chainId of the chain where the token is deployed.
     * @return bool True if Local Token is already added in current chain, false otherwise.
     */
    function isLocalToken(address _localAddress, uint256 _srcChainId, uint256 _dstChainId)
        external
        view
        returns (bool);

    /**
     * @notice View Function returns True if the underlying Token is already added in given chain, false otherwise.
     *  @param _underlyingToken The address of the underlying token.
     *  @param _srcChainId The chainId of the chain where the token is deployed.
     * @return bool True if the underlying Token is already added in given chain, false otherwise.
     */
    function isUnderlyingToken(address _underlyingToken, uint256 _srcChainId) external view returns (bool);

    /**
     * @notice View Function returns Virtual Account of a given user.
     *  @param _user The address of the user.
     * @return VirtualAccount user virtual account.
     */
    function getUserAccount(address _user) external view returns (VirtualAccount);

    /**
     * @notice View Function returns True if the router is approved by user request to use their virtual account.
     *  @param _userAccount The virtual account of the user.
     *  @param _router The address of the router.
     * @return bool True if the router is approved by user request to use their virtual account.
     */
    function isRouterApproved(VirtualAccount _userAccount, address _router) external returns (bool);

    /*///////////////////////////////////////////////////////////////
                        BRIDGE AGENT MANAGER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice Allows a root bridge agent to update it's bridge agent manager address.
     *  @param _newManager address of the new bridge agent manager.
     */
    function setBridgeAgentManager(address _newManager) external;

    /*///////////////////////////////////////////////////////////////
                        hTOKEN ACCOUTING FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates root port state to match a new deposit.
     *   @param _to recipient of bridged tokens.
     *   @param _hToken address of the hToken to bridge.
     *   @param _amount amount of hTokens to bridge.
     *   @param _deposit amount of underlying tokens to deposit.
     *   @param _srcChainId chainId of the chain where the tokens are being bridged from.
     */
    function bridgeToRoot(address _to, address _hToken, uint256 _amount, uint256 _deposit, uint256 _srcChainId)
        external;

    /**
     * @notice Updates root port state to match hTokens being bridged to branch.
     *   @param _from depositor of the hTokens to bridge.
     *   @param _hToken address of the hToken to bridge.
     *   @param _amount amount of hTokens to bridge.
     *   @param _deposit amount of underlying tokens to deposit.
     *   @param _dstChainId chainId of the chain where the tokens are being bridged to.
     */
    function bridgeToBranch(address _from, address _hToken, uint256 _amount, uint256 _deposit, uint256 _dstChainId)
        external;

    /**
     * @notice Bridges hTokens from the local arbitrum branch for usage in the root port.
     *   @param _from sender of the hTokens to bridge.
     *   @param _hToken address of the hToken to bridge.
     *   @param _amount amount of hTokens to bridge.
     */
    function bridgeToRootFromLocalBranch(address _from, address _hToken, uint256 _amount) external;

    /**
     * @notice Bridges hTokens from the root port to the local arbitrum branch.
     *   @param _to recipient of the bridged tokens.
     *   @param _hToken address of the hToken to bridge.
     *   @param _amount amount of hTokens to bridge.
     */
    function bridgeToLocalBranchFromRoot(address _to, address _hToken, uint256 _amount) external;

    /**
     * @notice Burns tokens from the Arbitrum Branch Port withdrawer address.
     *   @param _from sender of the tokens to burn.
     *   @param _hToken address of the hToken to burn.
     *   @param _amount amount of tokens to burn.
     */
    function burnFromLocalBranch(address _from, address _hToken, uint256 _amount) external;

    /**
     * @notice Mints new root hTokens to the recipient address in reflection of Artbitrum Branch Port deposit.
     *   @param _to recipient of the newly minted tokens.
     *   @param _hToken address of the hToken to mint.
     *   @param _amount amount of tokens to mint.
     */
    function mintToLocalBranch(address _to, address _hToken, uint256 _amount) external;

    /*///////////////////////////////////////////////////////////////
                        hTOKEN MANAGEMENT FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Setter function to add a new underlying token to the system. Includes the creation of a new local hToken
     *         and global hToken.
     *   @param _globalAddress new root hToken address to set.
     *   @param _localAddress new origin chain local hToken address to set.
     *   @param _underlyingAddress new underlying/native token address to set.
     *   @param _srcChainId chainId of the chain where the token is deployed.
     *
     */
    function setAddresses(
        address _globalAddress,
        address _localAddress,
        address _underlyingAddress,
        uint256 _srcChainId
    ) external;

    /**
     * @notice Setter function to update a Global hToken's Local hToken Address.
     *   @param _globalAddress new hToken address to update.
     *   @param _localAddress new underlying/native token address to set.
     *
     */
    function setLocalAddress(address _globalAddress, address _localAddress, uint256 _srcChainId) external;

    /*///////////////////////////////////////////////////////////////
                    VIRTUAL ACCOUNT MANAGEMENT FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the virtual account given a user address. Creates a new virtual account if one does not exist.
     * @param _user address of the user to get the virtual account for.
     */
    function fetchVirtualAccount(address _user) external returns (VirtualAccount account);

    /**
     * @notice Toggles the approval of a router for virtual account usage.
     * @dev Allows for a router to interact/spend from a user's virtual account.
     * @param _userAccount virtual account to toggle the approval for.
     * @param _router router to toggle the approval for.
     */
    function toggleVirtualAccountApproved(VirtualAccount _userAccount, address _router) external;

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT MANAGEMENT FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new bridge agent to the system.
     * @param _manager address of the manager of the bridge agent.
     * @param _bridgeAgent address of the bridge agent to add.
     */
    function addBridgeAgent(address _manager, address _bridgeAgent) external;

    /**
     * @notice Sets the address of the branch bridge agent connected to a root bridge agent for a given chain.
     * @param _newBranchBridgeAgent address of the new branch bridge agent.
     * @param _rootBridgeAgent address of the root bridge agent.
     * @param _srcChainId chainId of the chain to set the bridge agent for.
     */
    function syncBranchBridgeAgentWithRoot(address _newBranchBridgeAgent, address _rootBridgeAgent, uint256 _srcChainId)
        external;

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Toggles the status of a bridge agent factory.
     * @param _bridgeAgentFactory address of the bridge agent factory to toggle.
     */
    function toggleBridgeAgentFactory(address _bridgeAgentFactory) external;

    /**
     * @notice Adds a new chain to the root port lists of chains and adds core branch contracts to system.
     * @param _coreBranchBridgeAgentAddress address of the core branch bridge agent
     * @param _chainId chainId of the new chain
     * @param _wrappedGasTokenName gas token name of the new chain
     * @param _wrappedGasTokenSymbol gas token symbol of the new chain
     * @param _wrappedGasTokenDecimals gas token decimals of the new chain
     * @param _newLocalBranchWrappedNativeTokenAddress address of the wrapped native local hToken of the new chain
     * @param _newUnderlyingBranchWrappedNativeTokenAddress new branch address of the underlying wrapped native token
     */
    function addNewChain(
        address _coreBranchBridgeAgentAddress,
        uint256 _chainId,
        string memory _wrappedGasTokenName,
        string memory _wrappedGasTokenSymbol,
        uint8 _wrappedGasTokenDecimals,
        address _newLocalBranchWrappedNativeTokenAddress,
        address _newUnderlyingBranchWrappedNativeTokenAddress
    ) external;

    /**
     * @notice Adds an ecosystem hToken to a branch chain
     * @param ecoTokenGlobalAddress ecosystem token global address
     */
    function addEcosystemToken(address ecoTokenGlobalAddress) external;

    /**
     * @notice Sets the core root router and bridge agent
     * @param _coreRootRouter address of the core root router
     * @param _coreRootBridgeAgent address of the core root bridge agent
     */
    function setCoreRootRouter(address _coreRootRouter, address _coreRootBridgeAgent) external;

    /**
     * @notice Sets the core branch router and bridge agent
     * @param _refundee address of the refundee
     * @param _coreBranchRouter address of the core branch router
     * @param _coreBranchBridgeAgent address of the core branch bridge agent
     * @param _dstChainId chainId of the destination chain
     * @param _gParams gas params for the transaction
     */
    function setCoreBranchRouter(
        address _refundee,
        address _coreBranchRouter,
        address _coreBranchBridgeAgent,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable;

    /**
     * @notice Syncs a new core branch router and bridge agent.
     * @param _coreBranchRouter address of the core branch router
     * @param _coreBranchBridgeAgent address of the core branch bridge agent
     * @param _dstChainId chainId of the destination chain
     */
    function syncNewCoreBranchRouter(address _coreBranchRouter, address _coreBranchBridgeAgent, uint16 _dstChainId)
        external;

    /**
     * @notice Allows governance to withdraw any native tokens accumulated from failed transactions.
     *  @param _to address to transfer ETH to.
     */
    function sweep(address _to) external;

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new chain is added to the system.
    event NewChainAdded(uint256 indexed chainId);

    /// @notice Emitted when a new bridge agent factory is added or removed.
    event BridgeAgentFactoryToggled(address indexed bridgeAgentFactory);
    /// @notice Emitted when a new bridge agent is added or removed.
    event BridgeAgentToggled(address indexed bridgeAgent);
    /// @notice Emitted when a new branch bridge agent is added to a root bridge agent.
    event BridgeAgentSynced(address indexed bridgeAgent, address indexed rootBridgeAgent, uint256 indexed srcChainId);

    /// @notice Emitted when a new Virtual Account is created.
    event VirtualAccountCreated(address indexed user, address account);

    /// @notice Emitted when a new local token is added to the system.
    event LocalTokenAdded(
        address indexed underlyingAddress, address indexed localAddress, address indexed globalAddress, uint256 chainId
    );
    /// @notice Emitted when a new global token is added to the system.
    event GlobalTokenAdded(address indexed localAddress, address indexed globalAddress, uint256 indexed chainId);
    /// @notice Emitted when a new Ecosystem Token is added to the system.
    event EcosystemTokenAdded(address indexed ecoTokenGlobalAddress);

    /// @notice Emitted when the Core Root Router and Bridge Agent are set.
    event CoreRootSet(address indexed coreRootRouter, address indexed coreRootBridgeAgent);
    /// @notice Emitted when a new Core Branch Router and Bridge Agent are set.
    event CoreBranchSet(
        address indexed coreBranchRouter, address indexed coreBranchBridgeAgent, uint16 indexed dstChainId
    );
    /// @notice Emitted when a new Core Branch Router and Bridge Agent are synced with the root environment.
    event CoreBranchSynced(
        address indexed coreBranchRouter, address indexed coreBranchBridgeAgent, uint16 indexed dstChainId
    );

    /*///////////////////////////////////////////////////////////////
                            ERRORS  
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when owner tries to renounce ownership.
    error RenounceOwnershipNotAllowed();

    /// @notice Error emitted when Set Up period is over.
    error SetUpEnded();
    /// @notice Error emitted when Core Set Up period is over.
    error SetUpCoreEnded();

    /// @notice Error emitted when hToken minting fails.
    error UnableToMint();
    /// @notice Error emitted when hToken bridging fails due to insufficient balance.
    error InsufficientBalance();

    /// @notice Error emitted when an invalid global token address is provided.
    error InvalidGlobalAddress();
    /// @notice Error emitted when an invalid local token address is provided.
    error InvalidLocalAddress();
    /// @notice Error emitted when an invalid underlying token address is provided.
    error InvalidUnderlyingAddress();
    /// @notice Error emitted when zero address is provided for Virtual Account creation.
    error InvalidUserAddress();
    /// @notice Error emitted when zero address is provided for CoreRootRouter.
    error InvalidCoreRootRouter();
    /// @notice Error emitted when zero address is provided for CoreRootBridgeAgent.
    error InvalidCoreRootBridgeAgent();
    /// @notice Error emitted when zero address is provided for CoreBranchRouter.
    error InvalidCoreBranchRouter();
    /// @notice Error emitted when zero address is provided for CoreBranchBridgeAgent.
    error InvalidCoreBrancBridgeAgent();
    /// @notice Error emitted when zero address is provided for RootBridgeAgentFactory.
    error InvalidRootBridgeAgentFactory();
    /// @notice Error emitted when zero address is provided for Branch Port.
    error InvalidBranchPort();

    /// @notice Error emitted when caller is not a Bridge Agent Factory.
    error UnrecognizedBridgeAgentFactory();
    /// @notice Error emitted when caller is not a Bridge Agent.
    error UnrecognizedBridgeAgent();
    /// @notice Error emitted when caller is not the Core Root Router.
    error UnrecognizedCoreRootRouter();
    /// @notice Error emitted when caller is not the Arbitrum Branch
    error UnrecognizedLocalBranchPort();
    /// @notice Error emitted when Core Root Bridge Agent being added isn't added as Bridge Agent yet.
    error UnrecognizedCoreRootBridgeAgent();

    /// @notice Error emitted when trying to add a chain that already exists.
    error AlreadyAddedChain();
    /// @notice Error emitted when trying to add a token that already exists as an Ecosystem Token.
    error AlreadyAddedEcosystemToken();

    /// @notice Error emitted when trying to add a Bridge Agent that already exists.
    error AlreadyAddedBridgeAgent();
    /// @notice Error emitted when trying to add a Bridge Agent Factory that already exists.
    error AlreadyAddedBridgeAgentFactory();
    /// @notice Error emitted when trying to add a chain to a Root Bridge Agent without a Bridge Agent Manager allowing.
    error BridgeAgentNotAllowed();
}
