// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Decode Params Library
 * @notice Library for decoding Ulysses cross-chain messages.
 * @dev    Used for decoding of Ulysses cross-chain messages.
 */
library DecodeBridgeInMultipleParams {
    /*///////////////////////////////////////////////////////////////
                   PAYLOAD DECODING POSITIONAL CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Defines the position in bytes where the payload starts after the flag byte.
    // Also used to offset number of assets in the payload.
    uint256 internal constant PARAMS_START = 1;

    // Defines the position in bytes where token-related information starts, after flag byte and nonce.
    uint256 internal constant PARAMS_TKN_START = 5;

    // Size in bytes for standard Ethereum types / slot size (like uint256).
    uint256 internal constant PARAMS_ENTRY_SIZE = 32;

    // Offset in bytes from the start of a slot to the start of an address.
    // Considering Ethereum addresses are 20 bytes and fit within the 32 bytes slot.
    uint256 internal constant ADDRESS_END_OFFSET = 12;

    // Offset in bytes to reach the amount parameter after hToken and token addresses in the token-related info.
    uint256 internal constant PARAMS_AMT_OFFSET = 64;

    // Offset in bytes to reach the deposit parameter after hToken, token, and amount in the token-related info.
    uint256 internal constant PARAMS_DEPOSIT_OFFSET = 96;

    /*///////////////////////////////////////////////////////////////
                    PAYLOAD DECODING POSITIONAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function decodeBridgeMultipleInfo(bytes calldata _params)
        internal
        pure
        returns (
            uint8 numOfAssets,
            uint32 nonce,
            address[] memory hTokens,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory deposits
        )
    {
        // Parse Parameters
        numOfAssets = uint8(bytes1(_params[0]));

        // Parse Nonce
        nonce = uint32(bytes4(_params[PARAMS_START:PARAMS_TKN_START]));

        // Initialize Arrays
        hTokens = new address[](numOfAssets);
        tokens = new address[](numOfAssets);
        amounts = new uint256[](numOfAssets);
        deposits = new uint256[](numOfAssets);

        for (uint256 i = 0; i < numOfAssets;) {
            // Cache offset
            uint256 currentIterationOffset = PARAMS_START + i;

            // Parse Params
            hTokens[i] = address(
                uint160(
                    bytes20(
                        bytes32(
                            _params[
                                PARAMS_TKN_START + (PARAMS_ENTRY_SIZE * i) + ADDRESS_END_OFFSET:
                                    PARAMS_TKN_START + (PARAMS_ENTRY_SIZE * currentIterationOffset)
                            ]
                        )
                    )
                )
            );

            tokens[i] = address(
                uint160(
                    bytes20(
                        bytes32(
                            _params[
                                PARAMS_TKN_START + PARAMS_ENTRY_SIZE * (i + numOfAssets) + ADDRESS_END_OFFSET:
                                    PARAMS_TKN_START + PARAMS_ENTRY_SIZE * (currentIterationOffset + numOfAssets)
                            ]
                        )
                    )
                )
            );

            amounts[i] = uint256(
                bytes32(
                    _params[
                        PARAMS_TKN_START + PARAMS_AMT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * i:
                            PARAMS_TKN_START + PARAMS_AMT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * currentIterationOffset
                    ]
                )
            );

            deposits[i] = uint256(
                bytes32(
                    _params[
                        PARAMS_TKN_START + PARAMS_DEPOSIT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * i:
                            PARAMS_TKN_START + PARAMS_DEPOSIT_OFFSET * numOfAssets
                                + PARAMS_ENTRY_SIZE * currentIterationOffset
                    ]
                )
            );

            unchecked {
                ++i;
            }
        }
    }
}
