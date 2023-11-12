// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IArbitrumBranchPort as IPort} from "../interfaces/IArbitrumBranchPort.sol";

import {ArbitrumBranchBridgeAgent, DeployArbitrumBranchBridgeAgent} from "../ArbitrumBranchBridgeAgent.sol";
import {BranchBridgeAgentFactory} from "./BranchBridgeAgentFactory.sol";

/**
 * @title  Arbitrum Branch Bridge Agent Factory Contract
 * @author MaiaDAO
 * @notice Factory contract for allowing permissionless deployment of
 *         new Arbitrum Branch Bridge Agents which are in charge of
 *         managing the deposit and withdrawal of assets between the
 *         branch chains and the omnichain environment.
 */
contract ArbitrumBranchBridgeAgentFactory is BranchBridgeAgentFactory {
    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Bridge Agent Factory Contract.
     *  @param _rootChainId Root Chain Layer Zero Id.
     *  @param _rootBridgeAgentFactoryAddress Root Bridge Agent Factory Address.
     *  @param _localCoreBranchRouterAddress Local Core Branch Router Address.
     *  @param _localPortAddress Local Branch Port Address.
     *  @param _owner Owner of the contract.
     */
    constructor(
        uint16 _rootChainId,
        address _rootBridgeAgentFactoryAddress,
        address _localCoreBranchRouterAddress,
        address _localPortAddress,
        address _owner
    )
        BranchBridgeAgentFactory(
            _rootChainId,
            _rootChainId,
            _rootBridgeAgentFactoryAddress,
            address(0),
            _localCoreBranchRouterAddress,
            _localPortAddress,
            _owner
        )
    {}

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT FACTORY INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to deploy a new arbitrum branch bridge agent.
     * @param _rootBridgeAgentAddress Address of the root bridge agent to connect to.
     * @param _newBranchRouterAddress Address of the new branch router.
     * @return newBridgeAgent Address of the newly deployed bridge agent.
     */
    function _deployBridgeAgent(address _rootBridgeAgentAddress, address _newBranchRouterAddress)
        internal
        override
        returns (address newBridgeAgent)
    {
        // Deploy new bridge agent
        newBridgeAgent = address(
            DeployArbitrumBranchBridgeAgent.deploy(
                rootChainId, _rootBridgeAgentAddress, _newBranchRouterAddress, localPortAddress
            )
        );

        // Add the new bridge agent to the local Branch Port's state
        IPort(localPortAddress).addBridgeAgent(newBridgeAgent);

        // Emit event
        emit BridgeAgentAdded(newBridgeAgent);
    }
}
