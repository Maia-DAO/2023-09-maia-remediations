// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {SettlementParams, SettlementMultipleParams} from "./interfaces/IBranchBridgeAgent.sol";
import {IBranchRouter as IRouter} from "./interfaces/IBranchRouter.sol";

import {DecodeBridgeInMultipleParams} from "./lib/DecodeBridgeInMultipleParams.sol";

import {BranchBridgeAgent} from "./BranchBridgeAgent.sol";

/// @title Library for Branch Bridge Agent Executor Deployment
library DeployBranchBridgeAgentExecutor {
    function deploy(address _branchRouter) external returns (address) {
        return address(new BranchBridgeAgentExecutor(_branchRouter));
    }
}

/**
 * @title  Branch Bridge Agent Executor Contract
 * @author MaiaDAO
 * @notice This contract is used for requesting token deposit clearance and
 *         executing transactions in response to requests from the root environment.
 * @dev    Execution is "sandboxed" meaning upon tx failure both token deposits
 *         and interactions with external contracts should be reverted and caught.
 */
contract BranchBridgeAgentExecutor is Ownable, BridgeAgentConstants {
    using SafeTransferLib for address;
    using DecodeBridgeInMultipleParams for bytes;

    /*///////////////////////////////////////////////////////////////
                                IMMUATABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Router that is responsible for executing the cross-chain requests forwarded by this contract.
    IRouter public immutable branchRouter;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Branch Bridge Agent Executor.
     * @param _branchRouter router that will execute the cross-chain requests forwarded by this contract.
     * @dev    Sets the owner of the contract to the Branch Bridge Agent that deploys it.
     */
    constructor(address _branchRouter) {
        branchRouter = IRouter(_branchRouter);
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        EXECUTOR EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to execute a cross-chain request without any settlement.
     * @param _payload Data received from the messaging layer.
     * @dev SETTLEMENT FLAG: 0 (No settlement)
     */
    function executeNoSettlement(bytes calldata _payload) external payable onlyOwner {
        // Execute Calldata if there is code in the destination router
        branchRouter.executeNoSettlement{value: msg.value}(_payload[PARAMS_TKN_START_SIGNED:]);
    }

    /**
     * @notice Function to execute a cross-chain request with a single settlement.
     * @param _recipient Address of the recipient of the settlement.
     * @param _payload Data received from the messaging layer.
     * @dev Router is responsible for managing the msg.value either using it for more remote calls or sending to user.
     * @dev SETTLEMENT FLAG: 1 (Single Settlement)
     */
    function executeWithSettlement(address _recipient, bytes calldata _payload) external payable onlyOwner {
        // Clear Token / Execute Settlement
        SettlementParams memory sParams = SettlementParams({
            settlementNonce: uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED])),
            recipient: _recipient,
            hToken: address(uint160(bytes20(_payload[PARAMS_TKN_START_SIGNED:45]))),
            token: address(uint160(bytes20(_payload[45:65]))),
            amount: uint256(bytes32(_payload[65:97])),
            deposit: uint256(bytes32(_payload[97:PARAMS_SETTLEMENT_OFFSET]))
        });

        // Bridge In Assets
        BranchBridgeAgent(payable(msg.sender)).bridgeIn(
            _recipient, sParams.hToken, sParams.token, sParams.amount, sParams.deposit
        );

        // Execute Calldata if there is any
        if (_payload.length > PARAMS_SETTLEMENT_OFFSET) {
            // Execute remote request
            branchRouter.executeSettlement{value: msg.value}(_payload[PARAMS_SETTLEMENT_OFFSET:], sParams);
        } else if (_recipient == address(branchRouter)) {
            // Execute remote request
            branchRouter.executeSettlement{value: msg.value}("", sParams);
        } else {
            // Send remaininig native / gas token to recipient
            _recipient.safeTransferETH(address(this).balance);
        }
    }

    /**
     * @notice Function to execute a cross-chain request with multiple settlements.
     * @param _recipient Address of the recipient of the settlement.
     * @param _payload Data received from the messaging layer.
     * @dev Router is responsible for managing the msg.value either using it for more remote calls or sending to user.
     * @dev SETTLEMENT FLAG: 2 (Multiple Settlements)
     */
    function executeWithSettlementMultiple(address _recipient, bytes calldata _payload) external payable onlyOwner {
        // Parse Values
        uint256 assetsOffset = uint8(bytes1(_payload[PARAMS_START_SIGNED])) * PARAMS_TKN_SET_SIZE_MULTIPLE;
        uint256 settlementEndOffset = PARAMS_END_SIGNED_OFFSET + assetsOffset;

        // Bridge In Assets and Save Deposit Params
        SettlementMultipleParams memory sParams =
            _bridgeInMultiple(_recipient, _payload[PARAMS_START_SIGNED:settlementEndOffset]);

        // Execute Calldata if there is any
        if (_payload.length > settlementEndOffset) {
            // Execute remote request
            branchRouter.executeSettlementMultiple{value: msg.value}(_payload[settlementEndOffset:], sParams);
        } else if (_recipient == address(branchRouter)) {
            // Execute remote request
            branchRouter.executeSettlementMultiple{value: msg.value}("", sParams);
        } else {
            // Send remaininig native / gas token to recipient
            _recipient.safeTransferETH(address(this).balance);
        }
    }

    /**
     * @notice Internal function to move assets from root omnichain environment to branch chain.
     *   @param _recipient Cross-Chain Settlement of Multiple Tokens Params.
     *   @param _sParams Cross-Chain Settlement of Multiple Tokens Params.
     *   @dev Since the input data payload is encodePacked we need to parse it:
     *     1. First byte is the number of assets to be bridged in. Equals length of all arrays.
     *     2. Next 4 bytes are the nonce of the deposit.
     *     3. Last 32 bytes after the token related information are the chain to bridge to.
     *     4. Token related information starts at index PARAMS_TKN_START is encoded as follows:
     *         1. N * 32 bytes for the hToken address.
     *         2. N * 32 bytes for the underlying token address.
     *         3. N * 32 bytes for the amount of hTokens to be bridged in.
     *         4. N * 32 bytes for the amount of underlying tokens to be bridged in.
     *     5. Each of the 4 token related arrays are of length N and start at the following indexes:
     *         1. PARAMS_TKN_START [hToken address has no offset from token information start].
     *         2. PARAMS_TKN_START + (PARAMS_ADDRESS_SIZE * N)
     *         3. PARAMS_TKN_START + (PARAMS_AMT_OFFSET * N)
     *         4. PARAMS_TKN_START + (PARAMS_DEPOSIT_OFFSET * N)
     */
    function _bridgeInMultiple(address _recipient, bytes calldata _sParams)
        internal
        returns (SettlementMultipleParams memory sParams)
    {
        // Decode Params
        (
            uint8 numOfAssets,
            uint32 nonce,
            address[] memory hTokens,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory deposits
        ) = _sParams.decodeBridgeMultipleInfo();

        // Save Deposit Multiple Params
        sParams = SettlementMultipleParams(numOfAssets, _recipient, nonce, hTokens, tokens, amounts, deposits);

        BranchBridgeAgent(payable(msg.sender)).bridgeInMultiple(_recipient, sParams);
    }
}
