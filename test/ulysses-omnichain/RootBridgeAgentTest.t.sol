//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/ImportHelper.sol";

contract RootBridgeAgentTest is DSTestPlus {
    using AddressCodeSize for address;

    MockRootBridgeAgent mockRootBridgeAgent;
    RootPort rootPort;

    address user = address(0xCAFE);

    function setUp() public {
        rootPort = new RootPort(100);

        mockRootBridgeAgent = new MockRootBridgeAgent(
        100,
        address(1),
        address(rootPort),
        address(1));
    }

    /*///////////////////////////////////////////////////////////////
                              TEST HELPERS
    ///////////////////////////////////////////////////////////////*/

    function test_computeAddress(address owner) public {
        if (owner == address(0)) owner = address(1);

        assertEq(
            ComputeVirtualAccount.computeAddress(address(rootPort), owner), address(rootPort.fetchVirtualAccount(owner))
        );
    }

    /*///////////////////////////////////////////////////////////////
                              TEST FUZZ
    ///////////////////////////////////////////////////////////////*/

    function test_fuzz_checkSettlementOwner(address caller, address settlementOwner) public {
        // Caller cannot be zero address
        if (caller == address(0)) caller = address(1);

        if (settlementOwner == address(0)) {
            // If settlementOwner is zero address, the settlement has already been redeemed
            hevm.expectRevert(IRootBridgeAgent.NotSettlementOwner.selector);
        } else if (caller != settlementOwner) {
            if (settlementOwner.isContract()) {
                // If the caller and settlementOwner are not the same, the owner cannot be a contract
                hevm.expectRevert(IRootBridgeAgent.ContractsVirtualAccountNotAllowed.selector);
            } else if (caller != ComputeVirtualAccount.computeAddress(address(rootPort), settlementOwner)) {
                // If the caller is not the settlementOwner, the caller must be the computed virtual account
                hevm.expectRevert(IRootBridgeAgent.NotSettlementOwner.selector);
            } else {
                // If caller is the virtual account, deploy the virtual account if it does not exist
                rootPort.fetchVirtualAccount(settlementOwner);
            }
        }

        mockRootBridgeAgent.checkSettlementOwner(caller, settlementOwner);
    }

    /*///////////////////////////////////////////////////////////////
                           TEST SAME ADDRESS
    ///////////////////////////////////////////////////////////////*/

    // The following tests should all pass because the caller and settlementOwner are the same address

    function test_fuzz_checkSettlementOwner_sameAddress(address owner) public {
        if (owner == address(0)) owner = address(1);

        test_fuzz_checkSettlementOwner(owner, owner);
    }

    function test_checkSettlementOwner_sameAddress_EOA() public {
        test_fuzz_checkSettlementOwner(user, user);
    }

    function test_checkSettlementOwner_sameAddress_contract() public {
        test_fuzz_checkSettlementOwner(address(this), address(this));
    }

    function test_checkSettlementOwner_sameAddress_virtualAccount() public {
        address virtualAccount = address(rootPort.fetchVirtualAccount(user));
        test_fuzz_checkSettlementOwner(virtualAccount, virtualAccount);
    }

    /*///////////////////////////////////////////////////////////////
                          TEST ALREADY REDEEMED
    ///////////////////////////////////////////////////////////////*/

    // The following tests should all fail because the settlement has already been redeemed

    function test_fuzz_checkSettlementOwner_alreadyRedeemed(address owner) public {
        test_fuzz_checkSettlementOwner(owner, address(0));
    }

    function test_checkSettlementOwner_alreadyRedeemed_EOA() public {
        test_fuzz_checkSettlementOwner(user, address(0));
    }

    function test_checkSettlementOwner_alreadyRedeemed_Contract() public {
        test_fuzz_checkSettlementOwner(address(this), address(0));
    }

    function test_checkSettlementOwner_alreadyRedeemed_VirtualAccount() public {
        address virtualAccount = address(rootPort.fetchVirtualAccount(user));
        test_fuzz_checkSettlementOwner(virtualAccount, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                            TEST IS CONTRACT
    ///////////////////////////////////////////////////////////////*/

    // The following tests should all fail because the settlementOwner is not the caller and is a contract

    function test_fuzz_checkSettlementOwner_isContract(address owner) public {
        test_fuzz_checkSettlementOwner(owner, address(this));
    }

    function test_checkSettlementOwner_isContract_EOA() public {
        test_fuzz_checkSettlementOwner(user, address(this));
    }

    function test_checkSettlementOwner_isContract_Contract() public {
        test_fuzz_checkSettlementOwner(address(this), address(rootPort));
    }

    function test_checkSettlementOwner_isContract_VirtualAccount() public {
        address virtualAccount = address(rootPort.fetchVirtualAccount(address(this)));
        test_fuzz_checkSettlementOwner(virtualAccount, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                          TEST DIFFERENT ADDRESS
    ///////////////////////////////////////////////////////////////*/

    // The following tests should all fail because the settlementOwner is not the caller and is not a contract

    function test_fuzz_checkSettlementOwner_differentAddress(address owner) public {
        if (owner == user) owner = address(1);

        test_fuzz_checkSettlementOwner(owner, user);
    }

    function test_checkSettlementOwner_differentAddress_EOA() public {
        test_fuzz_checkSettlementOwner(address(1), user);
    }

    function test_checkSettlementOwner_differentAddress_Contract() public {
        test_fuzz_checkSettlementOwner(address(this), user);
    }

    function test_checkSettlementOwner_differentAddress_VirtualAccount() public {
        address virtualAccount = address(rootPort.fetchVirtualAccount(address(1)));
        test_fuzz_checkSettlementOwner(virtualAccount, user);
    }

    /*///////////////////////////////////////////////////////////////
                          TEST VIRTUAL ACCOUNT
    ///////////////////////////////////////////////////////////////*/

    // The following tests should all pass because the caller is the settlementOwner's virtual account

    function test_fuzz_checkSettlementOwner_virtualAccount(address owner) public {
        if (owner == address(0)) owner = address(1);

        address virtualAccount = address(rootPort.fetchVirtualAccount(owner));
        test_fuzz_checkSettlementOwner(virtualAccount, owner);
    }

    function test_checkSettlementOwner_virtualAccount_EOA() public {
        address virtualAccount = address(rootPort.fetchVirtualAccount(user));
        test_fuzz_checkSettlementOwner(virtualAccount, user);
    }
}
