//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/ImportHelper.sol";

contract MockRootPort {
    /// @notice Holds the mapping from Virtual account to router address => bool.
    /// @notice Stores whether a router is approved to spend a virtual account.
    mapping(VirtualAccount acount => mapping(address router => bool allowed)) public isRouterApproved;

    function setRouterApproved(VirtualAccount account, address router, bool allowed) public {
        isRouterApproved[account][router] = allowed;
    }
}

contract VirtualAccountTest is DSTestPlus {
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                             GLOBAL CONTRACTS
    //////////////////////////////////////////////////////////////*/

    address public localPortAddress = address(new MockRootPort());

    /*//////////////////////////////////////////////////////////////
                            FALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                               TEST SETUP
    //////////////////////////////////////////////////////////////*/

    function _deployVirtualAccount(address _userAddress, address _localPortAddress) internal returns (VirtualAccount) {
        return new VirtualAccount(_userAddress, _localPortAddress);
    }

    function test_constructor(address _userAddress, address _localPortAddress)
        public
        returns (VirtualAccount virtualAccount)
    {
        virtualAccount = _deployVirtualAccount(_userAddress, _localPortAddress);

        assertEq(virtualAccount.userAddress(), _userAddress);
        assertEq(virtualAccount.localPortAddress(), _localPortAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST PERMISSIONS
    //////////////////////////////////////////////////////////////*/

    function test_requiresApprovedCaller_withdrawNative(address _userAddress, uint256 _withdrawAmount)
        public
        returns (VirtualAccount virtualAccount)
    {
        if (_userAddress == address(this)) _userAddress = address(1);

        virtualAccount = _deployVirtualAccount(_userAddress, localPortAddress);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.withdrawNative(_withdrawAmount);
    }

    function test_requiresApprovedCaller_withdrawERC20(address _userAddress, address _token, uint256 _withdrawAmount)
        public
        returns (VirtualAccount virtualAccount)
    {
        if (_userAddress == address(this)) _userAddress = address(1);

        virtualAccount = _deployVirtualAccount(_userAddress, localPortAddress);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.withdrawERC20(_token, _withdrawAmount);
    }

    function test_requiresApprovedCaller_withdrawERC721(address _userAddress, address _token, uint256 _tokenId)
        public
        returns (VirtualAccount virtualAccount)
    {
        if (_userAddress == address(this)) _userAddress = address(1);

        virtualAccount = _deployVirtualAccount(_userAddress, localPortAddress);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.withdrawERC721(_token, _tokenId);
    }

    function test_requiresApprovedCaller_call(address _userAddress, Call[] calldata _calls)
        public
        returns (VirtualAccount virtualAccount)
    {
        if (_userAddress == address(this)) _userAddress = address(1);

        virtualAccount = _deployVirtualAccount(_userAddress, localPortAddress);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.call(_calls);
    }

    function test_requiresApprovedCaller_payableCall(address _userAddress, PayableCall[] calldata _calls)
        public
        returns (VirtualAccount virtualAccount)
    {
        if (_userAddress == address(this)) _userAddress = address(1);

        virtualAccount = _deployVirtualAccount(_userAddress, localPortAddress);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.payableCall(_calls);
    }

    /*//////////////////////////////////////////////////////////////
                              TEST NATIVE
    //////////////////////////////////////////////////////////////*/

    function test_receiveETH(address _userAddress, address _localPortAddress, uint256 _depositAmount)
        public
        returns (VirtualAccount virtualAccount)
    {
        virtualAccount = _deployVirtualAccount(_userAddress, _localPortAddress);

        _testSendEth(address(virtualAccount), _depositAmount);
    }

    function test_withdrawNative(address _userAddress, uint256 _depositAmount, uint256 _withdrawAmount)
        public
        returns (VirtualAccount virtualAccount)
    {
        (_depositAmount, _withdrawAmount) = _parseDepositAndWithdrawAmounts(_depositAmount, _withdrawAmount);

        virtualAccount = test_receiveETH(_userAddress, localPortAddress, _depositAmount);

        MockRootPort(localPortAddress).setRouterApproved(virtualAccount, address(this), true);
        virtualAccount.withdrawNative(_withdrawAmount);

        assertEq(address(virtualAccount).balance, _depositAmount - _withdrawAmount);
    }

    function test_withdrawNative_Unautharized(address _userAddress, uint256 _depositAmount, uint256 _withdrawAmount)
        public
        returns (VirtualAccount virtualAccount)
    {
        if (_userAddress == address(this)) _userAddress = address(1);
        (_depositAmount, _withdrawAmount) = _parseDepositAndWithdrawAmounts(_depositAmount, _withdrawAmount);

        virtualAccount = test_receiveETH(_userAddress, localPortAddress, _depositAmount);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.withdrawNative(_withdrawAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              TEST ERC20
    //////////////////////////////////////////////////////////////*/

    function test_receiveERC20() public {
        test_receiveERC20(address(this), localPortAddress, 0, 100 ether);
    }

    function test_receiveERC20(
        address _userAddress,
        address _localPortAddress,
        bytes32 _tokenSalt,
        uint256 _depositAmount
    ) public returns (VirtualAccount virtualAccount) {
        address token = address(new MockERC20{salt: _tokenSalt}("Test Token","TTK",18));

        virtualAccount = _test_receiveERC20(_userAddress, _localPortAddress, token, _depositAmount);
    }

    function _test_receiveERC20(address _userAddress, address _localPortAddress, address _token, uint256 _depositAmount)
        internal
        returns (VirtualAccount virtualAccount)
    {
        virtualAccount = _deployVirtualAccount(_userAddress, _localPortAddress);

        _testSendERC20(address(virtualAccount), _token, _depositAmount);
    }

    function test_withdrawERC20(
        address _userAddress,
        bytes32 _tokenSalt,
        uint256 _depositAmount,
        uint256 _withdrawAmount
    ) public returns (VirtualAccount virtualAccount) {
        (_depositAmount, _withdrawAmount) = _parseDepositAndWithdrawAmounts(_depositAmount, _withdrawAmount);

        address token = address(new MockERC20{salt: _tokenSalt}("Test Token","TTK",18));

        virtualAccount = _test_receiveERC20(_userAddress, localPortAddress, token, _depositAmount);

        MockRootPort(localPortAddress).setRouterApproved(virtualAccount, address(this), true);
        virtualAccount.withdrawERC20(token, _withdrawAmount);

        assertEq(token.balanceOf(address(virtualAccount)), _depositAmount - _withdrawAmount);
    }

    function test_withdrawERC20_Unautharized(
        address _userAddress,
        bytes32 _tokenSalt,
        uint256 _depositAmount,
        uint256 _withdrawAmount
    ) public returns (VirtualAccount virtualAccount) {
        if (_userAddress == address(this)) _userAddress = address(1);
        (_depositAmount, _withdrawAmount) = _parseDepositAndWithdrawAmounts(_depositAmount, _withdrawAmount);

        address token = address(new MockERC20{salt: _tokenSalt}("Test Token","TTK",18));

        virtualAccount = _test_receiveERC20(_userAddress, localPortAddress, token, _depositAmount);

        hevm.expectRevert(IVirtualAccount.UnauthorizedCaller.selector);
        virtualAccount.withdrawERC20(token, _withdrawAmount);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST HELPERS
    //////////////////////////////////////////////////////////////*/

    function _parseDepositAndWithdrawAmounts(uint256 depositAmount, uint256 withdrawAmount)
        internal
        pure
        returns (uint256, uint256)
    {
        // Can't withdraw 0 or more than deposited
        if (depositAmount == 0) return (0, 0);

        return (depositAmount, withdrawAmount % depositAmount);
    }

    function _testSendEth(address _to, uint256 _amount) internal {
        hevm.deal(address(this), _amount);

        uint256 oldBalance = _to.balance;

        _to.safeTransferETH(_amount);

        assertEq(_to.balance, _amount + oldBalance);
    }

    function _testSendERC20(address _to, address _token, uint256 _amount) internal {
        MockERC20(_token).mint(address(this), _amount);

        uint256 oldBalance = _token.balanceOf(_to);

        _token.safeTransfer(_to, _amount);

        assertEq(_token.balanceOf(_to), _amount + oldBalance);
    }
}
