// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IBranchPort as IPort} from "./interfaces/IBranchPort.sol";
import {IBranchBridgeAgent as IBridgeAgent, GasParams} from "./interfaces/IBranchBridgeAgent.sol";
import {IBranchBridgeAgentFactory as IBridgeAgentFactory} from "./interfaces/IBranchBridgeAgentFactory.sol";
import {IBranchRouter} from "./interfaces/IBranchRouter.sol";
import {ICoreBranchRouter} from "./interfaces/ICoreBranchRouter.sol";
import {IERC20hTokenBranchFactory as ITokenFactory} from "./interfaces/IERC20hTokenBranchFactory.sol";

import {BaseBranchRouter} from "./BaseBranchRouter.sol";
import {ERC20hToken} from "./token/ERC20hToken.sol";

/// @title Core Branch Router Contract
/// @author MaiaDAO
contract CoreBranchRouter is ICoreBranchRouter, BaseBranchRouter {
    /// @notice hToken Factory Address.
    address public immutable hTokenFactoryAddress;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Core Branch Router.
     * @param _hTokenFactoryAddress Branch hToken Factory Address.
     */
    constructor(address _hTokenFactoryAddress) BaseBranchRouter() {
        hTokenFactoryAddress = _hTokenFactoryAddress;
    }

    /*///////////////////////////////////////////////////////////////
                 TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice This function is used to add a global token to a branch.
     * @param _globalAddress Address of the token to be added.
     * @param _dstChainId Chain Id of the chain to which the deposit is being added.
     * @param _gParams Gas parameters for remote execution.
     */
    function addGlobalToken(address _globalAddress, uint256 _dstChainId, GasParams[3] calldata _gParams)
        external
        payable
    {
        // Encode Call Data
        bytes memory params = abi.encode(msg.sender, _globalAddress, _dstChainId, [_gParams[1], _gParams[2]]);

        // Pack FuncId
        bytes memory payload = abi.encodePacked(bytes1(0x01), params);

        // Send Cross-Chain request (System Response/Request)
        IBridgeAgent(localBridgeAgentAddress).callOut{value: msg.value}(payable(msg.sender), payload, _gParams[0]);
    }

    /**
     * @notice This function is used to add a local token to the system.
     * @param _underlyingAddress Address of the underlying token to be added.
     * @param _gParams Gas parameters for remote execution.
     */
    function addLocalToken(address _underlyingAddress, GasParams calldata _gParams) external payable virtual {
        //Get Token Info
        uint8 decimals = ERC20(_underlyingAddress).decimals();

        //Create Token
        ERC20hToken newToken = ITokenFactory(hTokenFactoryAddress).createToken(
            ERC20(_underlyingAddress).name(), ERC20(_underlyingAddress).symbol(), decimals, true
        );

        //Encode Data
        bytes memory params = abi.encode(_underlyingAddress, newToken, newToken.name(), newToken.symbol(), decimals);

        // Pack FuncId
        bytes memory payload = abi.encodePacked(bytes1(0x02), params);

        //Send Cross-Chain request (System Response/Request)
        IBridgeAgent(localBridgeAgentAddress).callOut{value: msg.value}(payable(msg.sender), payload, _gParams);
    }

    /*///////////////////////////////////////////////////////////////
                    LAYERZERO EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchRouter
    function executeNoSettlement(bytes calldata _params) external payable virtual override requiresAgentExecutor {
        /// _receiveAddGlobalToken
        if (_params[0] == 0x01) {
            (
                address globalAddress,
                string memory name,
                string memory symbol,
                uint8 decimals,
                address refundee,
                GasParams memory gParams
            ) = abi.decode(_params[1:], (address, string, string, uint8, address, GasParams));

            _receiveAddGlobalToken(globalAddress, name, symbol, decimals, refundee, gParams);
            /// _receiveAddBridgeAgent
        } else if (_params[0] == 0x02) {
            (
                address newBranchRouter,
                address branchBridgeAgentFactory,
                address rootBridgeAgent,
                address rootBridgeAgentFactory,
                address refundee,
                GasParams memory gParams
            ) = abi.decode(_params[1:], (address, address, address, address, address, GasParams));

            _receiveAddBridgeAgent(
                newBranchRouter, branchBridgeAgentFactory, rootBridgeAgent, rootBridgeAgentFactory, refundee, gParams
            );

            /// _toggleBranchBridgeAgentFactory
        } else if (_params[0] == 0x03) {
            (address bridgeAgentFactoryAddress) = abi.decode(_params[1:], (address));

            _toggleBranchBridgeAgentFactory(bridgeAgentFactoryAddress);

            /// _toggleStrategyToken
        } else if (_params[0] == 0x04) {
            (address underlyingToken, uint256 minimumReservesRatio) = abi.decode(_params[1:], (address, uint256));

            _toggleStrategyToken(underlyingToken, minimumReservesRatio);

            /// _updateStrategyToken
        } else if (_params[0] == 0x05) {
            (address underlyingToken, uint256 minimumReservesRatio) = abi.decode(_params[1:], (address, uint256));

            _updateStrategyToken(underlyingToken, minimumReservesRatio);

            /// _togglePortStrategy
        } else if (_params[0] == 0x06) {
            (
                address portStrategy,
                address underlyingToken,
                uint256 dailyManagementLimit,
                uint256 reserveRatioManagementLimit
            ) = abi.decode(_params[1:], (address, address, uint256, uint256));

            _togglePortStrategy(portStrategy, underlyingToken, dailyManagementLimit, reserveRatioManagementLimit);

            /// _updatePortStrategy
        } else if (_params[0] == 0x07) {
            (
                address portStrategy,
                address underlyingToken,
                uint256 dailyManagementLimit,
                uint256 reserveRatioManagementLimit
            ) = abi.decode(_params[1:], (address, address, uint256, uint256));

            _updatePortStrategy(portStrategy, underlyingToken, dailyManagementLimit, reserveRatioManagementLimit);

            /// _setCoreBranchRouter
        } else if (_params[0] == 0x08) {
            (address coreBranchRouter, address coreBranchBridgeAgent) = abi.decode(_params[1:], (address, address));

            IPort(localPortAddress).setCoreBranchRouter(coreBranchRouter, coreBranchBridgeAgent);

            /// _sweep
        } else if (_params[0] == 0x09) {
            (address recipient) = abi.decode(_params[1:], (address));

            IPort(localPortAddress).sweep(recipient);

            /// Unrecognized Function Selector
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /*///////////////////////////////////////////////////////////////
                 TOKEN MANAGEMENT INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to deploy/add a token already active in the global environment in the Root Chain.
     *         Must be called from another chain.
     *  @param _globalAddress the address of the global virtualized token.
     *  @param _name token name.
     *  @param _symbol token symbol.
     *  @param _refundee the address of the excess gas receiver.
     *  @param _gParams Gas parameters for remote execution.
     *  @dev FUNC ID: 1
     *  @dev all hTokens have 18 decimals.
     */
    function _receiveAddGlobalToken(
        address _globalAddress,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _refundee,
        GasParams memory _gParams
    ) internal {
        //Create Token
        ERC20hToken newToken = ITokenFactory(hTokenFactoryAddress).createToken(_name, _symbol, _decimals, false);

        // Encode Data
        bytes memory params = abi.encode(_globalAddress, newToken);

        // Pack FuncId
        bytes memory payload = abi.encodePacked(bytes1(0x03), params);

        //Send Cross-Chain request
        IBridgeAgent(localBridgeAgentAddress).callOut{value: msg.value}(payable(_refundee), payload, _gParams);
    }

    /**
     * @notice Function to deploy/add a token already active in the global environment in the Root Chain.
     *         Must be called from another chain.
     *  @param _newBranchRouter the address of the new branch router.
     *  @param _branchBridgeAgentFactory the address of the branch bridge agent factory.
     *  @param _rootBridgeAgent the address of the root bridge agent.
     *  @param _rootBridgeAgentFactory the address of the root bridge agent factory.
     *  @param _refundee the address of the excess gas receiver.
     *  @param _gParams Gas parameters for remote execution.
     *  @dev FUNC ID: 2
     *  @dev all hTokens have 18 decimals.
     */
    function _receiveAddBridgeAgent(
        address _newBranchRouter,
        address _branchBridgeAgentFactory,
        address _rootBridgeAgent,
        address _rootBridgeAgentFactory,
        address _refundee,
        GasParams memory _gParams
    ) internal virtual {
        // Save Port Address to memory
        address _localPortAddress = localPortAddress;

        // Check if msg.sender is a valid BridgeAgentFactory
        if (!IPort(_localPortAddress).isBridgeAgentFactory(_branchBridgeAgentFactory)) {
            revert UnrecognizedBridgeAgentFactory();
        }

        // Create BridgeAgent
        address newBridgeAgent = IBridgeAgentFactory(_branchBridgeAgentFactory).createBridgeAgent(
            _newBranchRouter, _rootBridgeAgent, _rootBridgeAgentFactory
        );

        // Check BridgeAgent Address
        if (!IPort(_localPortAddress).isBridgeAgent(newBridgeAgent)) {
            revert UnrecognizedBridgeAgent();
        }

        // Encode Data
        bytes memory params = abi.encode(newBridgeAgent, _rootBridgeAgent);

        // Pack FuncId
        bytes memory payload = abi.encodePacked(bytes1(0x04), params);

        //Send Cross-Chain request
        IBridgeAgent(localBridgeAgentAddress).callOut{value: msg.value}(payable(_refundee), payload, _gParams);
    }

    /*///////////////////////////////////////////////////////////////
                 BRIDGE AGENT MANAGEMENT INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to add/deactivate a Branch Bridge Agent Factory.
     *  @param _newBridgeAgentFactoryAddress the address of the new local bridge agent factory.
     *  @dev FUNC ID: 3
     */
    function _toggleBranchBridgeAgentFactory(address _newBridgeAgentFactoryAddress) internal {
        IPort(localPortAddress).toggleBridgeAgentFactory(_newBridgeAgentFactoryAddress);
    }

    /*///////////////////////////////////////////////////////////////
                 PORT STRATEGIES INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to add/remove a token to be used by Port Strategies.
     *  @param _underlyingToken the address of the underlying token.
     *  @param _minimumReservesRatio the minimum reserves ratio the Port must have.
     *  @dev FUNC ID: 4
     */
    function _toggleStrategyToken(address _underlyingToken, uint256 _minimumReservesRatio) internal {
        IPort(localPortAddress).toggleStrategyToken(_underlyingToken, _minimumReservesRatio);
    }

    /**
     * @notice Function to update the minimum reserves ratio of a token to be used by Port Strategies.
     *  @param _underlyingToken the address of the underlying token.
     *  @param _minimumReservesRatio the minimum reserves ratio the Port must have.
     *  @dev FUNC ID: 5
     */
    function _updateStrategyToken(address _underlyingToken, uint256 _minimumReservesRatio) internal {
        IPort(localPortAddress).updateStrategyToken(_underlyingToken, _minimumReservesRatio);
    }

    /**
     * @notice Function to add or remove a strategy that manages balances of a strategy token from this branch's port.
     *         Must be called from another chain.
     *  @param _portStrategy the address of the port strategy.
     *  @param _underlyingToken the address of the underlying token.
     *  @param _dailyManagementLimit the daily management limit.
     *  @param _reserveRatioManagementLimit the reserve ratio management limit.
     *  @dev FUNC ID: 6
     */
    function _togglePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) internal {
        IPort(localPortAddress).togglePortStrategy(
            _portStrategy, _underlyingToken, _dailyManagementLimit, _reserveRatioManagementLimit
        );
    }

    /**
     * @notice Function to update a strategy that manages balances of a strategy token from this branch's port.
     *         Must be called from another chain.
     *  @param _portStrategy the address of the port strategy.
     *  @param _underlyingToken the address of the underlying token.
     *  @param _dailyManagementLimit the daily management limit.
     *  @param _reserveRatioManagementLimit the reserve ratio management limit.
     *  @dev FUNC ID: 7
     */
    function _updatePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) internal {
        IPort(localPortAddress).updatePortStrategy(
            _portStrategy, _underlyingToken, _dailyManagementLimit, _reserveRatioManagementLimit
        );
    }
}
