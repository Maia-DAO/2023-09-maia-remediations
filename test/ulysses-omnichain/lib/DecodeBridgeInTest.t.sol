//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "../helpers/ImportHelper.sol";

contract DecodeBridgeInTest is BridgeAgentConstants, DSTestPlus {
    using DecodeBridgeInMultipleParams for bytes;

    function test_decodeBridgeMultipleInfo() public {
        _decodeBridgeMultipleInfo(
            5,
            1,
            getDynamicAddressArray([address(0), address(1), address(2), address(3), address(4)]),
            getDynamicAddressArray([address(5), address(6), address(7), address(8), address(9)]),
            getDynamicUint256Array([uint256(10), 11, 12, 13, 14]),
            getDynamicUint256Array([uint256(15), 16, 17, 18, 19])
        );
    }

    function test_fuzz_decodeBridgeMultipleInfo(
        uint8 _numberOfAssets,
        uint32 _nonce,
        address[255] calldata _hTokens,
        address[255] calldata _tokens,
        uint256[255] calldata _amounts,
        uint256[255] calldata _deposits
    ) public {
        if (_numberOfAssets == 0) {
            _numberOfAssets = 1;
        } else if (_numberOfAssets > MAX_TOKENS_LENGTH) {
            _numberOfAssets = uint8(MAX_TOKENS_LENGTH);
        }

        _decodeBridgeMultipleInfo(
            _numberOfAssets,
            _nonce,
            getDynamicAddressArray(_numberOfAssets, _hTokens),
            getDynamicAddressArray(_numberOfAssets, _tokens),
            getDynamicUint256Array(_numberOfAssets, _amounts),
            getDynamicUint256Array(_numberOfAssets, _deposits)
        );
    }

    function _decodeBridgeMultipleInfo(
        uint8 _numberOfAssets,
        uint32 _nonce,
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) public {
        bytes memory data = abi.encodePacked(_numberOfAssets, _nonce, _hTokens, _tokens, _amounts, _deposits);

        DepositMultipleParams memory expected = DepositMultipleParams({
            numberOfAssets: _numberOfAssets,
            depositNonce: _nonce,
            hTokens: _hTokens,
            tokens: _tokens,
            amounts: _amounts,
            deposits: _deposits
        });

        DepositMultipleParams memory actual = this.decodeBridgeMultipleInfo(data);

        assertEq(actual.numberOfAssets, expected.numberOfAssets);
        assertEq(actual.depositNonce, expected.depositNonce);
        assertAddressArrayEq(actual.hTokens, expected.hTokens);
        assertAddressArrayEq(actual.tokens, expected.tokens);
        assertUintArrayEq(actual.amounts, expected.amounts);
        assertUintArrayEq(actual.deposits, expected.deposits);
    }

    function decodeBridgeMultipleInfo(bytes calldata _params) external pure returns (DepositMultipleParams memory) {
        (
            uint8 numOfAssets,
            uint32 nonce,
            address[] memory hTokens,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory deposits
        ) = _params.decodeBridgeMultipleInfo();

        return DepositMultipleParams({
            numberOfAssets: numOfAssets,
            depositNonce: nonce,
            hTokens: hTokens,
            tokens: tokens,
            amounts: amounts,
            deposits: deposits
        });
    }

    function getDynamicAddressArray(uint256 _numberOfAssets, address[255] calldata _addresses)
        internal
        pure
        returns (address[] memory addresses)
    {
        addresses = new address[](_numberOfAssets);

        for (uint256 i = 0; i < _numberOfAssets; i++) {
            addresses[i] = _addresses[i];
        }
    }

    function getDynamicUint256Array(uint256 _numberOfAssets, uint256[255] calldata _uint256s)
        internal
        pure
        returns (uint256[] memory uint256s)
    {
        uint256s = new uint256[](_numberOfAssets);

        for (uint256 i = 0; i < _numberOfAssets; i++) {
            uint256s[i] = _uint256s[i];
        }
    }

    function getDynamicAddressArray(address[5] memory _addresses) internal pure returns (address[] memory addresses) {
        addresses = new address[](5);

        for (uint256 i = 0; i < 5; i++) {
            addresses[i] = _addresses[i];
        }
    }

    function getDynamicUint256Array(uint256[5] memory _uint256s) internal pure returns (uint256[] memory uint256s) {
        uint256s = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256s[i] = _uint256s[i];
        }
    }

    function assertAddressArrayEq(address[] memory a, address[] memory b) internal {
        require(a.length == b.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i]);
        }
    }
}
