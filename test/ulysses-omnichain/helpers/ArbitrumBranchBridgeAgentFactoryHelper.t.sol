//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import "./BranchBridgeAgentFactoryHelper.t.sol";

library ArbitrumBranchBridgeAgentFactoryHelper {
    using ArbitrumBranchBridgeAgentFactoryHelper for ArbitrumBranchBridgeAgentFactory;
    using BranchBridgeAgentFactoryHelper for BranchBridgeAgentFactory;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(
        ArbitrumBranchBridgeAgentFactory,
        uint16 _rootChainId,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
        ArbitrumBranchPort _arbitrumPort,
        address _owner
    ) internal returns (ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory) {
        _arbitrumBranchBridgeAgentFactory = new ArbitrumBranchBridgeAgentFactory(
            _rootChainId,
            address(_rootBridgeAgentFactory),
            address(_arbitrumCoreBranchRouter),
            address(_arbitrumPort),
            _owner
        );

        BranchBridgeAgentFactory(_arbitrumBranchBridgeAgentFactory).check_deploy(
            _rootChainId,
            _rootChainId,
            _rootBridgeAgentFactory,
            address(0),
            CoreBranchRouter(_arbitrumCoreBranchRouter),
            BranchPort(_arbitrumPort),
            _owner
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
        RootBridgeAgent _coreRootBridgeAgent
    ) internal {
        BranchBridgeAgentFactory(_arbitrumBranchBridgeAgentFactory)._init(_coreRootBridgeAgent);
    }
}
