// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title  Branch Port - Omnichain Token Management Contract
 * @author MaiaDAO
 * @notice Ulyses `Port` implementation for Branch Chain deployment. This contract
 *         is used to manage the deposit and withdrawal of underlying assets from
 *         the Branch Chain in response to Branch Bridge Agents' requests.
 *         Manages Bridge Agents and their factories as well as the chain's strategies and
 *         their tokens.
 */
interface IBranchPort {
    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns true if the address is a Bridge Agent.
     *   @param _bridgeAgent Bridge Agent address.
     *   @return bool.
     */
    function isBridgeAgent(address _bridgeAgent) external view returns (bool);

    /**
     * @notice Returns true if the address is a Strategy Token.
     *   @param _token token address.
     *   @return bool.
     */
    function isStrategyToken(address _token) external view returns (bool);

    /**
     * @notice Returns true if the address is a Port Strategy.
     *   @param _strategy strategy address.
     *   @param _token token address.
     *   @return bool.
     */
    function isPortStrategy(address _strategy, address _token) external view returns (bool);

    /**
     * @notice Returns true if the address is a Bridge Agent Factory.
     *   @param _bridgeAgentFactory Bridge Agent Factory address.
     *   @return bool.
     */
    function isBridgeAgentFactory(address _bridgeAgentFactory) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
                          PORT STRATEGY MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows active Port Strategy addresses to withdraw assets.
     *  @param _token token address.
     *  @param _amount amount of tokens.
     */
    function manage(address _token, uint256 _amount) external;

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     *  @param _amount uint
     *  @param _token address
     *  @dev must be called by the port strategy itself
     */
    function replenishReserves(address _token, uint256 _amount) external;

    /**
     * @notice allow approved address to repay borrowed reserves and replenish a given token's reserves
     *  @param _strategy address
     *  @param _token address
     *  @dev can be called by anyone to ensure availability of service
     */
    function replenishReserves(address _strategy, address _token) external;

    /*///////////////////////////////////////////////////////////////
                          hTOKEN MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to withdraw underlying/native token amount into Port in exchange for Local hToken.
     *   @param _recipient hToken receiver.
     *   @param _underlyingAddress underlying/native token address.
     *   @param _amount amount of tokens.
     *
     */
    function withdraw(address _recipient, address _underlyingAddress, uint256 _amount) external;

    /**
     * @notice Setter function to increase local hToken supply.
     *   @param _recipient hToken receiver.
     *   @param _localAddress token address.
     *   @param _amount amount of tokens.
     *
     */
    function bridgeIn(address _recipient, address _localAddress, uint256 _amount) external;

    /**
     * @notice Setter function to increase local hToken supply.
     *   @param _recipient hToken receiver.
     *   @param _localAddresses token addresses.
     *   @param _amounts amount of tokens.
     *
     */
    function bridgeInMultiple(
        address _recipient,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external;

    /**
     * @notice Setter function to decrease local hToken supply.
     *   @param _localAddress token address.
     *   @param _amount amount of tokens.
     *   @param _deposit amount of underlying tokens.
     *
     */
    function bridgeOut(
        address _depositor,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit
    ) external;

    /**
     * @notice Setter function to decrease local hToken supply.
     *   @param _depositor user to deduct balance from.
     *   @param _localAddresses local token addresses.
     *   @param _underlyingAddresses local token address.
     *   @param _amounts amount of local tokens.
     *   @param _deposits amount of underlying tokens.
     *
     */
    function bridgeOutMultiple(
        address _depositor,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external;

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new bridge agent address to the branch port.
     *   @param _bridgeAgent address of the bridge agent to add to the Port
     */
    function addBridgeAgent(address _bridgeAgent) external;

    /**
     * @notice Toggle a given bridge agent factory. If it's active, it will de-activate it and vice-versa.
     *   @param _bridgeAgentFactory address of the bridge agent factory to add to the Port
     */
    function toggleBridgeAgentFactory(address _bridgeAgentFactory) external;

    /**
     * @notice Toggle a given strategy token. If it's active, it will de-activate it and vice-versa.
     * @param _token address of the token to add to the Strategy Tokens
     * @param _minimumReservesRatio minimum reserves ratio for the token
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function toggleStrategyToken(address _token, uint256 _minimumReservesRatio) external;

    /**
     * @notice Update an active strategy token's minimum reserves ratio. If it is not active, it will revert.
     * @param _token address of the token to add to the Strategy Tokens
     * @param _minimumReservesRatio minimum reserves ratio for the token
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function updateStrategyToken(address _token, uint256 _minimumReservesRatio) external;

    /**
     * @notice Add or Remove a Port Strategy.
     * @param _portStrategy Address of the Port Strategy to be added for use in Branch strategies.
     * @param _underlyingToken Address of the underlying token to be added for use in Branch strategies.
     * @param _dailyManagementLimit Daily management limit of the given token for the Port Strategy.
     * @param _reserveRatioManagementLimit Total reserves management limit of the given token for the Port Strategy.
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function togglePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) external;

    /**
     * @notice Updates a Port Strategy.
     * @param _portStrategy Address of the Port Strategy to be added for use in Branch strategies.
     * @param _underlyingToken Address of the underlying token to be added for use in Branch strategies.
     * @param _dailyManagementLimit Daily management limit of the given token for the Port Strategy.
     * @param _reserveRatioManagementLimit Total reserves management limit of the given token for the Port Strategy.
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function updatePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) external;

    /**
     * @notice Sets the core branch router and bridge agent for the branch port.
     *   @param _coreBranchRouter address of the new core branch router
     *   @param _coreBranchBridgeAgent address of the new core branch bridge agent
     */
    function setCoreBranchRouter(address _coreBranchRouter, address _coreBranchBridgeAgent) external;

    /**
     * @notice Allows governance to claim any native tokens accumulated from failed transactions.
     *  @param _recipient address to transfer ETH to.
     */
    function sweep(address _recipient) external;

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    ///////////////////////////////////////////////////////////////*/

    event DebtCreated(address indexed _strategy, address indexed _token, uint256 _amount);
    event DebtRepaid(address indexed _strategy, address indexed _token, uint256 _amount);

    event StrategyTokenUpdated(address indexed _token, uint256 indexed _minimumReservesRatio);

    event PortStrategyUpdated(
        address indexed _portStrategy,
        address indexed _token,
        uint256 indexed _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    );

    event BridgeAgentFactoryToggled(address indexed _bridgeAgentFactory);

    event BridgeAgentToggled(address indexed _bridgeAgent);

    event CoreBranchSet(address indexed _coreBranchRouter, address indexed _coreBranchBridgeAgent);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    ///////////////////////////////////////////////////////////////*/

    error AlreadyAddedBridgeAgent();
    error AlreadyAddedBridgeAgentFactory();
    error InvalidMinimumReservesRatio();
    error InvalidInputArrays();
    error InsufficientReserves();
    error ExceedsReserveRatioManagementLimit();
    error UnrecognizedCore();
    error UnrecognizedBridgeAgent();
    error UnrecognizedBridgeAgentFactory();
    error UnrecognizedPortStrategy();
    error UnrecognizedStrategyToken();
    error NotEnoughDebtToRepay();

    /// @notice Error emitted when an invalid underlying token address is provided.
    error InvalidUnderlyingAddress();
}
