//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library ERC20hTokenBranchFactoryHelper {
    using ERC20hTokenBranchFactoryHelper for ERC20hTokenBranchFactory;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(ERC20hTokenBranchFactory, BranchPort _branchPort, string memory _name, string memory _symbol)
        internal
        returns (ERC20hTokenBranchFactory _branchHTokenFactory)
    {
        _branchHTokenFactory = new ERC20hTokenBranchFactory(address(_branchPort), _name, _symbol);

        _branchHTokenFactory.check_deploy(_branchPort, _name, _symbol, address(this));
    }

    function check_deploy(
        ERC20hTokenBranchFactory _branchHTokenFactory,
        BranchPort _branchPort,
        string memory _name,
        string memory _symbol,
        address _owner
    ) internal view {
        _branchHTokenFactory.check_branchPort(_branchPort);
        _branchHTokenFactory.check_chainName(_name);
        _branchHTokenFactory.check_chainSymbol(_symbol);
        _branchHTokenFactory.check_owner(_owner);
    }

    function check_branchPort(ERC20hTokenBranchFactory _branchHTokenFactory, BranchPort _branchPort) internal view {
        require(
            _branchHTokenFactory.localPortAddress() == address(_branchPort),
            "Incorrect ERC20hTokenBranchFactory BranchPort"
        );
    }

    function check_chainName(ERC20hTokenBranchFactory _branchHTokenFactory, string memory _name) internal view {
        require(
            keccak256(bytes(_branchHTokenFactory.chainName())) == keccak256(bytes(string.concat(_name, " Ulysses"))),
            "Incorrect ERC20hTokenBranchFactory chain name"
        );
    }

    function check_chainSymbol(ERC20hTokenBranchFactory _branchHTokenFactory, string memory _symbol) internal view {
        require(
            keccak256(bytes(_branchHTokenFactory.chainSymbol())) == keccak256(bytes(string.concat(_symbol, "-u"))),
            "Incorrect ERC20hTokenBranchFactory chain symbol"
        );
    }

    function check_owner(ERC20hTokenBranchFactory _branchHTokenFactory, address _owner) internal view {
        require(_branchHTokenFactory.owner() == _owner, "Incorrect ERC20hTokenBranchFactory Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    /*
        require(_coreRouter != address(0), "CoreRouter address cannot be 0");
        renounceOwnership();

        ERC20hToken newToken = new ERC20hToken(
            chainName,
            chainSymbol,
            ERC20(_wrappedNativeTokenAddress).name(),
            ERC20(_wrappedNativeTokenAddress).symbol(),
            ERC20(_wrappedNativeTokenAddress).decimals(),
            localPortAddress
        );

        hTokens.push(newToken);

        localCoreRouterAddress = _coreRouter;
    */
    function _init(
        ERC20hTokenBranchFactory _branchHTokenFactory,
        address _branchWrappedNativeToken,
        CoreBranchRouter _coreBranchRouter
    ) internal {
        _branchHTokenFactory.initialize(_branchWrappedNativeToken, address(_coreBranchRouter));

        _branchHTokenFactory.check_init(_branchWrappedNativeToken, _coreBranchRouter);
    }

    function check_init(
        ERC20hTokenBranchFactory _branchHTokenFactory,
        address _branchWrappedNativeToken,
        CoreBranchRouter _coreBranchRouter
    ) internal view {
        _branchHTokenFactory.check_coreBranchRouter(_coreBranchRouter);
        _branchHTokenFactory.check_owner(address(0));
    }

    function check_coreBranchRouter(ERC20hTokenBranchFactory _branchHTokenFactory, CoreBranchRouter _coreBranchRouter)
        internal
        view
    {
        require(
            _branchHTokenFactory.localCoreRouterAddress() == address(_coreBranchRouter),
            "Incorrect ERC20hTokenBranchFactory CoreBranchRouter"
        );
    }
}
