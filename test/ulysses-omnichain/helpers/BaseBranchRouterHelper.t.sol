//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library BaseBranchRouterHelper {
    using BaseBranchRouterHelper for BaseBranchRouter;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(BaseBranchRouter) internal returns (BaseBranchRouter _baseBranchRouter) {
        _baseBranchRouter = new BaseBranchRouter();

        _baseBranchRouter.check_deploy(address(this));
    }

    function check_deploy(BaseBranchRouter _baseBranchRouter, address _owner) internal view {
        _baseBranchRouter.check_owner(_owner);
    }

    function check_owner(BaseBranchRouter _baseBranchRouter, address _owner) internal view {
        require(_baseBranchRouter.owner() == _owner, "Incorrect BaseBranchRouter Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(BaseBranchRouter _baseBranchRouter, BranchBridgeAgent _branchBridgeAgent, BranchPort _branchPort)
        internal
    {
        _baseBranchRouter.initialize(address(_branchBridgeAgent));

        _baseBranchRouter.check_init(_branchBridgeAgent, _branchPort);
    }

    function check_init(
        BaseBranchRouter _baseBranchRouter,
        BranchBridgeAgent _branchBridgeAgent,
        BranchPort _branchPort
    ) internal view {
        _baseBranchRouter.check_owner(address(0));
        _baseBranchRouter.check_branchBridgeAgent(_branchBridgeAgent);
        _baseBranchRouter.check_branchBridgeAgentExecutor(
            BranchBridgeAgentExecutor(_branchBridgeAgent.bridgeAgentExecutorAddress())
        );
        _baseBranchRouter.check_branchPort(_branchPort);
    }

    function check_branchBridgeAgent(BaseBranchRouter _baseBranchRouter, BranchBridgeAgent _branchBridgeAgent)
        internal
        view
    {
        require(
            _baseBranchRouter.localBridgeAgentAddress() == address(_branchBridgeAgent),
            "Incorrect BaseBranchRouter bridgeAgentAddress"
        );
    }

    function check_branchBridgeAgentExecutor(
        BaseBranchRouter _baseBranchRouter,
        BranchBridgeAgentExecutor _branchBridgeAgentExecutor
    ) internal view {
        require(
            _baseBranchRouter.bridgeAgentExecutorAddress() == address(_branchBridgeAgentExecutor),
            "Incorrect BaseBranchRouter bridgeAgentExecutorAddress"
        );
    }

    function check_branchPort(BaseBranchRouter _baseBranchRouter, BranchPort _branchPort) internal view {
        require(_baseBranchRouter.localPortAddress() == address(_branchPort), "Incorrect BaseBranchRouter BranchPort");
    }
}
