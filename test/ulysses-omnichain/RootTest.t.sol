//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/ImportHelper.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract RootTest is DSTestPlus, BridgeAgentConstants {
    using SafeTransferLib for address;

    // Consts

    uint16 constant rootChainId = uint16(42161);

    uint16 constant avaxChainId = uint16(43114);

    uint16 constant ftmChainId = uint16(2040);

    //// System contracts

    // Root

    RootPort rootPort;

    ERC20hTokenRootFactory hTokenFactory;

    RootBridgeAgentFactory bridgeAgentFactory;

    RootBridgeAgent coreBridgeAgent;

    RootBridgeAgent multicallBridgeAgent;

    CoreRootRouter coreRootRouter;

    MulticallRootRouter rootMulticallRouter;

    // Arbitrum Branch

    ArbitrumBranchPort arbitrumPort;

    ERC20hTokenBranchFactory localHTokenFactory;

    ArbitrumBranchBridgeAgentFactory arbitrumBranchBridgeAgentFactory;

    ArbitrumBranchBridgeAgent arbitrumCoreBridgeAgent;

    ArbitrumBranchBridgeAgent arbitrumMulticallBridgeAgent;

    ArbitrumCoreBranchRouter arbitrumCoreRouter;

    BaseBranchRouter arbitrumMulticallRouter;

    // Avax Branch

    BranchPort avaxPort;

    ERC20hTokenBranchFactory avaxHTokenFactory;

    BranchBridgeAgentFactory avaxBranchBridgeAgentFactory;

    BranchBridgeAgent avaxCoreBridgeAgent;

    BranchBridgeAgent avaxMulticallBridgeAgent;

    CoreBranchRouter avaxCoreRouter;

    BaseBranchRouter avaxMulticallRouter;

    // Ftm Branch

    BranchPort ftmPort;

    ERC20hTokenBranchFactory ftmHTokenFactory;

    BranchBridgeAgentFactory ftmBranchBridgeAgentFactory;

    BranchBridgeAgent ftmCoreBridgeAgent;

    BranchBridgeAgent ftmMulticallBridgeAgent;

    CoreBranchRouter ftmCoreRouter;

    BaseBranchRouter ftmMulticallRouter;

    // ERC20s from different chains.

    address avaxMockAssethToken;

    MockERC20 avaxMockAssetToken;

    address ftmMockAssethToken;

    MockERC20 ftmMockAssetToken;

    ERC20hToken arbitrumMockAssethToken;

    MockERC20 arbitrumMockToken;

    // Mocks

    address arbitrumGlobalToken;
    address avaxGlobalToken;
    address ftmGlobalToken;

    address arbitrumWrappedNativeToken;
    address avaxWrappedNativeToken;
    address ftmWrappedNativeToken;

    address arbitrumLocalWrappedNativeToken;
    address avaxLocalWrappedNativeToken;
    address ftmLocalWrappedNativeToken;

    address multicallAddress;

    address testGasPoolAddress = address(0xFFFF);

    address nonFungiblePositionManagerAddress = address(0xABAD);

    address avaxLocalarbitrumWrappedNativeTokenAddress = address(0xBFFF);
    address avaxUnderlyingarbitrumWrappedNativeTokenAddress = address(0xFFFB);

    address ftmLocalarbitrumWrappedNativeTokenAddress = address(0xABBB);
    address ftmUnderlyingarbitrumWrappedNativeTokenAddress = address(0xAAAB);

    address avaxCoreBridgeAgentAddress = address(0xBEEF);

    address avaxMulticallBridgeAgentAddress = address(0xEBFE);

    address avaxPortAddress = address(0xFEEB);

    address ftmCoreBridgeAgentAddress = address(0xCACA);

    address ftmMulticallBridgeAgentAddress = address(0xACAC);

    address ftmPortAddressM = address(0xABAC);

    address lzEndpointAddress = address(new MockEndpoint());

    address owner = address(this);

    address dao = address(this);

    function setUp() public {
        /////////////////////////////////
        //      Deploy Root Utils      //
        /////////////////////////////////

        arbitrumWrappedNativeToken = address(new WETH());
        avaxWrappedNativeToken = address(new WETH());
        ftmWrappedNativeToken = address(new WETH());

        multicallAddress = address(new Multicall2());

        /////////////////////////////////
        //    Deploy Root Contracts    //
        /////////////////////////////////

        rootPort = new RootPort(rootChainId);

        bridgeAgentFactory = new RootBridgeAgentFactory(
            rootChainId,
            lzEndpointAddress,
            address(rootPort)
        );

        coreRootRouter = new CoreRootRouter(rootChainId, address(rootPort));

        rootMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        hTokenFactory = new ERC20hTokenRootFactory(address(rootPort));

        /////////////////////////////////
        //  Initialize Root Contracts  //
        /////////////////////////////////

        rootPort.initialize(address(bridgeAgentFactory), address(coreRootRouter));

        hevm.deal(address(rootPort), 1 ether);
        hevm.prank(address(rootPort));
        WETH(arbitrumWrappedNativeToken).deposit{value: 1 ether}();

        hTokenFactory.initialize(address(coreRootRouter));

        coreBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(coreRootRouter)))
        );

        multicallBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(rootMulticallRouter)))
        );

        coreRootRouter.initialize(address(coreBridgeAgent), address(hTokenFactory));

        rootMulticallRouter.initialize(address(multicallBridgeAgent));

        /////////////////////////////////
        // Deploy Local Branch Contracts//
        /////////////////////////////////

        arbitrumPort = new ArbitrumBranchPort(rootChainId, address(rootPort), owner);

        arbitrumMulticallRouter = new ArbitrumBaseBranchRouter();

        arbitrumCoreRouter = new ArbitrumCoreBranchRouter();

        arbitrumBranchBridgeAgentFactory = new ArbitrumBranchBridgeAgentFactory(
            rootChainId,
            address(bridgeAgentFactory),
            address(arbitrumCoreRouter),
            address(arbitrumPort),
            owner
        );

        arbitrumPort.initialize(address(arbitrumCoreRouter), address(arbitrumBranchBridgeAgentFactory));

        arbitrumBranchBridgeAgentFactory.initialize(address(coreBridgeAgent));
        arbitrumCoreBridgeAgent = ArbitrumBranchBridgeAgent(payable(arbitrumPort.bridgeAgents(0)));

        arbitrumCoreRouter.initialize(address(arbitrumCoreBridgeAgent));
        // ArbitrumMulticallRouter.initialize(address(arbitrumMulticallBridgeAgent));

        //////////////////////////////////
        // Deploy Avax Branch Contracts //
        //////////////////////////////////

        avaxPort = new BranchPort(owner);

        avaxHTokenFactory = new ERC20hTokenBranchFactory(address(avaxPort), "Avalanche Ulysses ", "avax-u");

        avaxMulticallRouter = new BaseBranchRouter();

        avaxCoreRouter = new CoreBranchRouter(address(avaxHTokenFactory));

        avaxBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            avaxChainId,
            rootChainId,
            address(bridgeAgentFactory),
            lzEndpointAddress,
            address(avaxCoreRouter),
            address(avaxPort),
            owner
        );

        avaxPort.initialize(address(avaxCoreRouter), address(avaxBranchBridgeAgentFactory));

        avaxBranchBridgeAgentFactory.initialize(address(coreBridgeAgent));
        avaxCoreBridgeAgent = BranchBridgeAgent(payable(avaxPort.bridgeAgents(0)));

        avaxHTokenFactory.initialize(avaxWrappedNativeToken, address(avaxCoreRouter));
        avaxLocalWrappedNativeToken = 0x386Cc0A3450d41747C05C62381320C039C65ee0d;

        avaxCoreRouter.initialize(address(avaxCoreBridgeAgent));

        //////////////////////////////////
        // Deploy Ftm Branch Contracts //
        //////////////////////////////////

        ftmPort = new BranchPort(owner);

        ftmHTokenFactory = new ERC20hTokenBranchFactory(address(ftmPort), "Fantom Ulysses ", "ftm-u");

        ftmMulticallRouter = new BaseBranchRouter();

        ftmCoreRouter = new CoreBranchRouter(address(ftmHTokenFactory));

        ftmBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(bridgeAgentFactory),
            lzEndpointAddress,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        ftmPort.initialize(address(ftmCoreRouter), address(ftmBranchBridgeAgentFactory));

        ftmBranchBridgeAgentFactory.initialize(address(coreBridgeAgent));
        ftmCoreBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(0)));

        ftmHTokenFactory.initialize(ftmWrappedNativeToken, address(ftmCoreRouter));
        ftmLocalWrappedNativeToken = 0x0315E8648695243BCE3Da6a0Ce973867B75Db847;

        ftmCoreRouter.initialize(address(ftmCoreBridgeAgent));

        /////////////////////////////
        //  Add new branch chains  //
        /////////////////////////////

        RootPort(rootPort).addNewChain(
            address(avaxCoreBridgeAgent),
            avaxChainId,
            "Avalanche",
            "AVAX",
            18,
            avaxLocalWrappedNativeToken,
            avaxWrappedNativeToken
        );

        RootPort(rootPort).addNewChain(
            address(ftmCoreBridgeAgent),
            ftmChainId,
            "Fantom Opera",
            "FTM",
            18,
            ftmLocalWrappedNativeToken,
            ftmWrappedNativeToken
        );

        avaxGlobalToken = RootPort(rootPort).getGlobalTokenFromLocal(avaxLocalWrappedNativeToken, avaxChainId);

        ftmGlobalToken = RootPort(rootPort).getGlobalTokenFromLocal(ftmLocalWrappedNativeToken, ftmChainId);

        //////////////////////
        // Verify Addition  //
        //////////////////////

        require(RootPort(rootPort).isGlobalAddress(avaxGlobalToken), "Token should be added");

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(avaxLocalWrappedNativeToken), avaxChainId)
                == avaxGlobalToken,
            "Token should be added"
        );

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(avaxGlobalToken, avaxChainId)
                == address(avaxLocalWrappedNativeToken),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(avaxLocalWrappedNativeToken), avaxChainId)
                == address(avaxWrappedNativeToken),
            "Token should be added"
        );

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(ftmLocalWrappedNativeToken), ftmChainId)
                == ftmGlobalToken,
            "Token should be added"
        );

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(ftmGlobalToken, ftmChainId)
                == address(ftmLocalWrappedNativeToken),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(ftmLocalWrappedNativeToken), ftmChainId)
                == address(ftmWrappedNativeToken),
            "Token should be added"
        );

        ///////////////////////////////////
        //  Approve new Branchs in Root  //
        ///////////////////////////////////

        rootPort.initializeCore(address(coreBridgeAgent), address(arbitrumCoreBridgeAgent), address(arbitrumPort));

        multicallBridgeAgent.approveBranchBridgeAgent(rootChainId);

        multicallBridgeAgent.approveBranchBridgeAgent(avaxChainId);

        multicallBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        ///////////////////////////////////////
        //  Add new branches to  Root Agents //
        ///////////////////////////////////////

        hevm.deal(address(this), 3 ether);

        coreRootRouter.addBranchToBridgeAgent{value: 1 ether}(
            address(multicallBridgeAgent),
            address(avaxBranchBridgeAgentFactory),
            address(avaxMulticallRouter),
            address(this),
            avaxChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );

        coreRootRouter.addBranchToBridgeAgent{value: 1 ether}(
            address(multicallBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(ftmMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );

        coreRootRouter.addBranchToBridgeAgent(
            address(multicallBridgeAgent),
            address(arbitrumBranchBridgeAgentFactory),
            address(arbitrumMulticallRouter),
            address(this),
            rootChainId,
            [GasParams(0, 0), GasParams(0, 0)]
        );

        /////////////////////////////////////
        //  Initialize new Branch Routers  //
        /////////////////////////////////////

        arbitrumMulticallBridgeAgent = ArbitrumBranchBridgeAgent(payable(arbitrumPort.bridgeAgents(1)));
        avaxMulticallBridgeAgent = BranchBridgeAgent(payable(avaxPort.bridgeAgents(1)));
        ftmMulticallBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(1)));

        arbitrumMulticallRouter.initialize(address(arbitrumMulticallBridgeAgent));
        avaxMulticallRouter.initialize(address(avaxMulticallBridgeAgent));
        ftmMulticallRouter.initialize(address(ftmMulticallBridgeAgent));

        //////////////////////////////////////
        // Deploy Underlying Tokens and Mocks//
        //////////////////////////////////////

        // avaxMockAssethToken = new MockERC20("hTOKEN-AVAX", "LOCAL hTOKEN FOR TOKEN IN AVAX", 18);
        avaxMockAssetToken = new MockERC20("underlying token", "UNDER", 18);

        // ftmMockAssethToken = new MockERC20("hTOKEN-FTM", "LOCAL hTOKEN FOR TOKEN IN FMT", 18);
        ftmMockAssetToken = new MockERC20("underlying token", "UNDER", 18);

        // ArbitrumMockAssethToken is global
        arbitrumMockToken = new MockERC20("underlying token", "UNDER", 18);
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                             TEST HELPERS
    //////////////////////////////////////////////////////////////*/

    function _parseDepositAndWithdrawAmounts(uint256 _amount, uint256 _deposit)
        internal
        pure
        returns (uint256, uint256)
    {
        // Can't withdraw 0
        if (_amount == 0) return (1, 0);

        // We want to transfer at least 1 hToken
        if (_amount <= _deposit) return (_amount, _deposit % _amount);

        return (_amount, _deposit);
    }

    //////////////////////////////////////
    //      Bridge To Chain Amounts     //
    //////////////////////////////////////

    function test_bridgeToBranch_arbMockToken_fromRemoteBranch() public {
        test_bridgeToBranch_arbMockToken(address(this), 100 ether, 50 ether, ftmChainId);
    }

    function test_bridgeToBranch_arbMockToken_fromLocalBranch() public {
        test_bridgeToBranch_arbMockToken(address(this), 100 ether, 50 ether, rootChainId);
    }

    function test_bridgeToBranch_arbMockToken(address _from, uint256 _amount, uint256 _deposit, uint256 _dstChainId)
        public
    {
        (_amount, _deposit) = _parseDepositAndWithdrawAmounts(_amount, _deposit);

        // Add arbitrumMockToken to the ecosystem as underlying
        testAddLocalTokenArbitrum();

        _test_bridgeToBranch(_from, newArbitrumAssetGlobalAddress, _amount, _deposit, _dstChainId);
    }

    function _test_bridgeToBranch(
        address _from,
        address _hToken,
        uint256 _amount,
        uint256 _deposit,
        uint256 _dstChainId
    ) internal {
        hevm.prank(address(rootPort));
        MockERC20(_hToken).mint(_from, _amount);

        hevm.prank(_from);
        _hToken.safeApprove(address(rootPort), _amount);

        uint256 priorBalanceOfFrom = _hToken.balanceOf(_from);
        uint256 priorBalanceOfPort = _hToken.balanceOf(address(rootPort));
        uint256 priorBalanceOfBranch = rootPort.getBalanceOfBranch(_hToken, _dstChainId);
        uint256 priorTotalSupplyBranch = rootPort.getTotalSupplyBranches(_hToken);

        hevm.prank(address(multicallBridgeAgent));
        rootPort.bridgeToBranch(_from, _hToken, _amount, _deposit, _dstChainId);

        uint256 balanceDiff = _amount - _deposit;

        assertEq(_hToken.balanceOf(_from), priorBalanceOfFrom - _amount);
        assertEq(_hToken.balanceOf(address(rootPort)), priorBalanceOfPort + balanceDiff);

        if (_dstChainId != rootChainId) {
            assertEq(rootPort.getBalanceOfBranch(_hToken, _dstChainId), priorBalanceOfBranch + balanceDiff);
            assertEq(rootPort.getTotalSupplyBranches(_hToken), priorTotalSupplyBranch + balanceDiff);
        } else {
            assertEq(rootPort.getBalanceOfBranch(_hToken, _dstChainId), priorBalanceOfBranch);
            assertEq(rootPort.getTotalSupplyBranches(_hToken), priorTotalSupplyBranch);
        }
    }

    function test_bridgeToRoot_arbMockToken_fromRemoteBranch() public {
        test_bridgeToRoot_arbMockToken(address(this), 100 ether, 50 ether, ftmChainId);
    }

    function test_bridgeToRoot_arbMockToken_fromLocalBranch() public {
        test_bridgeToRoot_arbMockToken(address(this), 100 ether, 50 ether, rootChainId);
    }

    function test_bridgeToRoot_arbMockToken(address _to, uint256 _amount, uint256 _deposit, uint256 _srcChainId)
        public
    {
        (_amount, _deposit) = _parseDepositAndWithdrawAmounts(_amount, _deposit);

        test_bridgeToBranch_arbMockToken(_to, _amount, _deposit, _srcChainId);

        _test_bridgeToRoot(_to, newArbitrumAssetGlobalAddress, _amount, _deposit, _srcChainId);
    }

    function _test_bridgeToRoot(address _to, address _hToken, uint256 _amount, uint256 _deposit, uint256 _srcChainId)
        internal
    {
        uint256 priorBalanceOfTo = _hToken.balanceOf(_to);
        uint256 priorBalanceOfPort = _hToken.balanceOf(address(rootPort));
        uint256 priorBalanceOfBranch = rootPort.getBalanceOfBranch(_hToken, _srcChainId);
        uint256 priorTotalSupplyBranch = rootPort.getTotalSupplyBranches(_hToken);

        hevm.prank(address(multicallBridgeAgent));
        rootPort.bridgeToRoot(_to, _hToken, _amount, _deposit, _srcChainId);

        uint256 balanceDiff = _amount - _deposit;

        assertEq(_hToken.balanceOf(address(_to)), priorBalanceOfTo + _amount);
        assertEq(_hToken.balanceOf(address(rootPort)), priorBalanceOfPort - balanceDiff);

        if (_srcChainId != rootChainId) {
            assertEq(rootPort.getBalanceOfBranch(_hToken, _srcChainId), priorBalanceOfBranch - balanceDiff);
            assertEq(rootPort.getTotalSupplyBranches(_hToken), priorTotalSupplyBranch - balanceDiff);
        } else {
            assertEq(rootPort.getBalanceOfBranch(_hToken, _srcChainId), priorBalanceOfBranch);
            assertEq(rootPort.getTotalSupplyBranches(_hToken), priorTotalSupplyBranch);
        }
    }

    function test_bridgeToRoot_arbMockToken_ChainInsufficientBalance(
        address _to,
        uint256 _amount,
        uint256 _deposit,
        uint256 _dstChainId,
        uint256 _srcChainId
    ) public {
        if (_amount == 0) _amount = 1;
        if (_dstChainId == _srcChainId) _dstChainId = _srcChainId == 0 ? 1 : _srcChainId - 1;

        (_amount, _deposit) = _parseDepositAndWithdrawAmounts(_amount, _deposit);

        // Bridge to a different branch
        test_bridgeToBranch_arbMockToken(_to, _amount, _deposit, _dstChainId);

        if (_srcChainId == rootChainId) {
            hevm.expectRevert(IRootPort.InsufficientBalance.selector);
        } else {
            hevm.expectRevert(stdError.arithmeticError);
        }
        hevm.prank(address(multicallBridgeAgent));
        rootPort.bridgeToRoot(_to, newArbitrumAssetGlobalAddress, _amount, _deposit, _srcChainId);
    }

    function test_bridgeToRoot_arbMockToken_NoDeposit(
        address _to,
        uint256 _amount,
        uint256 _deposit,
        uint256 _srcChainId
    ) public {
        if (_amount == 0) _amount = 1;

        (_amount, _deposit) = _parseDepositAndWithdrawAmounts(_amount, _deposit);

        // Add arbitrumMockToken to the ecosystem as underlying
        testAddLocalTokenArbitrum();

        hevm.expectRevert(stdError.arithmeticError);
        hevm.prank(address(multicallBridgeAgent));
        rootPort.bridgeToRoot(_to, newArbitrumAssetGlobalAddress, _amount, _deposit, _srcChainId);
    }

    function test_bridgeToLocalBranchFromRoot_arbMockToken() public {
        test_bridgeToLocalBranchFromRoot_arbMockToken(address(this), 100 ether);
    }

    function test_bridgeToLocalBranchFromRoot_arbMockToken(address _to, uint256 _amount) public {
        // Add arbitrumMockToken to the ecosystem as underlying
        testAddLocalTokenArbitrum();

        // Mock bridgeToRootFromLocalBranch
        hevm.prank(address(rootPort));
        MockERC20(newArbitrumAssetGlobalAddress).mint(address(rootPort), _amount);

        _test_bridgeToLocalBranchFromRoot(_to, newArbitrumAssetGlobalAddress, _amount);
    }

    // function test_bridgeToLocalBranchFromRoot_ecosystemToken(address _to, uint256 _amount, uint256 _deposit)
    //     public
    // {
    // // Mock bridgeToRootFromLocalBranch
    // hevm.prank(address(rootPort));
    // MockERC20(newArbitrumAssetGlobalAddress).mint(address(rootPort), _amount);

    // _test_bridgeToLocalBranchFromRoot(_to, newArbitrumAssetGlobalAddress, _amount);
    // }

    function _test_bridgeToLocalBranchFromRoot(address _to, address _hToken, uint256 _amount) internal {
        uint256 priorBalanceOfTo = _hToken.balanceOf(_to);
        uint256 priorBalanceOfPort = _hToken.balanceOf(address(rootPort));
        uint256 priorTotalSupplyBranch = rootPort.getTotalSupplyBranches(_hToken);

        hevm.prank(address(arbitrumPort));
        rootPort.bridgeToLocalBranchFromRoot(_to, _hToken, _amount);

        assertEq(_hToken.balanceOf(address(_to)), priorBalanceOfTo + _amount);
        assertEq(_hToken.balanceOf(address(rootPort)), priorBalanceOfPort - _amount);

        assertEq(rootPort.getTotalSupplyBranches(_hToken), priorTotalSupplyBranch);
    }

    function test_bridgeToLocalBranchFromRoot_arbMockToken_ChainInsufficientBalance(
        address _to,
        uint128 _amount,
        uint256 _dstChainId
    ) public {
        if (_amount == 0) _amount = 1;

        // Bridge to a different branch
        test_bridgeToBranch_arbMockToken(_to, _amount, 0, _dstChainId);

        hevm.expectRevert(IRootPort.InsufficientBalance.selector);
        hevm.prank(address(arbitrumPort));
        rootPort.bridgeToLocalBranchFromRoot(_to, newArbitrumAssetGlobalAddress, _amount);
    }

    function test_bridgeToLocalBranchFromRoot_arbMockToken_NoDeposit(address _to, uint256 _amount) public {
        if (_amount == 0) _amount = 1;

        // Add arbitrumMockToken to the ecosystem as underlying
        testAddLocalTokenArbitrum();

        hevm.expectRevert(IRootPort.InsufficientBalance.selector);
        hevm.prank(address(arbitrumPort));
        rootPort.bridgeToLocalBranchFromRoot(_to, newArbitrumAssetGlobalAddress, _amount);
    }

    //////////////////////////////////////
    //         Ecosystem Tokens         //
    //////////////////////////////////////

    function testAddEcosystemToken(address _ecosystemToken) public {
        rootPort.addEcosystemToken(_ecosystemToken);

        console2.log("New Ecosystem Token: ", _ecosystemToken);

        require(RootPort(rootPort).isGlobalAddress(_ecosystemToken), "Eco Token should be added");
        require(
            RootPort(rootPort).getGlobalTokenFromLocal(_ecosystemToken, rootChainId) == _ecosystemToken,
            "Eco Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(_ecosystemToken, rootChainId) == _ecosystemToken,
            "Eco Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(_ecosystemToken, rootChainId) == address(0),
            "Eco Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromUnderlying(_ecosystemToken, rootChainId) == address(0),
            "Eco Token should be added"
        );
    }

    function testAddEcosystemToken_AlreadyAdded_NoDeposit() public {
        // Add arbitrumMockToken to the ecosystem as underlying
        testAddLocalTokenArbitrum();

        // There are no deposits so the total supply should be 0
        require(MockERC20(newArbitrumAssetGlobalAddress).totalSupply() == 0, "TotalSupply should be 0");

        // The admin can still add an ecosystem token because there were no deposits
        testAddEcosystemToken(address(arbitrumMockToken));
    }

    function testAddEcosystemToken_AlreadyAdded_WithDeposit() public {
        // Add arbitrumMockToken to the ecosystem as underlying and make a deposit
        testCallOutWithDeposit();

        // The admin can no longer add an ecosystem token because there were deposits
        hevm.expectRevert(abi.encodeWithSignature("AlreadyAddedEcosystemToken()"));
        rootPort.addEcosystemToken(address(arbitrumMockToken));
    }

    //////////////////////////////////////
    //           Bridge Agents          //
    //////////////////////////////////////

    function testAddBridgeAgent() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        // Get some gas
        hevm.deal(address(this), 1 ether);

        // Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(testMulticallRouter)))
        );

        // Initialize Router
        testMulticallRouter.initialize(address(testRootBridgeAgent));

        // Create Branch Router
        BaseBranchRouter ftmTestRouter = new BaseBranchRouter();

        // Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        // Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );

        console2.log("new branch bridge agent", ftmPort.bridgeAgents(2));

        BranchBridgeAgent ftmTestBranchBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(2)));

        ftmTestRouter.initialize(address(ftmTestBranchBridgeAgent));

        require(testRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == address(ftmTestBranchBridgeAgent));
    }

    function testAddBridgeAgentAlreadyAdded() public {
        testAddBridgeAgent();

        // Get some gas
        hevm.deal(address(this), 1 ether);

        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(payable(rootPort.bridgeAgents(2)));

        hevm.expectRevert(abi.encodeWithSignature("AlreadyAddedBridgeAgent()"));

        // Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);
    }

    function testAddBridgeAgentTwice() public {
        testAddBridgeAgent();

        // Get some gas
        hevm.deal(address(this), 1 ether);

        // Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(payable(rootPort.bridgeAgents(2)));

        hevm.expectRevert(abi.encodeWithSignature("InvalidChainId()"));

        // Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );
    }

    function testAddBridgeAgentNotApproved() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        // Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(testMulticallRouter)))
        );

        // Initialize Router
        testMulticallRouter.initialize(address(testRootBridgeAgent));

        hevm.expectRevert(abi.encodeWithSignature("UnauthorizedChainId()"));

        // Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );
    }

    function testAddBridgeAgentNotManager() public {
        // Get some gas
        hevm.deal(address(89), 1 ether);

        // Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(testMulticallRouter)))
        );

        // Initialize Router
        testMulticallRouter.initialize(address(testRootBridgeAgent));

        hevm.startPrank(address(89));

        hevm.expectRevert(abi.encodeWithSignature("UnauthorizedCallerNotManager()"));
        // Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );
    }

    function testAddBridgeAgentWrongBranchFactory() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        //Create Root Router
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(testMulticallRouter)))
        );

        // Initialize Router
        testMulticallRouter.initialize(address(testRootBridgeAgent));

        // Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        // Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(32),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );

        require(
            RootBridgeAgent(testRootBridgeAgent).getBranchBridgeAgent(ftmChainId) == address(0),
            "Branch Bridge Agent should not be created"
        );
    }

    //////////////////////////////////////
    //        Bridge Agent Factory     //
    //////////////////////////////////////

    BranchBridgeAgentFactory public newFtmBranchBridgeAgentFactory;

    function testAddBridgeAgentFactory() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        newFtmBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(80),
            lzEndpointAddress,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        console2.log("Core Router Owner", coreRootRouter.owner());

        coreRootRouter.toggleBranchBridgeAgentFactory{value: 0.05 ether}(
            address(bridgeAgentFactory),
            address(newFtmBranchBridgeAgentFactory),
            address(this),
            ftmChainId,
            GasParams(0.05 ether, 0.05 ether)
        );

        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Factory not enabled");
    }

    function testAddBridgeAgentWrongRootFactory() public {
        testAddBridgeAgentFactory();

        // Get some gas
        hevm.deal(address(this), 1 ether);

        // Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(testMulticallRouter)))
        );

        // Initialize Router
        testMulticallRouter.initialize(address(testRootBridgeAgent));

        // Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        // Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(newFtmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );

        require(
            RootBridgeAgent(testRootBridgeAgent).getBranchBridgeAgent(ftmChainId) == address(0),
            "Branch Bridge Agent should not be created"
        );
    }

    function testRemoveBridgeAgentFactory() public {
        // Add Factory
        testAddBridgeAgentFactory();

        // Get some gas
        hevm.deal(address(this), 1 ether);

        coreRootRouter.toggleBranchBridgeAgentFactory{value: 0.05 ether}(
            address(bridgeAgentFactory),
            address(newFtmBranchBridgeAgentFactory),
            address(this),
            ftmChainId,
            GasParams(0.05 ether, 0.05 ether)
        );

        require(!ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Should be disabled");
    }

    //////////////////////////////////////
    //           Port Strategies        //
    //////////////////////////////////////

    function testAddStrategyToken() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        coreRootRouter.toggleStrategyToken{value: 0.05 ether}(
            address(102), 7000, address(this), ftmChainId, GasParams(0.05 ether, 0.05 ether)
        );

        require(ftmPort.isStrategyToken(address(102)), "Should be added");
    }

    function testAddStrategyTokenInvalidMinReserve() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        // hevm.expectRevert(abi.encodeWithSignature("InvalidMinimumReservesRatio()"));
        coreRootRouter.toggleStrategyToken{value: 0.05 ether}(
            address(102), 30000, address(this), ftmChainId, GasParams(0.05 ether, 0.05 ether)
        );
        require(!ftmPort.isStrategyToken(address(102)), "Should note be added");
    }

    function testRemoveStrategyToken() public {
        // Add Token
        testAddStrategyToken();

        // Get some gas
        hevm.deal(address(this), 1 ether);

        coreRootRouter.toggleStrategyToken{value: 0.05 ether}(
            address(102), 0, address(this), ftmChainId, GasParams(0.05 ether, 0.05 ether)
        );

        require(!ftmPort.isStrategyToken(address(102)), "Should be removed");
    }

    function testAddPortStrategy() public {
        // Add strategy token
        testAddStrategyToken();

        // Get some gas
        hevm.deal(address(this), 1 ether);

        coreRootRouter.togglePortStrategy{value: 0.05 ether}(
            address(50), address(102), 7000, 7000, address(this), ftmChainId, GasParams(0.05 ether, 0)
        );

        require(ftmPort.isPortStrategy(address(50), address(102)), "Should be added");
    }

    function testAddPortStrategyNotToken() public {
        // Get some gas
        hevm.deal(address(this), 1 ether);

        //UnrecognizedStrategyToken();
        coreRootRouter.togglePortStrategy{value: 0.1 ether}(
            address(50), address(102), 7000, 7000, address(this), ftmChainId, GasParams(0.05 ether, 0.05 ether)
        );

        require(!ftmPort.isPortStrategy(address(50), address(102)), "Should not be added");
    }

    //////////////////////////////////////
    //          TOKEN MANAGEMENT        //
    //////////////////////////////////////

    address public newAvaxAssetGlobalAddress;

    function testAddLocalToken() public {
        hevm.deal(address(this), 1 ether);

        avaxCoreRouter.addLocalToken{value: 0.1 ether}(address(avaxMockAssetToken), GasParams(0.5 ether, 0.5 ether));

        avaxMockAssethToken = RootPort(rootPort).getLocalTokenFromUnderlying(address(avaxMockAssetToken), avaxChainId);

        newAvaxAssetGlobalAddress = RootPort(rootPort).getGlobalTokenFromLocal(avaxMockAssethToken, avaxChainId);

        console2.log("New Global: ", newAvaxAssetGlobalAddress);
        console2.log("New Local: ", avaxMockAssethToken);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(avaxMockAssethToken, avaxChainId) == newAvaxAssetGlobalAddress,
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, avaxChainId) == avaxMockAssethToken,
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(avaxMockAssethToken, avaxChainId)
                == address(avaxMockAssetToken),
            "Token should be added"
        );
    }

    address public newFtmAssetGlobalAddress;

    address public newAvaxAssetLocalToken;

    function testAddGlobalToken() public {
        // Add Local Token from Avax
        testAddLocalToken();

        GasParams[3] memory gasParams =
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.05 ether, 0.0025 ether), GasParams(0.002 ether, 0)];

        avaxCoreRouter.addGlobalToken{value: 0.15 ether}(newAvaxAssetGlobalAddress, ftmChainId, gasParams);

        newAvaxAssetLocalToken = RootPort(rootPort).getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId);

        console2.log("New Local: ", newAvaxAssetLocalToken);

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId) == newAvaxAssetLocalToken,
            "Token should be added"
        );

        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(newAvaxAssetLocalToken, ftmChainId) == address(0),
            "Underlying should not be added"
        );
    }

    address public mockApp = address(0xDAFA);

    address public newArbitrumAssetGlobalAddress;

    function testAddLocalTokenArbitrum() public {
        // Set up
        testAddGlobalToken();

        // Get some gas.
        hevm.deal(address(this), 1 ether);

        //Add new localToken
        arbitrumCoreRouter.addLocalToken{value: 0.0005 ether}(
            address(arbitrumMockToken), GasParams(0.5 ether, 0.5 ether)
        );

        newArbitrumAssetGlobalAddress =
            RootPort(rootPort).getLocalTokenFromUnderlying(address(arbitrumMockToken), rootChainId);

        console2.log("New: ", newArbitrumAssetGlobalAddress);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newArbitrumAssetGlobalAddress, rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(arbitrumMockToken),
            "Token should be added"
        );
    }

    //////////////////////////////////////
    //          TOKEN TRANSFERS         //
    //////////////////////////////////////

    function testCallOutWithDeposit() public {
        // Set up
        testAddLocalTokenArbitrum();

        // Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newArbitrumAssetGlobalAddress;
            amountOut = 100 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Mock Omnichain dApp call
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams =
                OutputParams(address(this), address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = rootChainId;

            // RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(address(this), 1 ether);

        // Mint Underlying Token.
        arbitrumMockToken.mint(address(this), 100 ether);

        // Approve spend by router
        arbitrumMockToken.approve(address(arbitrumPort), 100 ether);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumMockToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        arbitrumMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            packedData, depositInput, GasParams(0.5 ether, 0.5 ether), true
        );

        // Test If Deposit was successful
        testCreateDepositSingle(
            arbitrumMulticallBridgeAgent,
            uint32(1),
            address(this),
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumMockToken),
            100 ether,
            100 ether,
            GasParams(0.5 ether, 0.5 ether)
        );

        console2.log("LocalPort Balance:", MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)));
        require(
            MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)) == 50 ether, "LocalPort should have 50 tokens"
        );

        console2.log("User Balance:", MockERC20(arbitrumMockToken).balanceOf(address(this)));
        require(MockERC20(arbitrumMockToken).balanceOf(address(this)) == 50 ether, "User should have 50 tokens");

        console2.log("User Global Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)));
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)) == 50 ether,
            "User should have 50 global tokens"
        );
    }

    function testFuzzCallOutWithDeposit(
        address _user,
        uint256 _amount,
        uint256 _deposit,
        uint256 _amountOut,
        uint256 _depositOut
    ) public {
        // Input restrictions
        _amount %= type(uint256).max / 1 ether;

        uint256 size;
        assembly {
            size := extcodesize(_user)
        }

        // Input restrictions
        hevm.assume(
            _user != address(0) && size == 0 && _amount > _deposit && _amount >= _amountOut
                && _amount - _amountOut >= _depositOut && _depositOut < _amountOut
        );

        // Set up
        testAddLocalTokenArbitrum();

        // Prepare data
        bytes memory packedData;

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Mock Omnichain dApp call
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams =
                OutputParams(_user, _user, newArbitrumAssetGlobalAddress, _amountOut, _depositOut);

            // RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, rootChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(_user, 1 ether);

        if (_amount - _deposit > 0) {
            // Assure there is enough balance for mock action
            hevm.startPrank(address(rootPort));
            ERC20hToken(newArbitrumAssetGlobalAddress).mint(_user, _amount - _deposit);
            hevm.stopPrank();
            arbitrumMockToken.mint(address(arbitrumPort), _amount - _deposit);
        }

        // Mint Underlying Token.
        if (_deposit > 0) arbitrumMockToken.mint(_user, _deposit);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumMockToken),
            amount: _amount,
            deposit: _deposit
        });

        console2.log("BALANCE BEFORE:");
        console2.log("arbitrumMockToken Balance:", MockERC20(arbitrumMockToken).balanceOf(_user));
        console2.log(
            "newArbitrumAssetGlobalAddress Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user)
        );

        // Call Deposit function
        hevm.startPrank(_user);
        arbitrumMockToken.approve(address(arbitrumPort), _deposit);
        ERC20hToken(newArbitrumAssetGlobalAddress).approve(address(rootPort), _amount - _deposit);
        arbitrumMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            packedData, depositInput, GasParams(0.5 ether, 0.5 ether), true
        );
        hevm.stopPrank();

        // Test If Deposit was successful
        testCreateDepositSingle(
            arbitrumMulticallBridgeAgent,
            uint32(1),
            _user,
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumMockToken),
            _amount,
            _deposit,
            GasParams(0.05 ether, 0.05 ether)
        );

        console2.log("DATA");
        console2.log(_amount);
        console2.log(_deposit);
        console2.log(_amountOut);
        console2.log(_depositOut);

        address userAccount = address(RootPort(rootPort).getUserAccount(_user));

        console2.log("LocalPort Balance:", MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)));
        console2.log("Expected:", _amount - _deposit + _deposit - _depositOut);
        require(
            MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)) == _amount - _deposit + _deposit - _depositOut,
            "LocalPort tokens"
        );

        console2.log("RootPort Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)));
        // console2.log("Expected:", 0); SINCE ORIGIN == DESTINATION == ARBITRUM
        require(MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)) == 0, "RootPort tokens");

        console2.log("User Balance:", MockERC20(arbitrumMockToken).balanceOf(_user));
        console2.log("Expected:", _depositOut);
        require(MockERC20(arbitrumMockToken).balanceOf(_user) == _depositOut, "User tokens");

        console2.log("User Global Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user));
        console2.log("Expected:", _amountOut - _depositOut);
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user) == _amountOut - _depositOut, "User Global tokens"
        );

        console2.log("User Account Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(userAccount));
        console2.log("Expected:", _amount - _amountOut);
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(userAccount) == _amount - _amountOut,
            "User Account tokens"
        );
    }

    function testRetrySettlement() public {
        // Set up
        testAddLocalTokenArbitrum();

        // Prepare data
        bytes memory packedData;

        address _user = address(0x420);

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Mock Omnichain dApp call
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams = OutputParams(_user, _user, newAvaxAssetGlobalAddress, 150 ether, 0);

            // RLP Encode Calldata Call with no gas to bridge out and we top up.
            bytes memory data = abi.encode(calls, outputParams, avaxChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }
        // Get some gas.
        hevm.deal(_user, 1 ether);

        // Assure there is enough balance for mock action
        hevm.prank(address(rootPort));
        ERC20hToken(newAvaxAssetGlobalAddress).mint(address(multicallBridgeAgent), 150 ether);
        hevm.prank(address(avaxPort));
        ERC20hToken(avaxMockAssethToken).mint(_user, 50 ether);

        hevm.startPrank(address(multicallBridgeAgent));
        ERC20hToken(newAvaxAssetGlobalAddress).approve(address(rootPort), 50 ether);
        rootPort.bridgeToBranch(
            address(multicallBridgeAgent), newAvaxAssetGlobalAddress, 150 ether, 100 ether, avaxChainId
        );
        hevm.stopPrank();

        // Mint Underlying Token.
        avaxMockAssetToken.mint(_user, 100 ether);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 150 ether,
            deposit: 100 ether
        });

        console2.log("BALANCE BEFORE:");
        console2.log("User avaxMockAssetToken Balance:", MockERC20(avaxMockAssetToken).balanceOf(_user));
        console2.log("User avaxMockAssethToken Balance:", MockERC20(avaxMockAssethToken).balanceOf(_user));

        //Set MockEndpoint _fallback mode ON
        MockEndpoint(lzEndpointAddress).toggleFallback(1);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        hevm.startPrank(_user);

        // Call Deposit function
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(packedData, depositInput, gasParams, false);

        //Set MockEndpoint _fallback mode OFF
        MockEndpoint(lzEndpointAddress).toggleFallback(0);

        uint32 settlementNonce = multicallBridgeAgent.settlementNonce() - 1;

        Settlement memory settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

        require(settlement.status == STATUS_SUCCESS, "Settlement status should be success.");

        // Get some gas.
        hevm.deal(_user, 1 ether);

        console2.log("asdasdas", address(avaxMulticallBridgeAgent));

        //Retry Settlement
        rootMulticallRouter.retrySettlement{value: 1 ether}(
            settlementNonce, address(this), "", GasParams(0.5 ether, 0.5 ether), true
        );

        hevm.stopPrank();

        settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

        require(settlement.status == STATUS_SUCCESS, "Settlement status should be success.");

        require(avaxMulticallBridgeAgent.executionState(settlementNonce) == 1, "Settelement Executed in branch");
    }

    function testRetryTwoSettlements() public {
        // Set up
        testAddLocalTokenArbitrum();

        address _user = address(0x420);

        {
            // Prepare data
            bytes memory _packedData;

            {
                Multicall2.Call[] memory calls = new Multicall2.Call[](1);

                // Mock Omnichain dApp call
                calls[0] = Multicall2.Call({
                    target: newAvaxAssetGlobalAddress,
                    callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
                });

                // Output Params
                OutputParams memory outputParams = OutputParams(_user, _user, newAvaxAssetGlobalAddress, 150 ether, 0);

                // RLP Encode Calldata Call with no gas to bridge out and we top up.
                bytes memory data = abi.encode(calls, outputParams, avaxChainId);

                // Pack FuncId
                _packedData = abi.encodePacked(bytes1(0x02), data);
            }

            // Get some gas.
            hevm.deal(_user, 1 ether);

            // Assure there is enough balance for mock action
            hevm.prank(address(rootPort));
            ERC20hToken(newAvaxAssetGlobalAddress).mint(address(multicallBridgeAgent), 150 ether);
            hevm.prank(address(avaxPort));
            ERC20hToken(avaxMockAssethToken).mint(_user, 50 ether);

            hevm.startPrank(address(multicallBridgeAgent));
            ERC20hToken(newAvaxAssetGlobalAddress).approve(address(rootPort), 50 ether);
            rootPort.bridgeToBranch(
                address(multicallBridgeAgent), newAvaxAssetGlobalAddress, 150 ether, 100 ether, avaxChainId
            );
            hevm.stopPrank();

            // Mint Underlying Token.
            avaxMockAssetToken.mint(_user, 100 ether);

            // Prepare deposit info
            DepositInput memory depositInput = DepositInput({
                hToken: address(avaxMockAssethToken),
                token: address(avaxMockAssetToken),
                amount: 150 ether,
                deposit: 100 ether
            });

            console2.log("BALANCE BEFORE:");
            console2.log("User avaxMockAssetToken Balance:", MockERC20(avaxMockAssetToken).balanceOf(_user));
            console2.log("User avaxMockAssethToken Balance:", MockERC20(avaxMockAssethToken).balanceOf(_user));

            //Set MockEndpoint _fallback mode ON
            MockEndpoint(lzEndpointAddress).toggleFallback(1);

            //GasParams
            GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

            hevm.startPrank(_user);

            // Call Deposit function
            avaxMockAssetToken.approve(address(avaxPort), 100 ether);

            avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(_packedData, depositInput, gasParams, false);

            //Set MockEndpoint _fallback mode OFF
            MockEndpoint(lzEndpointAddress).toggleFallback(0);

            uint32 settlementNonce = multicallBridgeAgent.settlementNonce() - 1;

            Settlement memory settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

            console2.log("Status after fallback:", settlement.status == STATUS_FAILED ? "Failed" : "Success");

            require(settlement.status == STATUS_SUCCESS, "Settlement status should be success.");

            // Get some gas.
            hevm.deal(_user, 1 ether);

            //Retry Settlement
            rootMulticallRouter.retrySettlement{value: 1 ether}(
                settlementNonce, address(_user), "", GasParams(0.5 ether, 0.5 ether), true
            );

            hevm.stopPrank();

            settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

            require(settlement.status == STATUS_SUCCESS, "Settlement status should be success.");

            require(avaxMulticallBridgeAgent.executionState(settlementNonce) == 1, "Settelement Executed in branch");
        }

        // Prepare data
        bytes memory packedData;

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Mock Omnichain dApp call
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams = OutputParams(_user, _user, newAvaxAssetGlobalAddress, 150 ether, 0);

            // RLP Encode Calldata Call with no gas to bridge out and we top up.
            bytes memory data = abi.encode(calls, outputParams, avaxChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(_user, 1 ether);

        // Assure there is enough balance for mock action
        hevm.prank(address(rootPort));
        ERC20hToken(newAvaxAssetGlobalAddress).mint(address(multicallBridgeAgent), 150 ether);
        hevm.prank(address(avaxPort));
        ERC20hToken(avaxMockAssethToken).mint(_user, 50 ether);

        hevm.startPrank(address(multicallBridgeAgent));
        ERC20hToken(newAvaxAssetGlobalAddress).approve(address(rootPort), 50 ether);
        rootPort.bridgeToBranch(
            address(multicallBridgeAgent), newAvaxAssetGlobalAddress, 150 ether, 100 ether, avaxChainId
        );
        hevm.stopPrank();

        // Mint Underlying Token.
        avaxMockAssetToken.mint(_user, 100 ether);

        // Prepare deposit info
        DepositInput memory _depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 150 ether,
            deposit: 100 ether
        });

        console2.log("BALANCE BEFORE:");
        console2.log("User avaxMockAssetToken Balance:", MockERC20(avaxMockAssetToken).balanceOf(_user));
        console2.log("User avaxMockAssethToken Balance:", MockERC20(avaxMockAssethToken).balanceOf(_user));

        //Set MockEndpoint _fallback mode ON
        MockEndpoint(lzEndpointAddress).toggleFallback(1);

        //GasParams
        GasParams memory _gasParams = GasParams(0.5 ether, 0.5 ether);

        hevm.startPrank(_user);

        // Call Deposit function
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(packedData, _depositInput, _gasParams, false);

        //Set MockEndpoint _fallback mode OFF
        MockEndpoint(lzEndpointAddress).toggleFallback(0);

        uint32 _settlementNonce = multicallBridgeAgent.settlementNonce() - 1;

        Settlement memory _settlement = multicallBridgeAgent.getSettlementEntry(_settlementNonce);

        console2.log("Status after fallback:", _settlement.status == STATUS_FAILED ? "Failed" : "Success");

        require(_settlement.status == STATUS_SUCCESS, "Settlement status should be success.");

        // Get some gas.
        hevm.deal(_user, 1 ether);

        //Retry Settlement
        rootMulticallRouter.retrySettlement{value: 1 ether}(
            _settlementNonce, address(_user), "", GasParams(0.5 ether, 0.5 ether), true
        );

        hevm.stopPrank();

        _settlement = multicallBridgeAgent.getSettlementEntry(_settlementNonce);

        require(_settlement.status == STATUS_SUCCESS, "_settlement status should be success.");

        require(avaxMulticallBridgeAgent.executionState(_settlementNonce) == 1, "Settelement Executed in branch");
    }

    function testRedeemSettlement() public {
        // Set up
        testAddLocalTokenArbitrum();

        // Prepare data
        bytes memory packedData;

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Mock Omnichain dApp call
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams =
                OutputParams(address(this), address(this), newAvaxAssetGlobalAddress, 150 ether, 0);

            // RLP Encode Calldata Call with no gas to bridge out and we top up.
            bytes memory data = abi.encode(calls, outputParams, avaxChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        address _user = address(this);

        // Get some gas.
        hevm.deal(_user, 1 ether);

        // Assure there is enough balance for mock action
        hevm.prank(address(rootPort));
        ERC20hToken(newAvaxAssetGlobalAddress).mint(address(multicallBridgeAgent), 150 ether);
        hevm.prank(address(avaxPort));
        ERC20hToken(avaxMockAssethToken).mint(_user, 50 ether);

        hevm.startPrank(address(multicallBridgeAgent));
        ERC20hToken(newAvaxAssetGlobalAddress).approve(address(rootPort), 50 ether);
        rootPort.bridgeToBranch(
            address(multicallBridgeAgent), newAvaxAssetGlobalAddress, 150 ether, 100 ether, avaxChainId
        );
        hevm.stopPrank();

        // Mint Underlying Token.
        avaxMockAssetToken.mint(_user, 100 ether);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 150 ether,
            deposit: 100 ether
        });

        console2.log("BALANCE BEFORE:");
        console2.log("User avaxMockAssetToken Balance:", MockERC20(avaxMockAssetToken).balanceOf(_user));
        console2.log("User avaxMockAssethToken Balance:", MockERC20(avaxMockAssethToken).balanceOf(_user));

        //Set MockEndpoint _fallback mode ON
        MockEndpoint(lzEndpointAddress).toggleFallback(1);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        // Call Deposit function
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(packedData, depositInput, gasParams, true);

        //Set MockEndpoint _fallback mode OFF
        MockEndpoint(lzEndpointAddress).toggleFallback(0);

        //Perform _fallback transaction back to root bridge agent
        MockEndpoint(lzEndpointAddress).sendFallback();

        uint32 settlementNonce = multicallBridgeAgent.settlementNonce() - 1;

        Settlement memory settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

        console2.log("Status after fallback:", settlement.status == STATUS_FAILED ? "Failed" : "Success");

        require(settlement.status == STATUS_FAILED, "Settlement status should be failed.");

        // Retry Settlement
        multicallBridgeAgent.redeemSettlement(settlementNonce, address(this));

        settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

        require(settlement.owner == address(0), "Settlement should cease to exist.");

        require(
            MockERC20(newAvaxAssetGlobalAddress).balanceOf(_user) == 150 ether, "Settlement should have been redeemed"
        );
    }

    function testRedeemTwoSettlements() public {
        // Set up
        testAddLocalTokenArbitrum();

        // Prepare data
        bytes memory packedData;
        address _user = address(this);

        {
            {
                Multicall2.Call[] memory calls = new Multicall2.Call[](1);

                // Mock Omnichain dApp call
                calls[0] = Multicall2.Call({
                    target: newAvaxAssetGlobalAddress,
                    callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
                });

                // Output Params
                OutputParams memory outputParams =
                    OutputParams(address(this), address(this), newAvaxAssetGlobalAddress, 150 ether, 0);

                // RLP Encode Calldata Call with no gas to bridge out and we top up.
                bytes memory data = abi.encode(calls, outputParams, avaxChainId);

                // Pack FuncId
                packedData = abi.encodePacked(bytes1(0x02), data);
            }

            // Get some gas.
            hevm.deal(_user, 1 ether);

            // Assure there is enough balance for mock action
            hevm.prank(address(rootPort));
            ERC20hToken(newAvaxAssetGlobalAddress).mint(address(multicallBridgeAgent), 150 ether);
            hevm.prank(address(avaxPort));
            ERC20hToken(avaxMockAssethToken).mint(_user, 50 ether);

            hevm.startPrank(address(multicallBridgeAgent));
            ERC20hToken(newAvaxAssetGlobalAddress).approve(address(rootPort), 50 ether);
            rootPort.bridgeToBranch(
                address(multicallBridgeAgent), newAvaxAssetGlobalAddress, 150 ether, 100 ether, avaxChainId
            );
            hevm.stopPrank();

            // Mint Underlying Token.
            avaxMockAssetToken.mint(_user, 100 ether);

            // Prepare deposit info
            DepositInput memory depositInput = DepositInput({
                hToken: address(avaxMockAssethToken),
                token: address(avaxMockAssetToken),
                amount: 150 ether,
                deposit: 100 ether
            });

            console2.log("BALANCE BEFORE:");
            console2.log("User avaxMockAssetToken Balance:", MockERC20(avaxMockAssetToken).balanceOf(_user));
            console2.log("User avaxMockAssethToken Balance:", MockERC20(avaxMockAssethToken).balanceOf(_user));

            //Set MockEndpoint _fallback mode ON
            MockEndpoint(lzEndpointAddress).toggleFallback(1);

            //GasParams
            GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

            // Call Deposit function
            avaxMockAssetToken.approve(address(avaxPort), 100 ether);

            avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(packedData, depositInput, gasParams, true);

            //Set MockEndpoint _fallback mode OFF
            MockEndpoint(lzEndpointAddress).toggleFallback(0);

            //Perform _fallback transaction back to root bridge agent
            MockEndpoint(lzEndpointAddress).sendFallback();

            uint32 settlementNonce = multicallBridgeAgent.settlementNonce() - 1;

            Settlement memory settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

            console2.log("Status after fallback:", settlement.status == STATUS_FAILED ? "Failed" : "Success");

            require(settlement.status == STATUS_FAILED, "Settlement status should be failed.");

            // Retry Settlement
            multicallBridgeAgent.redeemSettlement(settlementNonce, _user);

            settlement = multicallBridgeAgent.getSettlementEntry(settlementNonce);

            require(settlement.owner == address(0), "Settlement should cease to exist.");

            require(
                MockERC20(newAvaxAssetGlobalAddress).balanceOf(_user) == 150 ether,
                "Settlement should have been redeemed"
            );
        }

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Mock Omnichain dApp call
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams =
                OutputParams(address(this), address(this), newAvaxAssetGlobalAddress, 150 ether, 0);

            // RLP Encode Calldata Call with no gas to bridge out and we top up.
            bytes memory data = abi.encode(calls, outputParams, avaxChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(_user, 1 ether);

        // Assure there is enough balance for mock action
        hevm.prank(address(rootPort));
        ERC20hToken(newAvaxAssetGlobalAddress).mint(address(multicallBridgeAgent), 150 ether);
        hevm.prank(address(avaxPort));
        ERC20hToken(avaxMockAssethToken).mint(_user, 50 ether);

        hevm.startPrank(address(multicallBridgeAgent));
        ERC20hToken(newAvaxAssetGlobalAddress).approve(address(rootPort), 50 ether);
        rootPort.bridgeToBranch(
            address(multicallBridgeAgent), newAvaxAssetGlobalAddress, 150 ether, 100 ether, avaxChainId
        );
        hevm.stopPrank();

        // Mint Underlying Token.
        avaxMockAssetToken.mint(_user, 100 ether);

        // Prepare deposit info
        DepositInput memory _depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 150 ether,
            deposit: 100 ether
        });

        console2.log("BALANCE BEFORE:");
        console2.log("User avaxMockAssetToken Balance:", MockERC20(avaxMockAssetToken).balanceOf(_user));
        console2.log("User avaxMockAssethToken Balance:", MockERC20(avaxMockAssethToken).balanceOf(_user));

        //Set MockEndpoint _fallback mode ON
        MockEndpoint(lzEndpointAddress).toggleFallback(1);

        //GasParams
        GasParams memory _gasParams = GasParams(0.5 ether, 0.5 ether);

        // Call Deposit function
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(packedData, _depositInput, _gasParams, true);

        //Set MockEndpoint _fallback mode OFF
        MockEndpoint(lzEndpointAddress).toggleFallback(0);

        //Perform _fallback transaction back to root bridge agent
        MockEndpoint(lzEndpointAddress).sendFallback();

        uint32 _settlementNonce = multicallBridgeAgent.settlementNonce() - 1;

        Settlement memory _settlement = multicallBridgeAgent.getSettlementEntry(_settlementNonce);

        console2.log("Status after fallback:", _settlement.status == STATUS_FAILED ? "Failed" : "Success");

        require(_settlement.status == STATUS_FAILED, "Settlement status should be failed.");

        // Retry Settlement
        multicallBridgeAgent.redeemSettlement(_settlementNonce, _user);

        _settlement = multicallBridgeAgent.getSettlementEntry(_settlementNonce);

        require(_settlement.owner == address(0), "Settlement should cease to exist.");

        require(
            MockERC20(newAvaxAssetGlobalAddress).balanceOf(_user) == 300 ether, "Settlement should have been redeemed"
        );
    }

    function testAddChain() public {
        // Number of tokens before
        uint256 tokensLength = hTokenFactory.getHTokens().length;

        // Add new chain
        rootPort.addNewChain(address(0xBABA), 123, "GasToken", "GTKN", 18, address(0xFAFA), address(0xDADA));

        require(rootPort.isChainId(123), "new chain not added");

        require(hTokenFactory.getHTokens().length == tokensLength + 1);
    }

    function testAddChainAlreadyAdded() public {
        hevm.expectRevert(abi.encodeWithSignature("AlreadyAddedChain()"));

        // Add new chain
        rootPort.addNewChain(address(0xBABA), 42161, "GasToken", "GTKN", 18, address(0xFAFA), address(0xDADA));
    }

    //////////////////////////////////////   HELPERS   //////////////////////////////////////

    function testCreateDepositSingle(
        ArbitrumBranchBridgeAgent _bridgeAgent,
        uint32 _depositNonce,
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit,
        GasParams memory
    ) private view {
        // Cast to Dynamic
        address[] memory hTokens = new address[](1);
        hTokens[0] = _hToken;
        address[] memory tokens = new address[](1);
        tokens[0] = _token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        uint256[] memory deposits = new uint256[](1);
        deposits[0] = _deposit;

        // Get Deposit
        Deposit memory deposit = _bridgeAgent.getDepositEntry(_depositNonce);

        console2.log(deposit.hTokens[0], hTokens[0]);
        console2.log(deposit.tokens[0], tokens[0]);
        console2.log("owner", deposit.owner);
        console2.log("user", _user);

        // Check deposit
        require(deposit.owner == _user, "Deposit owner doesn't match");

        require(
            keccak256(abi.encodePacked(deposit.hTokens)) == keccak256(abi.encodePacked(hTokens)),
            "Deposit local hToken doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.tokens)) == keccak256(abi.encodePacked(tokens)),
            "Deposit underlying token doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.amounts)) == keccak256(abi.encodePacked(amounts)),
            "Deposit amount doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.deposits)) == keccak256(abi.encodePacked(deposits)),
            "Deposit deposit doesn't match"
        );

        require(deposit.status == 0, "Deposit status should be succesful.");
    }
}

contract MockEndpoint is DSTestPlus {
    uint256 constant rootChain = 42161;

    address public sourceBridgeAgent;
    address public destinationBridgeAgent;
    bytes public data;
    uint32 public nonce;
    bool forceFallback;
    uint256 fallbackCountdown;
    uint256 gasLimit;
    uint256 remoteBranchExecutionGas;
    address receiver;

    constructor() {}

    function toggleFallback(uint256 _fallbackCountdown) external {
        forceFallback = !forceFallback;
        fallbackCountdown = _fallbackCountdown;
    }

    function sendFallback() public {
        console2.log("Mocking fallback...");
        console2.log("sourceBridgeAgent:", sourceBridgeAgent);
        console2.log("destinationBridgeAgent:", destinationBridgeAgent);
        console2.log("srcChainId:", BranchBridgeAgent(payable(sourceBridgeAgent)).localChainId());

        hevm.deal(address(this), (gasLimit + remoteBranchExecutionGas) * tx.gasprice);

        bytes memory fallbackData = abi.encodePacked(
            BranchBridgeAgent(payable(sourceBridgeAgent)).localChainId() == rootChain ? 0x09 : 0x04, nonce
        );

        // Perform Call
        RootBridgeAgent(payable(sourceBridgeAgent)).lzReceive{gas: 200_000}(
            BranchBridgeAgent(payable(destinationBridgeAgent)).localChainId(),
            abi.encodePacked(destinationBridgeAgent, sourceBridgeAgent),
            1,
            fallbackData
        );
    }
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination

    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable,
        address,
        bytes calldata _adapterParams
    ) external payable {
        sourceBridgeAgent = msg.sender;
        destinationBridgeAgent = address(bytes20(_destination[:20]));
        bytes memory path = abi.encodePacked(msg.sender, destinationBridgeAgent);
        data = _payload;

        nonce = _dstChainId == uint16(42161)
            ? BranchBridgeAgent(payable(msg.sender)).depositNonce() - 1
            : RootBridgeAgent(payable(msg.sender)).settlementNonce() - 1;

        console2.log("Mocking lzSends...");
        console2.log("sourceBridgeAgent:", msg.sender);
        console2.log("destinationBridgeAgent:", destinationBridgeAgent);
        console2.log("srcChainId:", BranchBridgeAgent(payable(msg.sender)).localChainId());

        // Decode adapter params
        if (_adapterParams.length > 0) {
            gasLimit = uint256(bytes32(_adapterParams[2:34]));
            remoteBranchExecutionGas = uint256(bytes32(_adapterParams[34:66]));
            receiver = address(bytes20(_adapterParams[66:86]));
        } else {
            gasLimit = 200_000;
            remoteBranchExecutionGas = 0;
            receiver = address(0);
        }

        if (!forceFallback) {
            // Perform Call
            destinationBridgeAgent.call{value: remoteBranchExecutionGas}("");
            RootBridgeAgent(payable(destinationBridgeAgent)).lzReceive{gas: gasLimit}(
                BranchBridgeAgent(payable(msg.sender)).localChainId(), path, 1, data
            );
        } else if (fallbackCountdown > 0) {
            console2.log("Execute LayerZero request...", fallbackCountdown--);
            // Perform Call
            destinationBridgeAgent.call{value: remoteBranchExecutionGas}("");
            RootBridgeAgent(payable(destinationBridgeAgent)).lzReceive{gas: gasLimit}(
                BranchBridgeAgent(payable(msg.sender)).localChainId(), path, 1, data
            );
        }
    }
}
