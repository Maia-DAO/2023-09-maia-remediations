//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {BaseBranchRouterHelper} from "./BaseBranchRouterHelper.t.sol";

library CoreBranchRouterHelper {
    using CoreBranchRouterHelper for CoreBranchRouter;
    using BaseBranchRouterHelper for BaseBranchRouter;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/
    function _deploy(CoreBranchRouter, ERC20hTokenBranchFactory _branchHTokenFactory)
        internal
        returns (CoreBranchRouter _coreBranchRouter)
    {
        _coreBranchRouter = new CoreBranchRouter(address(_branchHTokenFactory));

        _coreBranchRouter.check_deploy(_branchHTokenFactory, address(this));
    }

    function check_deploy(
        CoreBranchRouter _coreBranchRouter,
        ERC20hTokenBranchFactory _branchHTokenFactory,
        address _owner
    ) internal view {
        BaseBranchRouter(_coreBranchRouter).check_deploy(_owner);

        _coreBranchRouter.check_branchHTokenFactory(_branchHTokenFactory);
    }

    function check_branchHTokenFactory(
        CoreBranchRouter _coreBranchRouter,
        ERC20hTokenBranchFactory _branchHTokenFactory
    ) internal view {
        require(
            _coreBranchRouter.hTokenFactoryAddress() == address(_branchHTokenFactory),
            "Incorrect CoreBranchRouter ERC20hTokenBranchFactory"
        );
    }
    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        CoreBranchRouter _coreBranchRouter,
        BranchBridgeAgent _coreBranchBridgeAgent,
        BranchPort _branchPort
    ) internal {
        BaseBranchRouter(_coreBranchRouter)._init(_coreBranchBridgeAgent, _branchPort);
    }
}
