//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {BaseBranchRouterHelper} from "./BaseBranchRouterHelper.t.sol";

library ArbitrumBaseBranchRouterHelper {
    using BaseBranchRouterHelper for ArbitrumBaseBranchRouter;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(ArbitrumBaseBranchRouter) internal returns (ArbitrumBaseBranchRouter _arbitrumBaseBranchRouter) {
        _arbitrumBaseBranchRouter = new ArbitrumBaseBranchRouter();

        _arbitrumBaseBranchRouter.check_deploy(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        ArbitrumBaseBranchRouter _arbitrumBaseBranchRouter,
        BranchBridgeAgent _coreBranchBridgeAgent,
        BranchPort _branchPort
    ) internal {
        _arbitrumBaseBranchRouter._init(_coreBranchBridgeAgent, _branchPort);
    }
}
