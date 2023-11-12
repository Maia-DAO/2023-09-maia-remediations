//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library RootPortHelper {
    using RootPortHelper for RootPort;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(RootPort, uint16 _rootChainId) internal returns (RootPort _rootPort) {
        _rootPort = new RootPort(_rootChainId);

        _rootPort.check_deploy(_rootChainId);
    }

    function check_deploy(RootPort _rootPort, uint256 _rootChainId) internal view {
        _rootPort.check_rootChainId(_rootChainId);
        _rootPort.check_isChainId(_rootChainId);
        _rootPort.check_owner(address(this));
    }

    function check_rootChainId(RootPort _rootPort, uint256 _rootChainId) internal view {
        require(_rootPort.localChainId() == _rootChainId, "Incorrect RootPort Root Local Chain Id");
    }

    function check_isChainId(RootPort _rootPort, uint256 _rootChainId) internal view {
        require(_rootPort.isChainId(_rootChainId), "Incorrect RootPort is Chain Id");
    }

    function check_owner(RootPort _rootPort, address _owner) internal view {
        require(_rootPort.owner() == _owner, "Incorrect RootPort Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(RootPort _rootPort, RootBridgeAgentFactory _rootBridgeAgentFactory, CoreRootRouter _coreRootRouter)
        internal
    {
        _rootPort.initialize(address(_rootBridgeAgentFactory), address(_coreRootRouter));

        _rootPort.check_init(_rootBridgeAgentFactory, _coreRootRouter);
    }

    function check_init(
        RootPort _rootPort,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        CoreRootRouter _coreRootRouter
    ) internal view {
        _rootPort.check_rootBridgeAgentFactory(0, _rootBridgeAgentFactory);
        _rootPort.check_isBridgeAgentFactory(_rootBridgeAgentFactory);
        _rootPort.check_coreRootRouter(_coreRootRouter);
    }

    function check_rootBridgeAgentFactory(
        RootPort _rootPort,
        uint256 index,
        RootBridgeAgentFactory _rootBridgeAgentFactory
    ) internal view {
        require(
            _rootPort.bridgeAgentFactories(index) == address(_rootBridgeAgentFactory),
            "Incorrect RootPort RootBridgeAgentFactory"
        );
    }

    function check_isBridgeAgentFactory(RootPort _rootPort, RootBridgeAgentFactory _rootBridgeAgentFactory)
        internal
        view
    {
        require(
            _rootPort.isBridgeAgentFactory(address(_rootBridgeAgentFactory)),
            "Incorrect RootPort RootBridgeAgentFactory"
        );
    }

    function check_coreRootRouter(RootPort _rootPort, CoreRootRouter _coreRootRouter) internal view {
        require(_rootPort.coreRootRouterAddress() == address(_coreRootRouter), "Incorrect RootPort CoreRootRouter");
    }

    /*//////////////////////////////////////////////////////////////
                           INIT CORE HELPERS
    //////////////////////////////////////////////////////////////*/

    function _initCore(
        RootPort _rootPort,
        RootBridgeAgent _coreRootBridgeAgent,
        ArbitrumBranchBridgeAgent _coreLocalBranchBridgeAgent,
        ArbitrumBranchPort _localBranchPortAddress
    ) internal {
        _rootPort.initializeCore(
            address(_coreRootBridgeAgent), address(_coreLocalBranchBridgeAgent), address(_localBranchPortAddress)
        );

        _rootPort.check_initCore(_coreRootBridgeAgent, _localBranchPortAddress);
    }

    function check_initCore(
        RootPort _rootPort,
        RootBridgeAgent _coreRootBridgeAgent,
        ArbitrumBranchPort _localBranchPortAddress
    ) internal view {
        _rootPort.check_coreRootBridgeAgent(_coreRootBridgeAgent);
        _rootPort.check_localBranchPortAddress(_localBranchPortAddress);
        _rootPort.check_addBridgeAgent(_coreRootBridgeAgent, _rootPort.owner());
    }

    function check_coreRootBridgeAgent(RootPort _rootPort, RootBridgeAgent _coreRootBridgeAgent) internal view {
        require(
            _rootPort.coreRootBridgeAgentAddress() == address(_coreRootBridgeAgent),
            "Incorrect RootPort CoreRootBridgeAgent"
        );
    }

    function check_localBranchPortAddress(RootPort _rootPort, ArbitrumBranchPort _localBranchPortAddress)
        internal
        view
    {
        require(
            _rootPort.localBranchPortAddress() == address(_localBranchPortAddress),
            "Incorrect RootPort LocalBranchPortAddress"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        ADD BRIDGE AGENT HELPERS
    //////////////////////////////////////////////////////////////*/

    function check_addBridgeAgent(RootPort _rootPort, RootBridgeAgent _bridgeAgent, address _manager) internal view {
        _rootPort.check_isBridgeAgent(_bridgeAgent);
        _rootPort.check_bridgeAgentManager(_bridgeAgent, _manager);
    }

    function check_isBridgeAgent(RootPort _rootPort, RootBridgeAgent _bridgeAgent) internal view {
        require(_rootPort.isBridgeAgent(address(_bridgeAgent)), "Incorrect RootPort BridgeAgent");
    }

    function check_bridgeAgentManager(RootPort _rootPort, RootBridgeAgent _bridgeAgent, address _manager)
        internal
        view
    {
        require(_rootPort.getBridgeAgentManager(address(_bridgeAgent)) == _manager, "Incorrect RootPort BridgeAgent");
    }

    function check_bridgeAgents(RootPort _rootPort, uint256 index, RootBridgeAgent _bridgeAgent) internal view {
        require(_rootPort.bridgeAgents(index) == address(_bridgeAgent), "Incorrect RootPort BridgeAgent");
    }

    /*//////////////////////////////////////////////////////////////
                          ADD NEW CHAIN HELPERS
    //////////////////////////////////////////////////////////////*/

    function _addNewChain(
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
        uint256 hTokenIndex = _hTokenRootFactory.getHTokens().length;

        _rootPort.addNewChain(
            address(_coreBranchBridgeAgent),
            _branchChainId,
            _name,
            _symbol,
            _decimals,
            _branchLocalWrappedNativeToken,
            _branchWrappedNativeToken
        );

        branchGlobalToken = address(_hTokenRootFactory.hTokens(hTokenIndex));

        RootPort rootPort = _rootPort;
        rootPort.check_addNewChain(
            _coreBranchBridgeAgent,
            _branchChainId,
            _name,
            _symbol,
            _decimals,
            _branchLocalWrappedNativeToken,
            _branchWrappedNativeToken,
            branchGlobalToken
        );
    }

    function check_addNewChain(
        RootPort _rootPort,
        BranchBridgeAgent _coreBranchBridgeAgent,
        uint16 _branchChainId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _branchLocalWrappedNativeToken,
        address _branchWrappedNativeToken,
        address branchGlobalToken
    ) internal view {
        _rootPort.check_isGlobalAddress(branchGlobalToken);
        _rootPort.check_globalTokenFromLocal(_branchChainId, _branchLocalWrappedNativeToken, branchGlobalToken);
        _rootPort.check_localTokenFromGlobal(_branchChainId, branchGlobalToken, _branchLocalWrappedNativeToken);
        _rootPort.check_underlyingTokenFromLocal(
            _branchChainId, _branchLocalWrappedNativeToken, _branchWrappedNativeToken
        );
    }

    function check_isGlobalAddress(RootPort _rootPort, address _globalToken) internal view {
        require(_rootPort.isGlobalAddress(_globalToken), "Incorrect RootPort Global Token");
    }

    function check_globalTokenFromLocal(
        RootPort _rootPort,
        uint16 _branchChainId,
        address _branchLocalToken,
        address _globalToken
    ) internal view {
        require(
            _rootPort.getGlobalTokenFromLocal(_branchLocalToken, _branchChainId) == _globalToken,
            "Incorrect RootPort Global From Local Token"
        );
    }

    function check_localTokenFromGlobal(
        RootPort _rootPort,
        uint16 _branchChainId,
        address _globalToken,
        address _branchLocalToken
    ) internal view {
        require(
            _rootPort.getLocalTokenFromGlobal(_globalToken, _branchChainId) == _branchLocalToken,
            "Incorrect RootPort Local From Global Token"
        );
    }

    function check_underlyingTokenFromLocal(
        RootPort _rootPort,
        uint16 _branchChainId,
        address _branchLocalToken,
        address _branchUnderlyingToken
    ) internal view {
        require(
            _rootPort.getUnderlyingTokenFromLocal(_branchLocalToken, _branchChainId) == _branchUnderlyingToken,
            "Incorrect RootPort Underlying From Local Token"
        );
    }
}
