//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {BaseBranchRouterHelper} from "./BaseBranchRouterHelper.t.sol";

library ArbitrumCoreBranchRouterHelper {
    using ArbitrumCoreBranchRouterHelper for ArbitrumCoreBranchRouter;
    using BaseBranchRouterHelper for BaseBranchRouter;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/
    function _deploy(ArbitrumCoreBranchRouter) internal returns (ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter) {
        _arbitrumCoreBranchRouter = new ArbitrumCoreBranchRouter();

        _arbitrumCoreBranchRouter.check_deploy(address(this));
    }

    function check_deploy(ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter, address _owner) internal view {
        BaseBranchRouter(_arbitrumCoreBranchRouter).check_deploy(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        BaseBranchRouter _baseBranchRouter,
        ArbitrumBranchBridgeAgent _arbitrumCoreBranchBridgeAgent,
        ArbitrumBranchPort _arbitrumPort
    ) internal {
        BaseBranchRouter(_baseBranchRouter)._init(_arbitrumCoreBranchBridgeAgent, _arbitrumPort);
    }
}
