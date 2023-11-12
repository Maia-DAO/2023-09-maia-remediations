// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {IRootRouter as IRouter, DepositParams, DepositMultipleParams} from "./interfaces/IRootRouter.sol";

import {DecodeBridgeInMultipleParams} from "./lib/DecodeBridgeInMultipleParams.sol";

import {RootBridgeAgent} from "./RootBridgeAgent.sol";

/// @title Library for Root Bridge Agent Executor Deployment
library DeployRootBridgeAgentExecutor {
    function deploy(address _rootRouter) external returns (address) {
        return address(new RootBridgeAgentExecutor(_rootRouter));
    }
}

/**
 * @title  Root Bridge Agent Executor Contract
 * @author MaiaDAO
 * @notice This contract is used for requesting token settlement clearance and
 *         executing transaction requests from the branch chains.
 * @dev    Execution is "sandboxed" meaning upon tx failure both token settlements
 *         and interactions with external contracts should be reverted and caught.
 */
contract RootBridgeAgentExecutor is Ownable, BridgeAgentConstants {
    using DecodeBridgeInMultipleParams for bytes;

    /*///////////////////////////////////////////////////////////////
                                IMMUATABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Router that is responsible for executing the cross-chain requests forwarded by this contract.
    IRouter public immutable rootRouter;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Root Bridge Agent Executor.
     * @param _rootRouter router that will execute the cross-chain requests forwarded by this contract.
     */
    constructor(address _rootRouter) {
        rootRouter = IRouter(_rootRouter);
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        EXECUTOR EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Execute a remote request from a remote chain
     * @param _payload The encoded request data payload
     * @param _srcChainId The chain id of the chain that sent the request
     * @dev DEPOSIT FLAG: 1 (Call without Deposit)
     */
    function executeNoDeposit(bytes calldata _payload, uint16 _srcChainId) external payable onlyOwner {
        //Execute remote request
        rootRouter.execute{value: msg.value}(_payload[PARAMS_TKN_START:], _srcChainId);
    }

    /**
     * @notice Execute a remote request from a remote chain
     * @param _payload The encoded request data payload
     * @param _srcChainId The chain id of the chain that sent the request
     * @dev DEPOSIT FLAG: 2 (Call with Deposit)
     */
    function executeWithDeposit(bytes calldata _payload, uint16 _srcChainId) external payable onlyOwner {
        // Read Deposit Params
        DepositParams memory dParams = DepositParams({
            depositNonce: uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START])),
            hToken: address(uint160(bytes20(_payload[PARAMS_TKN_START:PARAMS_TKN_START_SIGNED]))),
            token: address(uint160(bytes20(_payload[PARAMS_TKN_START_SIGNED:45]))),
            amount: uint256(bytes32(_payload[45:77])),
            deposit: uint256(bytes32(_payload[77:PARAMS_TKN_SET_SIZE]))
        });

        // Bridge In Assets
        _bridgeIn(address(rootRouter), dParams, _srcChainId);

        // Check if there is additional calldata in the payload
        if (_payload.length > PARAMS_TKN_SET_SIZE) {
            //Execute remote request
            rootRouter.executeDepositSingle{value: msg.value}(_payload[PARAMS_TKN_SET_SIZE:], dParams, _srcChainId);
        } else {
            //Execute remote request
            rootRouter.executeDepositSingle{value: msg.value}("", dParams, _srcChainId);
        }
    }

    /**
     * @notice Execute a remote request from a remote chain
     * @param _payload The encoded request data payload
     * @param _srcChainId The chain id of the chain that sent the request
     * @dev DEPOSIT FLAG: 3 (Call with multiple asset Deposit)
     */
    function executeWithDepositMultiple(bytes calldata _payload, uint16 _srcChainId) external payable onlyOwner {
        //Bridge In Assets and Save Deposit Params
        DepositMultipleParams memory dParams = _bridgeInMultiple(
            address(rootRouter),
            _payload[
                PARAMS_START:
                    PARAMS_END_OFFSET + uint256(uint8(bytes1(_payload[PARAMS_START]))) * PARAMS_TKN_SET_SIZE_MULTIPLE
            ],
            _srcChainId
        );

        uint256 numOfAssets = uint8(bytes1(_payload[PARAMS_START]));
        uint256 length = _payload.length;

        // Check if there is additional calldata in the payload
        if (length > PARAMS_END_OFFSET + (numOfAssets * PARAMS_TKN_SET_SIZE_MULTIPLE)) {
            //Try to execute remote request
            rootRouter.executeDepositMultiple{value: msg.value}(
                _payload[PARAMS_END_OFFSET + uint256(numOfAssets) * PARAMS_TKN_SET_SIZE_MULTIPLE:], dParams, _srcChainId
            );
        } else {
            //Execute remote request
            rootRouter.executeDepositMultiple{value: msg.value}("", dParams, _srcChainId);
        }
    }

    /**
     * @notice Execute a remote request from a remote chain
     * @param _account The account that will execute the request
     * @param _payload The encoded request data payload
     * @param _srcChainId The chain id of the chain that sent the request
     * @dev DEPOSIT FLAG: 4 (Call without Deposit + msg.sender)
     */
    function executeSignedNoDeposit(address _account, bytes calldata _payload, uint16 _srcChainId)
        external
        payable
        onlyOwner
    {
        //Execute remote request
        rootRouter.executeSigned{value: msg.value}(_payload[PARAMS_TKN_START_SIGNED:], _account, _srcChainId);
    }

    /**
     * @notice Execute a remote request from a remote chain with single asset deposit
     * @param _account The account that will execute the request
     * @param _payload The encoded request data payload
     * @param _srcChainId The chain id of the chain that sent the request
     * @dev DEPOSIT FLAG: 5 (Call with Deposit + msg.sender)
     */
    function executeSignedWithDeposit(address _account, bytes calldata _payload, uint16 _srcChainId)
        external
        payable
        onlyOwner
    {
        //Read Deposit Params
        DepositParams memory dParams = DepositParams({
            depositNonce: uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED])),
            hToken: address(uint160(bytes20(_payload[PARAMS_TKN_START_SIGNED:45]))),
            token: address(uint160(bytes20(_payload[45:65]))),
            amount: uint256(bytes32(_payload[65:97])),
            deposit: uint256(bytes32(_payload[97:PARAMS_SETTLEMENT_OFFSET]))
        });

        //Bridge In Asset
        _bridgeIn(_account, dParams, _srcChainId);

        // Check if there is additional calldata in the payload
        if (_payload.length > PARAMS_SETTLEMENT_OFFSET) {
            //Execute remote request
            rootRouter.executeSignedDepositSingle{value: msg.value}(
                _payload[PARAMS_SETTLEMENT_OFFSET:], dParams, _account, _srcChainId
            );
        } else {
            //Execute remote request
            rootRouter.executeSignedDepositSingle{value: msg.value}("", dParams, _account, _srcChainId);
        }
    }

    /**
     * @notice Execute a remote request from a remote chain with multiple asset deposit
     * @param _account The account that will execute the request
     * @param _payload The encoded request data payload
     * @param _srcChainId The chain id of the chain that sent the request
     * @dev DEPOSIT FLAG: 6 (Call with multiple asset Deposit + msg.sender)
     */
    function executeSignedWithDepositMultiple(address _account, bytes calldata _payload, uint16 _srcChainId)
        external
        payable
        onlyOwner
    {
        //Bridge In Assets
        DepositMultipleParams memory dParams = _bridgeInMultiple(
            _account,
            _payload[
                PARAMS_START_SIGNED:
                    PARAMS_END_SIGNED_OFFSET
                        + uint256(uint8(bytes1(_payload[PARAMS_START_SIGNED]))) * PARAMS_TKN_SET_SIZE_MULTIPLE
            ],
            _srcChainId
        );

        // Check if there is additional calldata in the payload
        if (
            _payload.length
                > PARAMS_END_SIGNED_OFFSET
                    + uint256(uint8(bytes1(_payload[PARAMS_START_SIGNED]))) * PARAMS_TKN_SET_SIZE_MULTIPLE
        ) {
            //Execute remote request
            rootRouter.executeSignedDepositMultiple{value: msg.value}(
                _payload[
                    PARAMS_END_SIGNED_OFFSET
                        + uint256(uint8(bytes1(_payload[PARAMS_START_SIGNED]))) * PARAMS_TKN_SET_SIZE_MULTIPLE:
                ],
                dParams,
                _account,
                _srcChainId
            );
        } else {
            //Execute remote request
            rootRouter.executeSignedDepositMultiple{value: msg.value}("", dParams, _account, _srcChainId);
        }
    }

    /**
     * @notice Internal function to move assets from branch chain to root omnichain environment.
     *   @param _dParams Cross-Chain Deposit of Multiple Tokens Params.
     *   @param _srcChainId chain to bridge from.
     */
    function _bridgeIn(address _recipient, DepositParams memory _dParams, uint16 _srcChainId) internal {
        //Request assets for decoded request.
        RootBridgeAgent(payable(msg.sender)).bridgeIn(_recipient, _dParams, _srcChainId);
    }

    /**
     * @notice Internal function to move assets from branch chain to root omnichain environment.
     *   @param _dParams Cross-Chain Deposit of Multiple Tokens Params.
     *   @param _srcChainId chain to bridge from.
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
    function _bridgeInMultiple(address _recipient, bytes calldata _dParams, uint16 _srcChainId)
        internal
        returns (DepositMultipleParams memory dParams)
    {
        // Decode Params
        (
            uint8 numOfAssets,
            uint32 nonce,
            address[] memory hTokens,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory deposits
        ) = _dParams.decodeBridgeMultipleInfo();

        // Save Deposit Multiple Params
        dParams = DepositMultipleParams({
            numberOfAssets: numOfAssets,
            depositNonce: nonce,
            hTokens: hTokens,
            tokens: tokens,
            amounts: amounts,
            deposits: deposits
        });

        RootBridgeAgent(payable(msg.sender)).bridgeInMultiple(_recipient, dParams, _srcChainId);
    }
}
