//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library BranchBridgeAgentFactoryHelper {
    using BranchBridgeAgentFactoryHelper for BranchBridgeAgentFactory;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(
        BranchBridgeAgentFactory,
        uint16 _branchChainId,
        uint16 _rootChainId,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        address _lzEndpointAddress,
        CoreBranchRouter _coreBranchRouter,
        BranchPort _branchPort,
        address _owner
    ) internal returns (BranchBridgeAgentFactory _branchBridgeAgentFactory) {
        _branchBridgeAgentFactory = new BranchBridgeAgentFactory(
             _branchChainId,
            _rootChainId,
            address(_rootBridgeAgentFactory),
            _lzEndpointAddress,
            address(_coreBranchRouter),
            address(_branchPort),
            _owner
        );

        _branchBridgeAgentFactory.check_deploy(
            _branchChainId,
            _rootChainId,
            _rootBridgeAgentFactory,
            _lzEndpointAddress,
            _coreBranchRouter,
            _branchPort,
            _owner
        );
    }

    function check_deploy(
        BranchBridgeAgentFactory _branchBridgeAgentFactory,
        uint16 _branchChainId,
        uint16 _rootChainId,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        address _lzEndpointAddress,
        CoreBranchRouter _coreBranchRouter,
        BranchPort _branchPort,
        address _owner
    ) internal view {
        _branchBridgeAgentFactory.check_branchChainId(_branchChainId);
        _branchBridgeAgentFactory.check_rootChainId(_rootChainId);
        _branchBridgeAgentFactory.check_rootBridgeAgentFactory(_rootBridgeAgentFactory);
        _branchBridgeAgentFactory.check_lzEndpointAddress(_lzEndpointAddress);
        _branchBridgeAgentFactory.check_coreBranchRouter(_coreBranchRouter);
        _branchBridgeAgentFactory.check_branchPort(_branchPort);
        _branchBridgeAgentFactory.check_owner(_owner);
    }

    function check_branchChainId(BranchBridgeAgentFactory _branchBridgeAgentFactory, uint256 _branchChainId)
        internal
        view
    {
        require(
            _branchBridgeAgentFactory.localChainId() == _branchChainId,
            "Incorrect BranchBridgeAgentFactory Branch Local Chain Id"
        );
    }

    function check_rootChainId(BranchBridgeAgentFactory _branchBridgeAgentFactory, uint256 _rootChainId)
        internal
        view
    {
        require(
            _branchBridgeAgentFactory.rootChainId() == _rootChainId,
            "Incorrect BranchBridgeAgentFactory Root Local Chain Id"
        );
    }

    function check_rootBridgeAgentFactory(
        BranchBridgeAgentFactory _branchBridgeAgentFactory,
        RootBridgeAgentFactory _rootBridgeAgentFactory
    ) internal view {
        require(
            _branchBridgeAgentFactory.rootBridgeAgentFactoryAddress() == address(_rootBridgeAgentFactory),
            "Incorrect BranchBridgeAgentFactory RootBridgeAgentFactory"
        );
    }

    function check_lzEndpointAddress(BranchBridgeAgentFactory _branchBridgeAgentFactory, address _lzEndpointAddress)
        internal
        view
    {
        require(
            _branchBridgeAgentFactory.lzEndpointAddress() == _lzEndpointAddress,
            "Incorrect BranchBridgeAgentFactory lzEndpointAddress"
        );
    }

    function check_coreBranchRouter(
        BranchBridgeAgentFactory _branchBridgeAgentFactory,
        CoreBranchRouter _coreBranchRouter
    ) internal view {
        require(
            _branchBridgeAgentFactory.localCoreBranchRouterAddress() == address(_coreBranchRouter),
            "Incorrect BranchBridgeAgentFactory CoreBranchRouter"
        );
    }

    function check_branchPort(BranchBridgeAgentFactory _branchBridgeAgentFactory, BranchPort _branchPort)
        internal
        view
    {
        require(
            _branchBridgeAgentFactory.localPortAddress() == address(_branchPort),
            "Incorrect BranchBridgeAgentFactory BranchPort"
        );
    }

    function check_owner(BranchBridgeAgentFactory _branchBridgeAgentFactory, address _owner) internal view {
        require(_branchBridgeAgentFactory.owner() == _owner, "Incorrect BranchBridgeAgentFactory Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(BranchBridgeAgentFactory _branchBridgeAgentFactory, RootBridgeAgent _coreRootBridgeAgent) internal {
        _branchBridgeAgentFactory.initialize(address(_coreRootBridgeAgent));

        _branchBridgeAgentFactory.check_init();
    }

    function check_init(BranchBridgeAgentFactory _branchBridgeAgentFactory) internal view {
        _branchBridgeAgentFactory.check_owner(address(0));
    }
}
