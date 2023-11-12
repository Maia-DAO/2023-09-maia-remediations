// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Bridge Agent Constants Contract
 * @author MaiaDAO
 * @notice Constants for use in Bridge Agent and Bridge Agent Executor contracts.
 * @dev    Used for encoding and decoding of the cross-chain messages.
 */
contract BridgeAgentConstants {
    /*///////////////////////////////////////////////////////////////
             SETTLEMENT / DEPOSIT EXECUTION STATUS CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Indicates that a settlement or deposit is ready to be executed.
    uint8 internal constant STATUS_READY = 0;

    // Indicates that a settlement or deposit has been executed.
    uint8 internal constant STATUS_DONE = 1;

    // Indicates that a settlement or deposit has failed and can only be retrieved.
    uint8 internal constant STATUS_RETRIEVE = 2;

    /*///////////////////////////////////////////////////////////////
               SETTLEMENT / DEPOSIT REDEEM STATUS CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Indicates that the request for settlement or deposit was successful.
    uint8 internal constant STATUS_SUCCESS = 0;

    // Indicates that the request for settlement or deposit has failed.
    uint8 internal constant STATUS_FAILED = 1;

    /*///////////////////////////////////////////////////////////////
                      DEPOSIT SIGNATURE CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Indicates that the deposit has been signed.
    uint8 internal constant SIGNED_DEPOSIT = 1;

    // Indicates that the deposit has not been signed.
    uint8 internal constant UNSIGNED_DEPOSIT = 0;

    /*///////////////////////////////////////////////////////////////
            PAYLOAD ENCODING / DECODING POSITIONAL CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Defines the position in bytes where the payload starts after the flag byte.
    // Also used to offset number of assets in the payload.
    uint256 internal constant PARAMS_START = 1;

    // Defines the position in bytes where the signed payload starts after the flag byte and user address.
    uint256 internal constant PARAMS_START_SIGNED = 21;

    // Defines the position in bytes where token-related information starts, after flag byte and nonce.
    uint256 internal constant PARAMS_TKN_START = 5;

    // Defines the position in bytes where signed token-related information starts.
    // After flag byte, user and nonce.
    uint256 internal constant PARAMS_TKN_START_SIGNED = 25;

    // Size in bytes for standard Ethereum types / slot size (like uint256).
    uint256 internal constant PARAMS_ENTRY_SIZE = 32;

    // Size in bytes for an Ethereum address.
    uint256 internal constant PARAMS_ADDRESS_SIZE = 20;

    // Size in bytes for a single set of packed token-related parameters (hToken, token, amount, deposit).
    uint256 internal constant PARAMS_TKN_SET_SIZE = 109;

    // Size in bytes for an entry of multiple-token-related parameters, taking padding into account.
    // (hToken, token, amount, deposit)
    uint256 internal constant PARAMS_TKN_SET_SIZE_MULTIPLE = 128;

    // Offset in bytes to mark the end of the standard (deposit related) parameters in the payload.
    uint256 internal constant PARAMS_END_OFFSET = 6;

    // Offset in bytes to mark the end of the standard (deposit related) signed parameters in the payload.
    uint256 internal constant PARAMS_END_SIGNED_OFFSET = 26;

    // Offset in bytes to mark the end of the standard (settlement related) parameters in the payload.
    uint256 internal constant PARAMS_SETTLEMENT_OFFSET = 129;

    /*///////////////////////////////////////////////////////////////
                DEPOSIT / SETTLEMENT LIMITATION CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Maximum length of tokens allowed for deposit or settlement.
    uint256 internal constant MAX_TOKENS_LENGTH = 255;

    /*///////////////////////////////////////////////////////////////
                    MINIMUM EXECUTION GAS CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    uint256 internal constant BASE_FALLBACK_GAS = 50_000;

    // BRANCH: Deposit

    // Minimum gas required for a callOut request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_GAS = 100_000;

    // Minimum gas required for a callOutDepositSingle request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_DEPOSIT_SINGLE_GAS = 150_000;

    // Minimum gas required for a callOutDepositMultiple request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_DEPOSIT_MULTIPLE_GAS = 200_000;

    // Minimum gas required for a callOut request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_SIGNED_GAS = 100_000;

    // Minimum gas required for a callOutDepositSingle request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_SINGLE_GAS = 150_000;

    // Minimum gas required for a callOutDepositMultiple request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_MULTIPLE_GAS = 200_000;

    //ROOT: Settlement

    // Minimum gas required for a callOut request.
    uint256 internal constant ROOT_BASE_CALL_OUT_GAS = 100_000;

    // Minimum gas required for a callOutDepositSingle request.
    uint256 internal constant ROOT_BASE_CALL_OUT_DEPOSIT_SINGLE_GAS = 150_000;

    // Minimum gas required for a callOutDepositMultiple request.
    uint256 internal constant ROOT_BASE_CALL_OUT_DEPOSIT_MULTIPLE_GAS = 200_000;
}
