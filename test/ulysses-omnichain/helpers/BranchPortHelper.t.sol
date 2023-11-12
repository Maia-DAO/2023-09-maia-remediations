//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library BranchPortHelper {
    using BranchPortHelper for BranchPort;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(BranchPort, address _owner) internal returns (BranchPort _branchPort) {
        _branchPort = new BranchPort(_owner);

        _branchPort.check_deploy(_owner);
    }

    function check_deploy(BranchPort _branchPort, address _owner) internal view {
        _branchPort.check_owner(_owner);
    }

    function check_owner(BranchPort _branchPort, address _owner) internal view {
        require(_branchPort.owner() == _owner, "Incorrect BranchPort Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        BranchPort _branchPort,
        CoreBranchRouter _coreBranchRouter,
        BranchBridgeAgentFactory _branchBridgeAgentFactory
    ) internal {
        _branchPort.initialize(address(_coreBranchRouter), address(_branchBridgeAgentFactory));

        _branchPort.check_init(_coreBranchRouter, _branchBridgeAgentFactory);
    }

    function check_init(
        BranchPort _branchPort,
        CoreBranchRouter _coreBranchRouter,
        BranchBridgeAgentFactory _branchBridgeAgentFactory
    ) internal view {
        _branchPort.check_coreBranchRouter(_coreBranchRouter);
        _branchPort.check_isBranchBridgeAgentFactory(_branchBridgeAgentFactory);
    }

    function check_coreBranchRouter(BranchPort _branchPort, CoreBranchRouter _coreBranchRouter) internal view {
        require(
            _branchPort.coreBranchRouterAddress() == address(_coreBranchRouter), "Incorrect BranchPort CoreBranchRouter"
        );
    }

    function check_isBranchBridgeAgentFactory(
        BranchPort _branchPort,
        BranchBridgeAgentFactory _branchBridgeAgentFactory
    ) internal view {
        require(
            _branchPort.isBridgeAgentFactory(address(_branchBridgeAgentFactory)),
            "Incorrect BranchPort is BranchBridgeAgentFactory"
        );
    }
}
