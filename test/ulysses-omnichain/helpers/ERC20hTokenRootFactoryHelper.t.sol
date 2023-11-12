//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library ERC20hTokenRootFactoryHelper {
    using ERC20hTokenRootFactoryHelper for ERC20hTokenRootFactory;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(ERC20hTokenRootFactory, RootPort _rootPort)
        internal
        returns (ERC20hTokenRootFactory _hTokenRootFactory)
    {
        _hTokenRootFactory = new ERC20hTokenRootFactory(address(_rootPort));

        _hTokenRootFactory.check_deploy(_rootPort, address(this));
    }

    function check_deploy(ERC20hTokenRootFactory _hTokenRootFactory, RootPort _rootPort, address _owner)
        internal
        view
    {
        _hTokenRootFactory.check_rootPort(_rootPort);
        _hTokenRootFactory.check_owner(_owner);
    }

    function check_rootPort(ERC20hTokenRootFactory _hTokenRootFactory, RootPort _rootPort) internal view {
        require(_hTokenRootFactory.rootPortAddress() == address(_rootPort), "Incorrect ERC20hTokenRootFactory RootPort");
    }

    function check_owner(ERC20hTokenRootFactory _hTokenRootFactory, address _owner) internal view {
        require(_hTokenRootFactory.owner() == _owner, "Incorrect ERC20hTokenRootFactory Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(ERC20hTokenRootFactory _hTokenRootFactory, CoreRootRouter _coreRootRouter) internal {
        _hTokenRootFactory.initialize(address(_coreRootRouter));

        _hTokenRootFactory.check_init(_coreRootRouter);
    }

    function check_init(ERC20hTokenRootFactory _hTokenRootFactory, CoreRootRouter _coreRootRouter) internal view {
        _hTokenRootFactory.check_coreRootRouter(_coreRootRouter);
        _hTokenRootFactory.check_owner(address(0));
    }

    function check_coreRootRouter(ERC20hTokenRootFactory _hTokenRootFactory, CoreRootRouter _coreRootRouter)
        internal
        view
    {
        require(
            _hTokenRootFactory.coreRootRouterAddress() == address(_coreRootRouter),
            "Incorrect ERC20hTokenRootFactory CoreRootRouter"
        );
    }
}
