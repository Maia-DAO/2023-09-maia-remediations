//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {ArbitrumBranchBridgeAgentFactoryHelper} from "./ArbitrumBranchBridgeAgentFactoryHelper.t.sol";
import {ArbitrumBranchPortHelper} from "./ArbitrumBranchPortHelper.t.sol";
import {ArbitrumCoreBranchRouterHelper} from "./ArbitrumCoreBranchRouterHelper.t.sol";
import {BaseBranchRouterHelper} from "./BaseBranchRouterHelper.t.sol";
import {BranchBridgeAgentFactoryHelper} from "./BranchBridgeAgentFactoryHelper.t.sol";
import {BranchPortHelper} from "./BranchPortHelper.t.sol";
import {CoreBranchRouterHelper} from "./CoreBranchRouterHelper.t.sol";
import {CoreRootRouterHelper} from "./CoreRootRouterHelper.t.sol";
import {ERC20hTokenBranchFactoryHelper} from "./ERC20hTokenBranchFactoryHelper.t.sol";
import {ERC20hTokenRootFactoryHelper} from "./ERC20hTokenRootFactoryHelper.t.sol";
import {MulticallRootRouterHelper} from "./MulticallRootRouterHelper.t.sol";
import {RootBridgeAgentHelper} from "./RootBridgeAgentHelper.t.sol";
import {RootBridgeAgentFactoryHelper} from "./RootBridgeAgentFactoryHelper.t.sol";
import {RootPortHelper} from "./RootPortHelper.t.sol";

library RootForkHelper {
    using ArbitrumBranchBridgeAgentFactoryHelper for ArbitrumBranchBridgeAgentFactory;
    using ArbitrumBranchPortHelper for ArbitrumBranchPort;
    using ArbitrumCoreBranchRouterHelper for ArbitrumCoreBranchRouter;
    using BaseBranchRouterHelper for BaseBranchRouter;
    using BranchBridgeAgentFactoryHelper for BranchBridgeAgentFactory;
    using BranchPortHelper for BranchPort;
    using CoreBranchRouterHelper for CoreBranchRouter;
    using CoreRootRouterHelper for CoreRootRouter;
    using ERC20hTokenBranchFactoryHelper for ERC20hTokenBranchFactory;
    using ERC20hTokenRootFactoryHelper for ERC20hTokenRootFactory;
    using MulticallRootRouterHelper for MulticallRootRouter;
    using RootBridgeAgentFactoryHelper for RootBridgeAgentFactory;
    using RootPortHelper for RootPort;

    function _deployRoot(uint16 _rootChainId, address _lzEndpointAddress, address _multicallAddress)
        internal
        returns (
            RootPort _rootPort,
            RootBridgeAgentFactory _rootBridgeAgentFactory,
            ERC20hTokenRootFactory _hTokenRootFactory,
            CoreRootRouter _coreRootRouter,
            MulticallRootRouter _rootMulticallRouter
        )
    {
        _rootPort = _rootPort._deploy(_rootChainId);

        _rootBridgeAgentFactory = _rootBridgeAgentFactory._deploy(_rootChainId, _lzEndpointAddress, _rootPort);

        _hTokenRootFactory = _hTokenRootFactory._deploy(_rootPort);

        _coreRootRouter = _coreRootRouter._deploy(_rootChainId, _rootPort);

        _rootMulticallRouter = _rootMulticallRouter._deploy(_rootChainId, _rootPort, _multicallAddress);
    }

    function _initRoot(
        RootPort _rootPort,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        ERC20hTokenRootFactory _hTokenRootFactory,
        CoreRootRouter _coreRootRouter,
        MulticallRootRouter _rootMulticallRouter
    ) internal returns (RootBridgeAgent _coreRootBridgeAgent, RootBridgeAgent _multicallRootBridgeAgent) {
        _rootPort._init(_rootBridgeAgentFactory, _coreRootRouter);

        _hTokenRootFactory._init(_coreRootRouter);

        _coreRootBridgeAgent = _rootBridgeAgentFactory._createRootBridgeAgent(address(_coreRootRouter));

        _multicallRootBridgeAgent = _rootBridgeAgentFactory._createRootBridgeAgent(address(_rootMulticallRouter));

        _coreRootRouter._init(_coreRootBridgeAgent, _hTokenRootFactory);

        _rootMulticallRouter._init(_multicallRootBridgeAgent);
    }

    function _deployLocalBranch(
        uint16 _rootChainId,
        RootPort _rootPort,
        address _owner,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        RootBridgeAgent _coreRootBridgeAgent
    )
        internal
        returns (
            ArbitrumBranchPort _arbitrumPort,
            BaseBranchRouter _arbitrumMulticallRouter,
            ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
            ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
            ArbitrumBranchBridgeAgent _arbitrumCoreBranchBridgeAgent
        )
    {
        _arbitrumPort = _arbitrumPort._deploy(_rootChainId, _rootPort, _owner);

        _arbitrumMulticallRouter = _arbitrumMulticallRouter._deploy();

        _arbitrumCoreBranchRouter = _arbitrumCoreBranchRouter._deploy();

        _arbitrumBranchBridgeAgentFactory = _arbitrumBranchBridgeAgentFactory._deploy(
            _rootChainId, _rootBridgeAgentFactory, _arbitrumCoreBranchRouter, _arbitrumPort, _owner
        );

        _arbitrumPort._init(_arbitrumCoreBranchRouter, _arbitrumBranchBridgeAgentFactory);

        _arbitrumBranchBridgeAgentFactory._init(_coreRootBridgeAgent);
        _arbitrumCoreBranchBridgeAgent = ArbitrumBranchBridgeAgent(payable(_arbitrumPort.bridgeAgents(0)));

        _arbitrumCoreBranchRouter._init(_arbitrumCoreBranchBridgeAgent, _arbitrumPort);
    }

    function _deployBranch(
        string memory _name,
        string memory _symbol,
        uint16 _rootChainId,
        uint16 _branchChainId,
        address _owner,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        address _lzEndpointAddressBranch
    )
        internal
        returns (
            BranchPort _branchPort,
            ERC20hTokenBranchFactory _branchHTokenFactory,
            CoreBranchRouter _coreBranchRouter,
            address _branchWrappedNativeToken,
            BranchBridgeAgentFactory _branchBridgeAgentFactory,
            BaseBranchRouter _branchMulticallRouter
        )
    {
        _branchPort = _branchPort._deploy(_owner);

        _branchHTokenFactory = _branchHTokenFactory._deploy(_branchPort, _name, _symbol);

        _coreBranchRouter = _coreBranchRouter._deploy(_branchHTokenFactory);

        _branchWrappedNativeToken = address(new WETH());

        _branchBridgeAgentFactory = _branchBridgeAgentFactory._deploy(
            _branchChainId,
            _rootChainId,
            _rootBridgeAgentFactory,
            _lzEndpointAddressBranch,
            _coreBranchRouter,
            _branchPort,
            _owner
        );

        _branchMulticallRouter = _branchMulticallRouter._deploy();
    }

    function _initBranch(
        RootBridgeAgent _coreRootBridgeAgent,
        address _branchWrappedNativeToken,
        BranchPort _branchPort,
        ERC20hTokenBranchFactory _branchHTokenFactory,
        CoreBranchRouter _coreBranchRouter,
        BranchBridgeAgentFactory _branchBridgeAgentFactory
    ) internal returns (BranchBridgeAgent _branchCoreBridgeAgent, address _branchLocalWrappedNativeToken) {
        _branchHTokenFactory._init(_branchWrappedNativeToken, _coreBranchRouter);

        _branchPort._init(_coreBranchRouter, _branchBridgeAgentFactory);

        _branchBridgeAgentFactory._init(_coreRootBridgeAgent);

        _branchCoreBridgeAgent = BranchBridgeAgent(payable(_branchPort.bridgeAgents(0)));

        _coreBranchRouter._init(_branchCoreBridgeAgent, _branchPort);

        _branchLocalWrappedNativeToken = address(_branchHTokenFactory.hTokens(0));
    }

    function _addNewBranchChainToRoot(
        RootPort _rootPort,
        BranchBridgeAgent _coreBranchBridgeAgent,
        uint16 _branchChainId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _branchLocalWrappedNativeToken,
        address _branchWrappedNativeToken,
        ERC20hTokenRootFactory _hTokenRootFactory
    ) internal returns (address branchGlobalToken) {
        RootPort rootPort = _rootPort;
        branchGlobalToken = rootPort._addNewChain(
            _coreBranchBridgeAgent,
            _branchChainId,
            _name,
            _symbol,
            _decimals,
            _branchLocalWrappedNativeToken,
            _branchWrappedNativeToken,
            _hTokenRootFactory
        );
    }
}
