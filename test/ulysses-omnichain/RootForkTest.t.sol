//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/RootForkHelper.t.sol";

pragma solidity ^0.8.0;

contract RootForkTest is LzForkTest {
    using BaseBranchRouterHelper for BaseBranchRouter;
    using CoreRootRouterHelper for CoreRootRouter;
    using MulticallRootRouterHelper for MulticallRootRouter;
    using RootBridgeAgentHelper for RootBridgeAgent;
    using RootBridgeAgentFactoryHelper for RootBridgeAgentFactory;
    using RootPortHelper for RootPort;

    // Consts

    //Arb
    uint16 constant rootChainId = uint16(110);

    //Avax
    uint16 constant avaxChainId = uint16(106);

    //Ftm
    uint16 constant ftmChainId = uint16(112);

    //// System contracts

    // Root

    RootPort rootPort;

    ERC20hTokenRootFactory hTokenRootFactory;

    RootBridgeAgentFactory rootBridgeAgentFactory;

    RootBridgeAgent coreRootBridgeAgent;

    RootBridgeAgent multicallRootBridgeAgent;

    CoreRootRouter coreRootRouter;

    MulticallRootRouter rootMulticallRouter;

    // Arbitrum Branch

    ArbitrumBranchPort arbitrumPort;

    ArbitrumBranchBridgeAgentFactory arbitrumBranchBridgeAgentFactory;

    ArbitrumBranchBridgeAgent arbitrumCoreBranchBridgeAgent;

    ArbitrumBranchBridgeAgent arbitrumMulticallBranchBridgeAgent;

    ArbitrumCoreBranchRouter arbitrumCoreBranchRouter;

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

    address avaxWrappedNativeToken;
    address ftmWrappedNativeToken;

    address avaxLocalWrappedNativeToken;
    address ftmLocalWrappedNativeToken;

    address multicallAddress;

    address nonFungiblePositionManagerAddress = address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address lzEndpointAddress = address(0x3c2269811836af69497E5F486A85D7316753cf62);
    address lzEndpointAddressAvax = address(0x3c2269811836af69497E5F486A85D7316753cf62);
    address lzEndpointAddressFtm = address(0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7);

    address owner = address(this);

    address dao = address(this);

    // For specific tests

    address public newAvaxAssetGlobalAddress;

    address public newFtmAssetGlobalAddress;

    address public newAvaxAssetFtmLocalToken;

    address public mockApp = address(0xDAFA);

    address public newArbitrumAssetGlobalAddress;

    function setUp() public override {
        /////////////////////////////////
        //         Fork Setup          //
        /////////////////////////////////

        // Set up default fork chains
        setUpDefaultLzChains();

        /////////////////////////////////
        //      Deploy Root Utils      //
        /////////////////////////////////
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        multicallAddress = address(new Multicall2());

        /////////////////////////////////
        //    Deploy Root Contracts    //
        /////////////////////////////////

        _deployRoot();

        /////////////////////////////////
        //  Initialize Root Contracts  //
        /////////////////////////////////

        _initRoot();

        /////////////////////////////////
        //Deploy Local Branch Contracts//
        /////////////////////////////////

        _deployLocalBranch();

        //////////////////////////////////
        // Deploy Avax Branch Contracts //
        //////////////////////////////////

        _deployAvaxBranch();

        //////////////////////////////////
        // Deploy Ftm Branch Contracts //
        //////////////////////////////////

        _deployFtmBranch();

        /////////////////////////////
        //  Add new branch chains  //
        /////////////////////////////

        _addNewBranchChainsToRoot();

        ///////////////////////////////////
        //  Approve new Branches in Root  //
        ///////////////////////////////////

        _approveNewBranchesInRoot();

        ///////////////////////////////////////
        //  Add new branches to  Root Agents //
        ///////////////////////////////////////

        _addNewBranchesToRootAgents();

        /////////////////////////////////////
        //  Initialize new Branch Routers  //
        /////////////////////////////////////

        _initNewBranchRouters();

        //////////////////////////////////////
        //Deploy Underlying Tokens and Mocks//
        //////////////////////////////////////

        _deployUnderlyingTokensAndMocks();
    }

    function _deployRoot() internal {
        (rootPort, rootBridgeAgentFactory, hTokenRootFactory, coreRootRouter, rootMulticallRouter) =
            RootForkHelper._deployRoot(rootChainId, lzEndpointAddress, multicallAddress);
    }

    function _initRoot() internal {
        (coreRootBridgeAgent, multicallRootBridgeAgent) = RootForkHelper._initRoot(
            rootPort, rootBridgeAgentFactory, hTokenRootFactory, coreRootRouter, rootMulticallRouter
        );
    }

    function _deployLocalBranch() internal {
        (
            arbitrumPort,
            arbitrumMulticallRouter,
            arbitrumCoreBranchRouter,
            arbitrumBranchBridgeAgentFactory,
            arbitrumCoreBranchBridgeAgent
        ) = RootForkHelper._deployLocalBranch(rootChainId, rootPort, owner, rootBridgeAgentFactory, coreRootBridgeAgent);
    }

    function _deployAvaxBranch() internal {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        (
            avaxPort,
            avaxHTokenFactory,
            avaxCoreRouter,
            avaxWrappedNativeToken,
            avaxBranchBridgeAgentFactory,
            avaxMulticallRouter
        ) = RootForkHelper._deployBranch(
            "Avalanche Ulysses ",
            "avax-u",
            rootChainId,
            avaxChainId,
            owner,
            rootBridgeAgentFactory,
            lzEndpointAddressAvax
        );

        (avaxCoreBridgeAgent, avaxLocalWrappedNativeToken) = RootForkHelper._initBranch(
            coreRootBridgeAgent,
            avaxWrappedNativeToken,
            avaxPort,
            avaxHTokenFactory,
            avaxCoreRouter,
            avaxBranchBridgeAgentFactory
        );
    }

    function _deployFtmBranch() internal {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        (
            ftmPort,
            ftmHTokenFactory,
            ftmCoreRouter,
            ftmWrappedNativeToken,
            ftmBranchBridgeAgentFactory,
            ftmMulticallRouter
        ) = RootForkHelper._deployBranch(
            "Fantom Ulysses ", "ftm-u", rootChainId, ftmChainId, owner, rootBridgeAgentFactory, lzEndpointAddressFtm
        );

        (ftmCoreBridgeAgent, ftmLocalWrappedNativeToken) = RootForkHelper._initBranch(
            coreRootBridgeAgent,
            ftmWrappedNativeToken,
            ftmPort,
            ftmHTokenFactory,
            ftmCoreRouter,
            ftmBranchBridgeAgentFactory
        );
    }

    function _addNewBranchChainsToRoot() internal {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        avaxGlobalToken = RootForkHelper._addNewBranchChainToRoot(
            rootPort,
            avaxCoreBridgeAgent,
            avaxChainId,
            "Avalanche",
            "AVAX",
            18,
            avaxLocalWrappedNativeToken,
            avaxWrappedNativeToken,
            hTokenRootFactory
        );

        ftmGlobalToken = RootForkHelper._addNewBranchChainToRoot(
            rootPort,
            ftmCoreBridgeAgent,
            ftmChainId,
            "Fantom Opera",
            "FTM",
            18,
            ftmLocalWrappedNativeToken,
            ftmWrappedNativeToken,
            hTokenRootFactory
        );
    }

    function _approveNewBranchesInRoot() internal {
        rootPort._initCore(coreRootBridgeAgent, arbitrumCoreBranchBridgeAgent, arbitrumPort);

        multicallRootBridgeAgent._approveBranchBridgeAgent(rootChainId);

        multicallRootBridgeAgent._approveBranchBridgeAgent(avaxChainId);

        multicallRootBridgeAgent._approveBranchBridgeAgent(ftmChainId);
    }

    function _addNewBranchesToRootAgents() internal {
        // Start the recorder necessary for packet tracking
        vm.recordLogs();

        vm.deal(address(this), 100 ether);

        coreRootRouter._addBranchToBridgeAgent(
            multicallRootBridgeAgent,
            avaxBranchBridgeAgentFactory,
            avaxMulticallRouter,
            address(this),
            avaxChainId,
            [GasParams(6_000_000, 10 ether), GasParams(1_000_000, 0)],
            10 ether
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        vm.deal(address(this), 100 ether);

        coreRootRouter._addBranchToBridgeAgent(
            multicallRootBridgeAgent,
            ftmBranchBridgeAgentFactory,
            ftmMulticallRouter,
            address(this),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)],
            10 ether
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        coreRootRouter._addBranchToBridgeAgent(
            multicallRootBridgeAgent,
            arbitrumBranchBridgeAgentFactory,
            arbitrumMulticallRouter,
            address(this),
            rootChainId,
            [GasParams(0, 0), GasParams(0, 0)],
            0
        );
    }

    function _initNewBranchRouters() internal {
        arbitrumMulticallBranchBridgeAgent = ArbitrumBranchBridgeAgent(payable(arbitrumPort.bridgeAgents(1)));
        arbitrumMulticallRouter._init(arbitrumMulticallBranchBridgeAgent, arbitrumPort);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        avaxMulticallBridgeAgent = BranchBridgeAgent(payable(avaxPort.bridgeAgents(1)));
        avaxMulticallRouter._init(avaxMulticallBridgeAgent, avaxPort);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        ftmMulticallBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(1)));
        ftmMulticallRouter._init(ftmMulticallBridgeAgent, ftmPort);
    }

    function _deployUnderlyingTokensAndMocks() internal {
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        // avaxMockAssethToken = new MockERC20("hTOKEN-AVAX", "LOCAL hTOKEN FOR TOKEN IN AVAX", 18);
        avaxMockAssetToken = new MockERC20("underlying token", "UNDER", 18);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        // ftmMockAssethToken = new MockERC20("hTOKEN-FTM", "LOCAL hTOKEN FOR TOKEN IN FMT", 18);
        ftmMockAssetToken = new MockERC20("underlying token", "UNDER", 18);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        //arbitrumMockAssethToken is global
        arbitrumMockToken = new MockERC20("underlying token", "UNDER", 18);
    }

    fallback() external payable {}

    receive() external payable {}

    //////////////////////////////////////
    //           Bridge Agents          //
    //////////////////////////////////////

    function testAddBridgeAgentSimple() public {
        //Get some gas
        vm.deal(address(this), 2 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Create Branch Router in FTM
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        BaseBranchRouter ftmTestRouter;
        ftmTestRouter = ftmTestRouter._deploy();
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        //Allow new branch from root
        testRootBridgeAgent._approveBranchBridgeAgent(ftmChainId);

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            ftmBranchBridgeAgentFactory,
            BaseBranchRouter(address(testMulticallRouter)),
            address(this),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)],
            2 ether
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        BranchBridgeAgent ftmTestBranchBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(2)));

        ftmTestRouter.initialize(address(ftmTestBranchBridgeAgent));

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(testRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == address(ftmTestBranchBridgeAgent));
    }

    function testAddBridgeAgentArbitrum() public {
        //Get some gas
        vm.deal(address(this), 2 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Create Branch Router in FTM
        BaseBranchRouter arbTestRouter = new ArbitrumBaseBranchRouter();

        //Allow new branch from root
        testRootBridgeAgent._approveBranchBridgeAgent(rootChainId);

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            arbitrumBranchBridgeAgentFactory,
            BaseBranchRouter(address(testMulticallRouter)),
            address(this),
            rootChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)],
            2 ether
        );

        BranchBridgeAgent arbTestBranchBridgeAgent = BranchBridgeAgent(payable(arbitrumPort.bridgeAgents(2)));

        arbTestRouter._init(arbTestBranchBridgeAgent, arbitrumPort);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(testRootBridgeAgent.getBranchBridgeAgent(rootChainId) == address(arbTestBranchBridgeAgent));
    }

    function testAddBridgeAgentAlreadyAdded() public {
        testAddBridgeAgentSimple();

        //Get some gas
        vm.deal(address(this), 1 ether);

        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(payable(rootPort.bridgeAgents(2)));

        vm.expectRevert(abi.encodeWithSignature("AlreadyAddedBridgeAgent()"));

        //Allow new branch
        testRootBridgeAgent._approveBranchBridgeAgent(ftmChainId);
    }

    function testAddBridgeAgentTwoTimes() public {
        testAddBridgeAgentSimple();

        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(payable(rootPort.bridgeAgents(2)));

        vm.expectRevert(abi.encodeWithSignature("InvalidChainId()"));

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            ftmBranchBridgeAgentFactory,
            BaseBranchRouter(address(testMulticallRouter)),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)],
            0.05 ether
        );
    }

    function testAddBridgeAgentNotApproved() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        vm.expectRevert(abi.encodeWithSignature("UnauthorizedChainId()"));

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            ftmBranchBridgeAgentFactory,
            BaseBranchRouter(address(testMulticallRouter)),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)],
            0.05 ether
        );
    }

    function testAddBridgeAgentNotManager() public {
        //Get some gas
        vm.deal(address(89), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        vm.startPrank(address(89));

        vm.expectRevert(abi.encodeWithSignature("UnauthorizedCallerNotManager()"));
        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            ftmBranchBridgeAgentFactory,
            BaseBranchRouter(address(testMulticallRouter)),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)],
            0.05 ether
        );
    }

    address newFtmBranchBridgeAgent;

    function testAddBridgeAgentNewFactory() public {
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            newRootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Allow new branch
        testRootBridgeAgent._approveBranchBridgeAgent(ftmChainId);

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            newFtmBranchBridgeAgentFactory,
            BaseBranchRouter(address(testMulticallRouter)),
            address(this),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)],
            1 ether
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        newFtmBranchBridgeAgent = ftmPort.bridgeAgents(2);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(
            testRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == newFtmBranchBridgeAgent,
            "Branch Bridge Agent should be created"
        );
    }

    function testAddBridgeAgentWrongBranchFactory() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Allow new branch
        testRootBridgeAgent._approveBranchBridgeAgent(ftmChainId);

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            BranchBridgeAgentFactory(address(32)),
            BaseBranchRouter(address(testMulticallRouter)),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)],
            0.05 ether
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(
            RootBridgeAgent(testRootBridgeAgent).getBranchBridgeAgent(ftmChainId) == address(0),
            "Branch Bridge Agent should not be created"
        );
    }

    function testAddBridgeAgentWrongRootFactory() public {
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Allow new branch
        testRootBridgeAgent._approveBranchBridgeAgent(ftmChainId);

        // Get wrong factory
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        address branchBridgeAgentFactory = address(newFtmBranchBridgeAgentFactory);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        //Create Branch Bridge Agent
        coreRootRouter._addBranchToBridgeAgent(
            testRootBridgeAgent,
            BranchBridgeAgentFactory(branchBridgeAgentFactory),
            BaseBranchRouter(address(testMulticallRouter)),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)],
            1 ether
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(
            RootBridgeAgent(testRootBridgeAgent).getBranchBridgeAgent(ftmChainId) == address(0),
            "Branch Bridge Agent should not be created"
        );
    }

    CoreRootRouter newCoreRootRouter;
    RootBridgeAgent newCoreRootBridgeAgent;
    ERC20hTokenRootFactory newHTokenRootFactory;

    CoreBranchRouter newFtmCoreBranchRouter;
    BranchBridgeAgent newFtmCoreBranchBridgeAgent;
    ERC20hTokenBranchFactory newFtmHTokenFactory;

    function testSetBranchRouter() public {
        switchToLzChain(rootChainId);

        vm.deal(address(this), 1000 ether);

        // Deploy new root core

        newHTokenRootFactory = new ERC20hTokenRootFactory(address(rootPort));

        newCoreRootRouter = new CoreRootRouter(rootChainId, address(rootPort));

        newCoreRootBridgeAgent =
            RootBridgeAgent(payable(rootBridgeAgentFactory.createBridgeAgent(address(newCoreRootRouter))));

        // Init new root core

        newCoreRootRouter.initialize(address(newCoreRootBridgeAgent), address(newHTokenRootFactory));

        newHTokenRootFactory.initialize(address(newCoreRootRouter));

        switchToLzChain(ftmChainId);

        // Deploy new Branch Core

        newFtmHTokenFactory = new ERC20hTokenBranchFactory(address(ftmPort), "Fantom", "FTM");

        newFtmCoreBranchRouter = new CoreBranchRouter(address(newFtmHTokenFactory));

        newFtmCoreBranchBridgeAgent = new BranchBridgeAgent(rootChainId,
        ftmChainId,
        address(newCoreRootBridgeAgent),
        lzEndpointAddressFtm,
        address(newFtmCoreBranchRouter),
        address(ftmPort));

        // Init new branch core

        newFtmCoreBranchRouter.initialize(address(newFtmCoreBranchBridgeAgent));

        newFtmHTokenFactory.initialize(address(ftmWrappedNativeToken), address(newFtmCoreBranchRouter));

        switchToLzChain(rootChainId);

        rootPort.setCoreBranchRouter{value: 1000 ether}(
            address(this),
            address(newFtmCoreBranchRouter),
            address(newFtmCoreBranchBridgeAgent),
            ftmChainId,
            GasParams(200_000, 0)
        );

        switchToLzChain(ftmChainId);

        require(ftmPort.coreBranchRouterAddress() == address(newFtmCoreBranchRouter));
        require(ftmPort.isBridgeAgent(address(newFtmCoreBranchBridgeAgent)));

        ftmCoreRouter = newFtmCoreBranchRouter;
        ftmCoreBridgeAgent = newFtmCoreBranchBridgeAgent;
    }

    function testSetCoreRootRouter() public {
        testSetBranchRouter();

        // @dev Once all branches have been migrated we are ready to set the new root router

        switchToLzChain(rootChainId);

        // newCoreRootRouter = new CoreRootRouter(rootChainId, address(rootPort));

        // newCoreRootBridgeAgent =
        //     RootBridgeAgent(payable(rootBridgeAgentFactory.createBridgeAgent(address(newCoreRootRouter))));

        rootPort.setCoreRootRouter(address(newCoreRootRouter), address(newCoreRootBridgeAgent));

        require(rootPort.coreRootRouterAddress() == address(newCoreRootRouter));
        require(rootPort.coreRootBridgeAgentAddress() == address(newCoreRootBridgeAgent));

        coreRootRouter = newCoreRootRouter;
        coreRootBridgeAgent = newCoreRootBridgeAgent;
    }

    function testSyncNewCoreBranchRouter() public {
        testSetCoreRootRouter();

        // @dev after setting the new root core we can sync each new branch one by one

        rootPort.syncNewCoreBranchRouter(
            address(newFtmCoreBranchRouter), address(newFtmCoreBranchBridgeAgent), ftmChainId
        );

        require(newCoreRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == address(newFtmCoreBranchBridgeAgent));
    }

    MockERC20 newFtmMockUnderlyingToken;
    address newFtmMockAssetLocalToken;
    address newFtmMockGlobalToken;

    function testAddLocalTokenNewCore() public {
        testSyncNewCoreBranchRouter();

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        vm.deal(address(this), 10 ether);

        newFtmMockUnderlyingToken = new MockERC20("UnderTester", "UTST", 6);

        ftmCoreRouter.addLocalToken{value: 10 ether}(address(newFtmMockUnderlyingToken), GasParams(2_000_000, 0));

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        newFtmMockAssetLocalToken = rootPort.getLocalTokenFromUnderlying(address(newFtmMockUnderlyingToken), ftmChainId);

        newFtmMockGlobalToken = rootPort.getGlobalTokenFromLocal(newFtmMockAssetLocalToken, ftmChainId);

        require(
            rootPort.getGlobalTokenFromLocal(newFtmMockAssetLocalToken, ftmChainId) == newFtmMockGlobalToken,
            "Token should be added"
        );
        require(
            rootPort.getLocalTokenFromGlobal(newFtmMockGlobalToken, ftmChainId) == newFtmMockAssetLocalToken,
            "Token should be added"
        );
        require(
            rootPort.getUnderlyingTokenFromLocal(newFtmMockAssetLocalToken, ftmChainId)
                == address(newFtmMockUnderlyingToken),
            "Token should be added"
        );
    }

    //////////////////////////////////////
    //        Bridge Agent Factory     //
    //////////////////////////////////////

    RootBridgeAgentFactory newRootBridgeAgentFactory;

    BranchBridgeAgentFactory newFtmBranchBridgeAgentFactory;

    function testAddBridgeAgentFactory() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        // Add new Root Bridge Agent Factory
        newRootBridgeAgentFactory = newRootBridgeAgentFactory._deploy(rootChainId, lzEndpointAddress, rootPort);

        // Enable new Factory in Root
        rootPort.toggleBridgeAgentFactory(address(newRootBridgeAgentFactory));

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        // Add new Branch Bridge Agent Factory
        newFtmBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(newRootBridgeAgentFactory),
            lzEndpointAddressFtm,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        // Enable new Factory in Branch
        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(newRootBridgeAgentFactory),
            address(newFtmBranchBridgeAgentFactory),
            address(this),
            ftmChainId,
            GasParams(200_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Factory not enabled");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testAddBridgeAgentFactoryNotRootFactory() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        // Add new Root Bridge Agent Factory
        newRootBridgeAgentFactory = newRootBridgeAgentFactory._deploy(rootChainId, lzEndpointAddress, rootPort);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        // Add new Branch Bridge Agent Factory
        newFtmBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(newRootBridgeAgentFactory),
            lzEndpointAddressFtm,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        vm.expectRevert(abi.encodeWithSignature("UnrecognizedBridgeAgentFactory()"));

        // Add new Factory to Branch
        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(newRootBridgeAgentFactory),
            address(newFtmBranchBridgeAgentFactory),
            address(this),
            ftmChainId,
            GasParams(200_000, 0)
        );
    }

    RootBridgeAgentFactory newRootBridgeAgentFactory_2;

    BranchBridgeAgentFactory newFtmBranchBridgeAgentFactory_2;

    function testAddTwoBridgeAgentFactories() public {
        // Add first factory
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        // Add new Root Bridge Agent Factory
        newRootBridgeAgentFactory_2 = newRootBridgeAgentFactory_2._deploy(rootChainId, lzEndpointAddress, rootPort);

        // Enable new Factory in Root
        rootPort.toggleBridgeAgentFactory(address(newRootBridgeAgentFactory_2));

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        // Add new Branch Bridge Agent Factory
        newFtmBranchBridgeAgentFactory_2 = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(newRootBridgeAgentFactory_2),
            lzEndpointAddressFtm,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(newRootBridgeAgentFactory_2),
            address(newFtmBranchBridgeAgentFactory_2),
            address(this),
            ftmChainId,
            GasParams(200_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Factory not enabled");
        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory_2)), "Factory not enabled");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testRemoveBridgeAgentFactory() public {
        //Add Factory
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        address factoryToRemove = address(newFtmBranchBridgeAgentFactory);
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(rootBridgeAgentFactory), factoryToRemove, address(this), ftmChainId, GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Should be disabled");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    //////////////////////////////////////
    //           Port Strategies        //
    //////////////////////////////////////
    MockERC20 mockFtmPortToken;

    function testAddStrategyToken() public {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        mockFtmPortToken = new MockERC20("Token of the Port", "PORT TKN", 18);
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        //Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.toggleStrategyToken{value: 1 ether}(
            address(mockFtmPortToken), 7000, address(this), ftmChainId, GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isStrategyToken(address(mockFtmPortToken)), "Should be added");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testAddStrategyTokenInvalidMinReserve() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        // vm.expectRevert(abi.encodeWithSignature("InvalidMinimumReservesRatio()"));
        coreRootRouter.toggleStrategyToken{value: 1 ether}(
            address(mockFtmPortToken), 300, address(this), ftmChainId, GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isStrategyToken(address(mockFtmPortToken)), "Should note be added");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testRemoveStrategyToken() public {
        //Add Token
        testAddStrategyToken();

        //Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.toggleStrategyToken{value: 1 ether}(
            address(mockFtmPortToken), 0, address(this), ftmChainId, GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isStrategyToken(address(mockFtmPortToken)), "Should be removed");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    address mockFtmPortStrategyAddress;

    function testAddPortStrategy() public {
        // Add strategy token
        testAddStrategyToken();

        // Deploy Mock Strategy
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        mockFtmPortStrategyAddress = address(new MockPortStartegy());
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        // Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.togglePortStrategy{value: 1 ether}(
            mockFtmPortStrategyAddress,
            address(mockFtmPortToken),
            250 ether,
            7000,
            address(this),
            ftmChainId,
            GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isPortStrategy(mockFtmPortStrategyAddress, address(mockFtmPortToken)), "Should be added");

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testAddPortStrategyLowerRatio() public {
        // Add strategy token
        testAddStrategyToken();

        // Deploy Mock Strategy
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        mockFtmPortStrategyAddress = address(new MockPortStartegy());
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        // Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.togglePortStrategy{value: 1 ether}(
            mockFtmPortStrategyAddress,
            address(mockFtmPortToken),
            250 ether,
            8000,
            address(this),
            ftmChainId,
            GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isPortStrategy(mockFtmPortStrategyAddress, address(mockFtmPortToken)), "Should be added");

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testAddPortStrategyNotToken() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        //UnrecognizedStrategyToken();
        coreRootRouter.togglePortStrategy{value: 1 ether}(
            mockFtmPortStrategyAddress,
            address(mockFtmPortToken),
            300,
            7000,
            address(this),
            ftmChainId,
            GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isPortStrategy(mockFtmPortStrategyAddress, address(mockFtmPortToken)), "Should not be added");

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testManage() public {
        // Add Strategy token and Port strategy
        testAddPortStrategy();

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 250 ether);

        // Veriy if assets have been transfered
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore - 250 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore + 250 ether,
            "Should be transfered"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should be 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should be 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitRemaining(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod out"
        );
    }

    function testManageTwoDayLimits() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Warp 1 day
        vm.warp(block.timestamp + 1 days);

        // Add token balance to port (new deposits)
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 250 ether);

        // Veriy if assets have been transfered
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore - 250 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore + 250 ether,
            "Should be transfered"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 500 ether,
            "Should be 500 ether"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should be 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitRemaining(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod out"
        );
    }

    function testManageExceedsMinimumReserves() public {
        // Add Strategy token and Port strategy
        testAddPortStrategy();

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Prank into strategy
        vm.startPrank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert(abi.encodeWithSignature("InsufficientReserves()"));

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 400 ether);
    }

    function testManageExceedsDailyLimit() public {
        // Add Strategy token and Port strategy
        testAddPortStrategy();

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Prank into strategy
        vm.startPrank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert();

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 300 ether);
    }

    function testManageExceedsStrategyDebtLimit() public {
        // Add Strategy token and Port strategy
        testAddPortStrategyLowerRatio();

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 750 ether);

        // Prank into strategy
        vm.startPrank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert();

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 225 ether);
    }

    function testReplenishAsStrategy() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch to brnach
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.replenishReserves(address(mockFtmPortToken), 250 ether);

        // Veriy if assets have been transfered
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore + 250 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore - 250 ether,
            "Should be returned"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should remain 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitRemaining(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod"
        );
    }

    function testReplenishAsUser() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch to brnach
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Fake some port withdrawals
        // vm.prank(address(ftmPort));
        MockERC20(mockFtmPortToken).burn(address(ftmPort), 500 ether);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.replenishReserves(mockFtmPortStrategyAddress, address(mockFtmPortToken));

        // Veriy if assets have been transfered up to the minimum reserves
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore + 100 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore - 100 ether,
            "Should be returned"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 150 ether,
            "Should be decremented"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should remain 250 ether"
        );
    }

    function testReplenishAsStrategyNotEnoughDebtToRepay() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch to brnach
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert();

        // Request management of assets
        ftmPort.replenishReserves(address(mockFtmPortToken), 300 ether);
    }

    //////////////////////////////////////
    //          TOKEN MANAGEMENT        //
    //////////////////////////////////////

    function testAddLocalToken() public {
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        vm.deal(address(this), 10 ether);

        avaxCoreRouter.addLocalToken{value: 10 ether}(address(avaxMockAssetToken), GasParams(2_000_000, 0));

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        avaxMockAssethToken = rootPort.getLocalTokenFromUnderlying(address(avaxMockAssetToken), avaxChainId);

        newAvaxAssetGlobalAddress = rootPort.getGlobalTokenFromLocal(avaxMockAssethToken, avaxChainId);

        require(
            rootPort.getGlobalTokenFromLocal(avaxMockAssethToken, avaxChainId) == newAvaxAssetGlobalAddress,
            "Token should be added"
        );
        require(
            rootPort.getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, avaxChainId) == avaxMockAssethToken,
            "Token should be added"
        );
        require(
            rootPort.getUnderlyingTokenFromLocal(avaxMockAssethToken, avaxChainId) == address(avaxMockAssetToken),
            "Token should be added"
        );
    }

    function testAddGlobalTokenFork() public {
        //Add Local Token from Avax
        testAddLocalToken();

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        vm.deal(address(this), 1000 ether);

        GasParams[3] memory gasParams =
            [GasParams(15_000_000, 0.1 ether), GasParams(2_000_000, 3 ether), GasParams(200_000, 0)];

        avaxCoreRouter.addGlobalToken{value: 1000 ether}(newAvaxAssetGlobalAddress, ftmChainId, gasParams);

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        newAvaxAssetFtmLocalToken = rootPort.getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId);

        require(newAvaxAssetFtmLocalToken != address(0), "Failed is zero");

        require(
            rootPort.getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId) == newAvaxAssetFtmLocalToken,
            "Token should be added"
        );

        require(
            rootPort.getUnderlyingTokenFromLocal(newAvaxAssetFtmLocalToken, ftmChainId) == address(0),
            "Underlying should not be added"
        );
    }

    function testAddLocalTokenArbitrum() public {
        //Set up
        testAddGlobalTokenFork();

        //Get some gas.
        vm.deal(address(this), 1 ether);

        //Add new localToken
        arbitrumCoreBranchRouter.addLocalToken{value: 0.0005 ether}(
            address(arbitrumMockToken), GasParams(0.5 ether, 0.5 ether)
        );

        newArbitrumAssetGlobalAddress = rootPort.getLocalTokenFromUnderlying(address(arbitrumMockToken), rootChainId);

        require(
            rootPort.getGlobalTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            rootPort.getLocalTokenFromGlobal(newArbitrumAssetGlobalAddress, rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            rootPort.getUnderlyingTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(arbitrumMockToken),
            "Token should be added"
        );
    }

    //////////////////////////////////////
    //          TOKEN TRANSFERS         //
    //////////////////////////////////////

    function encodeMulticallNoOutput(Multicall2.Call[] memory callData) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), abi.encode(callData));
    }

    function encodeMulticallSingleOutput(
        Multicall2.Call[] memory callData,
        OutputParams memory outputParams,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x02), abi.encode(callData, outputParams, dstChainId, gasParams));
    }

    function encodeMulticallMultipleOutput(
        Multicall2.Call[] memory callData,
        OutputMultipleParams memory outputMultipleParams,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x03), abi.encode(callData, outputMultipleParams, dstChainId, gasParams));
    }

    function prepareMulticallSingleOutput_singleTransfer(
        address multicallTransferToken,
        address multicallTransferTo,
        uint256 multicallTransferAmount,
        address settlementOwner,
        address recipient,
        address outputToken,
        uint256 amountOut,
        uint256 depositOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal pure returns (bytes memory) {
        Multicall2.Call[] memory calls = new Multicall2.Call[](1);

        //Mock action
        calls[0] = Multicall2.Call({
            target: outputToken,
            callData: abi.encodeWithSelector(bytes4(0xa9059cbb), multicallTransferTo, multicallTransferAmount)
        });

        //Output Params
        OutputParams memory outputParams = OutputParams(settlementOwner, recipient, outputToken, amountOut, depositOut);

        return encodeMulticallSingleOutput(calls, outputParams, dstChainId, gasParams);
    }

    function testCallOutWithDepositArbtirum() public {
        _testCallOutWithDepositArbtirum(address(this), 100 ether, 100 ether, 100 ether, 50 ether);
    }

    function testFuzzCallOutWithDepositArbtirum(
        address _user,
        uint256 _amount,
        uint256 _deposit,
        uint256 _amountOut,
        uint256 _depositOut
    ) public {
        // Input restrictions
        _amount %= type(uint128).max;

        uint256 size;
        assembly {
            size := extcodesize(_user)
        }

        // Input restrictions
        vm.assume(
            _user != address(0) && size == 0 && _amount > _deposit && _amount >= _amountOut
                && _amount - _amountOut >= _depositOut && _depositOut < _amountOut
        );

        _testCallOutWithDepositArbtirum(_user, _amount, _deposit, _amountOut, _depositOut);
    }

    function _testCallOutWithDepositArbtirum(
        address _user,
        uint256 _amount,
        uint256 _deposit,
        uint256 _amountOut,
        uint256 _depositOut
    ) internal {
        //Set up
        testAddLocalTokenArbitrum();

        // Prepare data
        bytes memory packedData = prepareMulticallSingleOutput_singleTransfer(
            newArbitrumAssetGlobalAddress,
            mockApp,
            0,
            _user,
            _user,
            newArbitrumAssetGlobalAddress,
            _amountOut,
            _depositOut,
            rootChainId,
            GasParams(0, 0)
        );

        //Get some gas.
        vm.deal(_user, 1 ether);

        if (_amount - _deposit > 0) {
            //assure there is enough balance for mock action
            vm.startPrank(address(rootPort));
            ERC20hToken(newArbitrumAssetGlobalAddress).mint(_user, _amount - _deposit);
            vm.stopPrank();
            arbitrumMockToken.mint(address(arbitrumPort), _amount - _deposit);
        }

        //Mint Underlying Token.
        if (_deposit > 0) arbitrumMockToken.mint(_user, _deposit);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumMockToken),
            amount: _amount,
            deposit: _deposit
        });

        //Call Deposit function
        vm.startPrank(_user);
        arbitrumMockToken.approve(address(arbitrumPort), _deposit);
        ERC20hToken(newArbitrumAssetGlobalAddress).approve(address(rootPort), _amount - _deposit);
        arbitrumMulticallBranchBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            packedData, depositInput, GasParams(0.5 ether, 0.5 ether), false
        );
        vm.stopPrank();

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(arbitrumMulticallBranchBridgeAgent),
            uint32(1),
            _user,
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumMockToken),
            _amount,
            _deposit
        );

        address userAccount = address(rootPort.getUserAccount(_user));

        require(
            MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)) == _amount - _deposit + _deposit - _depositOut,
            "LocalPort tokens"
        );

        require(MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)) == 0, "RootPort tokens");

        require(MockERC20(arbitrumMockToken).balanceOf(_user) == _depositOut, "User tokens");

        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user) == _amountOut - _depositOut, "User Global tokens"
        );

        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(userAccount) == _amount - _amountOut,
            "User Account tokens"
        );
    }

    uint32 prevNonceRoot;
    uint32 prevNonceBranch;

    function testCallOutWithDepositSuccess() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        // Prepare data
        bytes memory packedData = prepareMulticallSingleOutput_singleTransfer(
            newAvaxAssetGlobalAddress,
            mockApp,
            1 ether,
            address(18),
            address(18),
            newAvaxAssetGlobalAddress,
            99 ether,
            50 ether,
            avaxChainId,
            GasParams(500_000, 0)
        );

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            packedData, depositInput, GasParams(1_800_000, 0.01 ether), false
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce() - 1, "Root should be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(18),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testCallOutWithDepositNotEnoughGasForRootRetryMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        // Prepare data
        bytes memory packedData = prepareMulticallSingleOutput_singleTransfer(
            newAvaxAssetGlobalAddress,
            mockApp,
            1 ether,
            address(18),
            address(18),
            newAvaxAssetGlobalAddress,
            99 ether,
            50 ether,
            avaxChainId,
            GasParams(500_000, 0)
        );

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            packedData, depositInput, GasParams(600_000, 0.01 ether), false
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(18),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testCallOutWithDepositWrongCalldataForRootRetryMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        // Prepare data
        bytes memory packedData = prepareMulticallSingleOutput_singleTransfer(
            newAvaxAssetGlobalAddress,
            mockApp,
            1 ether,
            address(18),
            address(18),
            newAvaxAssetGlobalAddress,
            99 ether,
            50 ether,
            ftmChainId, // root will revert with `UnrecognizedUnderlyingAddress` because ftm local token was not added
            GasParams(500_000, 0)
        );

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            packedData, depositInput, GasParams(1_250_000, 0.01 ether), false
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(18),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );
    }

    function testCallOutWithDepositNotEnoughGasForRootFallbackMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        // Prepare data
        bytes memory packedData = prepareMulticallSingleOutput_singleTransfer(
            newAvaxAssetGlobalAddress,
            mockApp,
            1 ether,
            address(18),
            address(18),
            newAvaxAssetGlobalAddress,
            99 ether,
            50 ether,
            avaxChainId,
            GasParams(500_000, 0)
        );

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            packedData, depositInput, GasParams(800_000, 0.01 ether), true
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(18),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testCallOutWithDepositWrongCalldataForRootFallbackMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        // Prepare data
        bytes memory packedData = prepareMulticallSingleOutput_singleTransfer(
            newAvaxAssetGlobalAddress,
            mockApp,
            1 ether,
            address(18),
            address(18),
            newAvaxAssetGlobalAddress,
            99 ether,
            50 ether,
            ftmChainId, // root will revert with `UnrecognizedUnderlyingAddress` because ftm local token was not added
            GasParams(500_000, 0)
        );

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            packedData, depositInput, GasParams(1_500_000, 0.2 ether), true
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(18),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToLzChain(avaxChainId);

        // Check if status failed
        avaxMulticallBridgeAgent.getDepositEntry(prevNonceBranch).status = 1;
    }

    //////////////////////////////////////
    //    RETRY, RETRIEVE AND REDEEM    //
    //////////////////////////////////////

    // function testFallbackGasAmount() public {
    //     _testFallbackGasAmount(payable(address(this)), 10);
    // }

    // function _testFallbackGasAmount(address payable _refundee, uint32 _settlementNonce) private {
    //     vm.deal(address(this), 10 ether);

    //     uint256 gasStart = gasleft();
    //     //Sends message to LayerZero messaging layer
    //     ILayerZeroEndpoint(lzEndpointAddress).send{value: address(this).balance}(
    //         rootChainId,
    //         abi.encodePacked(address(this), address(this)),
    //         abi.encodePacked(bytes1(0x09), _settlementNonce),
    //         _refundee,
    //         address(0),
    //         abi.encodePacked(uint16(1), uint256(50_000))
    //     );

    //     console2.log("gas used: ", gasStart - gasleft());
    // }

    function testRetrieveDeposit() public {
        //Set up
        testCallOutWithDepositNotEnoughGasForRootFallbackMode();

        switchToLzChain(avaxChainId);

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Call Deposit function
        avaxMulticallBridgeAgent.retrieveDeposit{value: 10 ether}(prevNonceRoot, GasParams(1_000_000, 0.01 ether));

        //Stop prank
        vm.stopPrank();

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).status == 0, "Deposit status should be success."
        );

        switchToLzChain(rootChainId);

        switchToLzChain(avaxChainId);

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).status == 1,
            "Deposit status should be ready for redemption."
        );
    }

    function testRedeemDepositAfterRetrieve() public {
        //Set up
        testRetrieveDeposit();

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        uint256 balanceBefore = avaxMockAssetToken.balanceOf(address(18));

        //Call Deposit function
        avaxMulticallBridgeAgent.redeemDeposit(prevNonceRoot, address(18));

        //Stop prank
        vm.stopPrank();

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).owner == address(0),
            "Deposit status should have ceased to exist"
        );

        require(avaxMockAssetToken.balanceOf(address(18)) == balanceBefore + 100 ether, "Balance should be increased.");
    }

    function testRedeemDepositAfterFallback() public {
        //Set up
        testCallOutWithDepositWrongCalldataForRootFallbackMode();

        uint256 balanceBefore = avaxMockAssetToken.balanceOf(address(18));

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Call Deposit function
        avaxMulticallBridgeAgent.redeemDeposit(prevNonceRoot, address(18));

        //Stop prank
        vm.stopPrank();

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).owner == address(0),
            "Deposit status should have ceased to exist"
        );

        require(avaxMockAssetToken.balanceOf(address(18)) == balanceBefore + 100 ether, "Balance should be increased.");
    }

    function testRetryDeposit() public {
        //Set up
        testCallOutWithDepositNotEnoughGasForRootRetryMode();

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        // Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams =
                OutputParams(address(18), address(18), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(800_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Call Deposit function
        avaxMulticallBridgeAgent.retryDepositSigned{value: 5 ether}(
            prevNonceBranch - 1, packedData, GasParams(2_000_000, 0.02 ether), false
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce() - 1, "Root should be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        // check this address balance
        require(MockERC20(newAvaxAssetFtmLocalToken).balanceOf(address(18)) == 99 ether, "Tokens should be received");
    }

    function testRetryDepositNotEnoughGasForSettlement() public {
        //Set up
        testCallOutWithDepositNotEnoughGasForRootRetryMode();

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        console2.log("previous nonce branch", prevNonceBranch);

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        console2.log("previous nonce root", prevNonceRoot);

        // Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams =
                OutputParams(address(18), address(18), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(0, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(18), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Call Deposit function
        avaxMulticallBridgeAgent.retryDepositSigned{value: 5 ether}(
            prevNonceBranch - 1, packedData, GasParams(2_000_000, 0.02 ether), false
        );

        // Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce() - 1, "Root should be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        //ExecutionStatus should be 0
        require(
            ftmMulticallBridgeAgent.executionState(prevNonceBranch + 1) == 0,
            "Settlement status should not be executed."
        );

        // check this address balance
        require(MockERC20(newAvaxAssetFtmLocalToken).balanceOf(address(18)) == 0, "Tokens should not be received");
    }

    function testRetrySettlement() public {
        //Set up
        testRetryDepositNotEnoughGasForSettlement();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));
        vm.etch(address(18), address(avaxMulticallBridgeAgent).code);

        console2.log("testRetrySettlement from avax");

        //Call Deposit function
        avaxMulticallBridgeAgent.retrySettlement{value: 100 ether}(
            prevNonceBranch - 1, "", [GasParams(1_000_000, 0.1 ether), GasParams(150_000, 0)], false
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        console2.log("executed root going testRetrySettlement from root");

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        // check this address balance
        require(MockERC20(newAvaxAssetFtmLocalToken).balanceOf(address(18)) == 99 ether, "Tokens should be received");
    }

    function testRetrySettlementTriggerFallback() public {
        //Set up
        testRetryDepositNotEnoughGasForSettlement();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Call Deposit function
        avaxMulticallBridgeAgent.retrySettlement{value: 100 ether}(
            prevNonceBranch - 1, "a", [GasParams(1_000_000, 0.1 ether), GasParams(300_000, 5 ether)], true
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        switchToLzChain(rootChainId);

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot - 1).status == 1,
            "Settlement status should be failed after fallback."
        );
    }

    function testRedeemSettlement() public {
        //Set up
        testRetrySettlementTriggerFallback();

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Call Deposit function
        multicallRootBridgeAgent.redeemSettlement(prevNonceRoot - 1, address(18));

        //Stop prank
        vm.stopPrank();

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).owner == address(0),
            "Settlement should have vanished."
        );
    }

    function testRetrySettlementNoFallback() public {
        //Set up
        testRetryDepositNotEnoughGasForSettlement();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        // Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams =
                OutputParams(address(18), address(18), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(800_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some ether.
        vm.deal(address(18), 100 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //     retrySettlement(
        //     uint32 _settlementNonce,
        //     bytes calldata _params,
        //     GasParams[2] calldata _gParams,
        //     bool _hasFallbackToggled
        // )

        //Call Deposit function
        avaxMulticallBridgeAgent.retrySettlement{value: 100 ether}(
            prevNonceBranch - 1, "jkladsjkldsajklads", [GasParams(1_000_000, 0.1 ether), GasParams(300_000, 0)], false
        );

        //Stop prank
        vm.stopPrank();

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        switchToLzChain(rootChainId);

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot - 1).status == 0,
            "Settlement status should be stay unexecuted after failure."
        );
    }

    function testRetrieveSettlement() public {
        //Set up
        testRetrySettlementNoFallback();

        //Get some ether.
        vm.deal(address(18), 10 ether);

        //Prank address 18
        vm.startPrank(address(18));

        //Call Deposit function
        multicallRootBridgeAgent.retrieveSettlement{value: 1 ether}(prevNonceRoot - 1, GasParams(1_000_000, 0.1 ether));

        //Stop prank
        vm.stopPrank();

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        switchToLzChain(rootChainId);

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot - 1).status == 1,
            "Settlement status should be ready for redemption."
        );
    }

    //////////////////////////////////////////////////////////////////////////   HELPERS   ///////////////////////////////////////////////////////////////////

    function testCreateDepositSingle(
        // address _branchPort,
        address _bridgeAgent,
        uint32 _depositNonce,
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit
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
        Deposit memory deposit = BranchBridgeAgent(payable(_bridgeAgent)).getDepositEntry(_depositNonce);

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

    /*///////////////////////////////////////////////////////////////
                        BRANCH BRIDGE AGENT TESTS
    ///////////////////////////////////////////////////////////////*/

    // Internal Notation because we only do an external call for easier bytes handling
    function _testRequiresEndpointBranch(
        BranchBridgeAgent _branchBridgeAgent,
        RootBridgeAgent _rootBridgeAgent,
        address _lzEndpointAddress,
        uint16 _rootChainId,
        address _endpoint,
        uint16 _srcChainId,
        bytes calldata _path,
        bytes calldata _payload
    ) external {
        if (_endpoint != _lzEndpointAddress) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedEndpoint.selector);
        } else if (_path.length != 40) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedCaller.selector);
        } else if (address(_rootBridgeAgent) != address(uint160(bytes20(_path[:20])))) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedCaller.selector);
        } else if (_srcChainId != _rootChainId) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedCaller.selector);
        } else if (_payload[0] == 0xFF) {
            vm.expectRevert(IBranchBridgeAgent.UnknownFlag.selector);
        }

        // Call lzReceiveNonBlocking because lzReceive should never fail
        vm.prank(address(_branchBridgeAgent));
        _branchBridgeAgent.lzReceiveNonBlocking(_endpoint, _srcChainId, _path, _payload);
    }

    function testRequiresEndpointBranch() public {
        switchToLzChain(avaxChainId);

        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            rootChainId,
            abi.encodePacked(multicallRootBridgeAgent, avaxMulticallBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_NotCallingItself() public {
        switchToLzChain(avaxChainId);

        vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedEndpoint.selector);
        avaxMulticallBridgeAgent.lzReceiveNonBlocking(
            lzEndpointAddress,
            rootChainId,
            abi.encodePacked(multicallRootBridgeAgent, avaxMulticallBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_srcAddress() public {
        switchToLzChain(avaxChainId);

        bytes memory _pathData = abi.encodePacked(address(0), address(0));
        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            rootChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_srcAddress(address _srcAddress) public {
        switchToLzChain(avaxChainId);

        bytes memory _pathData = abi.encodePacked(_srcAddress, address(0));
        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            rootChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_pathData() public {
        switchToLzChain(avaxChainId);

        bytes memory _pathData = abi.encodePacked(multicallRootBridgeAgent);

        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            rootChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_pathData(bytes memory _pathData) public {
        switchToLzChain(avaxChainId);

        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            rootChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_srcChainId() public {
        switchToLzChain(avaxChainId);

        uint16 _srcChainId = 0;

        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            _srcChainId,
            abi.encodePacked(multicallRootBridgeAgent, avaxMulticallBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointBranch_srcChainId(uint16 _srcChainId) public {
        switchToLzChain(avaxChainId);

        this._testRequiresEndpointBranch(
            avaxMulticallBridgeAgent,
            multicallRootBridgeAgent,
            lzEndpointAddress,
            rootChainId,
            lzEndpointAddress,
            _srcChainId,
            abi.encodePacked(multicallRootBridgeAgent, avaxMulticallBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    /*///////////////////////////////////////////////////////////////
                        ROOT BRIDGE AGENT TESTS
    ///////////////////////////////////////////////////////////////*/

    // Internal Notation because we only do an external call for easier bytes handling
    function _testRequiresEndpointRoot(
        RootBridgeAgent _rootBridgeAgent,
        BranchBridgeAgent _branchBridgeAgent,
        address _lzEndpointAddress,
        uint16 _branchChainId,
        address _endpoint,
        uint16 _srcChainId,
        bytes calldata _path,
        bytes calldata _payload
    ) external {
        if (_endpoint != _lzEndpointAddress) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedEndpoint.selector);
        } else if (_path.length != 40) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedCaller.selector);
        } else if (address(_branchBridgeAgent) != address(uint160(bytes20(_path[:20])))) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedCaller.selector);
        } else if (_srcChainId != _branchChainId) {
            vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedCaller.selector);
        } else if (_payload[0] == 0xFF) {
            vm.expectRevert(IBranchBridgeAgent.UnknownFlag.selector);
        }

        // Call lzReceiveNonBlocking because lzReceive should never fail
        vm.prank(address(_rootBridgeAgent));
        _rootBridgeAgent.lzReceiveNonBlocking(_endpoint, _srcChainId, _path, _payload);
    }

    function testRequiresEndpointRoot() public {
        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            avaxChainId,
            abi.encodePacked(avaxMulticallBridgeAgent, multicallRootBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_NotCallingItself() public {
        vm.expectRevert(IBranchBridgeAgent.LayerZeroUnauthorizedEndpoint.selector);
        multicallRootBridgeAgent.lzReceiveNonBlocking(
            lzEndpointAddress,
            avaxChainId,
            abi.encodePacked(avaxMulticallBridgeAgent, multicallRootBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_srcAddress() public {
        bytes memory _pathData = abi.encodePacked(address(0), address(0));
        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            avaxChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_srcAddress(address _srcAddress) public {
        bytes memory _pathData = abi.encodePacked(_srcAddress, address(0));
        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            avaxChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_pathData() public {
        bytes memory _pathData = abi.encodePacked(avaxMulticallBridgeAgent);

        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            avaxChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_pathData(bytes memory _pathData) public {
        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            avaxChainId,
            _pathData,
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_srcChainId() public {
        uint16 _srcChainId = 0;

        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            _srcChainId,
            abi.encodePacked(avaxMulticallBridgeAgent, multicallRootBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function testRequiresEndpointRoot_srcChainId(uint16 _srcChainId) public {
        this._testRequiresEndpointRoot(
            multicallRootBridgeAgent,
            avaxMulticallBridgeAgent,
            lzEndpointAddress,
            avaxChainId,
            lzEndpointAddress,
            _srcChainId,
            abi.encodePacked(avaxMulticallBridgeAgent, multicallRootBridgeAgent),
            abi.encodePacked(bytes1(0xFF))
        );
    }

    function test_CallOutAndBridgeMultiple_withLocalToken() public {
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        MockERC20 underToken0 = new MockERC20("u0 token", "U0", 18);
        MockERC20 underToken1 = new MockERC20("u0 token", "U0", 18);

        vm.deal(address(this), 10 ether);
        avaxCoreRouter.addLocalToken{value: 1 ether}(address(underToken0), GasParams(2_000_000, 0));
        avaxCoreRouter.addLocalToken{value: 1 ether}(address(underToken1), GasParams(2_000_000, 0));

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        address localTokenUnder0 = rootPort.getLocalTokenFromUnderlying(address(underToken0), avaxChainId);
        address localTokenUnder1 = rootPort.getLocalTokenFromUnderlying(address(underToken1), avaxChainId);

        switchToLzChain(avaxChainId);

        vm.deal(address(this), 50 ether);
        uint256 _amount0 = 2 ether;
        uint256 _amount1 = 2 ether;
        uint256 _deposit0 = 1 ether;
        uint256 _deposit1 = 1 ether;

        // GasParams
        GasParams memory gasParams = GasParams(1_250_000, 0 ether);

        address _recipient = address(this);

        underToken0.mint(_recipient, _deposit0);
        underToken1.mint(_recipient, _deposit1);

        address[] memory hTokens = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory deposits = new uint256[](2);

        hTokens[0] = localTokenUnder0;
        hTokens[1] = localTokenUnder1;
        tokens[0] = address(underToken0);
        tokens[1] = address(underToken1);
        amounts[0] = _amount0;
        amounts[1] = _amount1;
        deposits[0] = _deposit0;
        deposits[1] = _deposit1;

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        _getLocalhTokensToBranch(
            GetLocalhTokensToBranchParams(
                avaxChainId,
                address(this),
                _recipient,
                hTokens,
                tokens,
                amounts,
                deposits,
                GasParams(2_250_000, 0.1 ether),
                gasParams
            )
        );
    }

    function _test_CallOutAndBridgeMultiple_withLocalToken(
        address[] memory hTokens,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory deposits,
        GasParams memory gasParams
    ) public {
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        // Prepare deposit info
        DepositMultipleInput memory depositInput =
            DepositMultipleInput({hTokens: hTokens, tokens: tokens, amounts: amounts, deposits: deposits});

        for (uint256 i = 0; i < tokens.length; i++) {
            MockERC20(tokens[i]).approve(address(avaxMulticallRouter), deposits[i]);
        }

        vm.deal(address(this), 50 ether);
        // deposit multiple assets from Avax branch to Root
        // Attempting to deposit two hTokens and two underlyingTokens
        avaxMulticallRouter.callOutAndBridgeMultiple{value: 1 ether}(bytes(""), depositInput, gasParams);
        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    struct GetLocalhTokensToBranchParams {
        uint16 branchChainId;
        address owner;
        address recipient;
        address[] hTokensLocal;
        address[] tokens;
        uint256[] amounts;
        uint256[] deposits;
        GasParams gasParamsFromBranchToRoot;
        GasParams gasParamsFromRootToBranch;
    }

    function _getLocalhTokensToBranch(GetLocalhTokensToBranchParams memory _params) internal {
        address[] memory hTokensGlobal = new address[](_params.hTokensLocal.length);

        for (uint256 i = 0; i < _params.hTokensLocal.length; i++) {
            // Get Global Token
            hTokensGlobal[i] = rootPort.getGlobalTokenFromLocal(_params.hTokensLocal[i], _params.branchChainId);
        }

        uint256[] memory hTokenDesiredBalance = new uint256[](_params.amounts.length);

        for (uint256 i = 0; i < _params.amounts.length; i++) {
            // Get local hToken amount
            hTokenDesiredBalance[i] = _params.amounts[i] - _params.deposits[i];
        }

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        OutputMultipleParams memory outputMultipleParams;
        bytes memory routerPayload;

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](0);

            {
                uint256[] memory emptyDeposits = new uint256[](_params.amounts.length);

                // Output Params
                outputMultipleParams = OutputMultipleParams(
                    _params.owner, _params.recipient, hTokensGlobal, hTokenDesiredBalance, emptyDeposits
                );
            }

            routerPayload = abi.encodePacked(
                bytes1(0x03),
                abi.encode(calls, outputMultipleParams, _params.branchChainId, _params.gasParamsFromRootToBranch)
            );
        }

        DepositMultipleInput memory depositInput = DepositMultipleInput({
            hTokens: _params.hTokensLocal,
            tokens: _params.tokens,
            amounts: hTokenDesiredBalance,
            deposits: hTokenDesiredBalance
        });

        for (uint256 i = 0; i < _params.tokens.length; i++) {
            // Mint to owner
            MockERC20(_params.tokens[i]).mint(_params.owner, hTokenDesiredBalance[0]);
            // Approve spend by router
            MockERC20(_params.tokens[i]).approve(address(avaxPort), hTokenDesiredBalance[0]);
        }

        avaxMulticallBridgeAgent.callOutSignedAndBridgeMultiple{value: 50 ether}(
            routerPayload, depositInput, _params.gasParamsFromBranchToRoot, false
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }
}

contract MockPortStartegy {
    function withdraw(address port, address token, uint256 amount) public {
        MockERC20(token).transfer(port, amount);
    }
}
