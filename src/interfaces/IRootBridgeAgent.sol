// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    GasParams,
    DepositParams,
    DepositMultipleParams,
    Settlement,
    SettlementInput,
    SettlementMultipleInput,
    SettlementParams
} from "./BridgeAgentStructs.sol";

import {ILayerZeroReceiver} from "./ILayerZeroReceiver.sol";

/*///////////////////////////////////////////////////////////////
                            ENUMS
//////////////////////////////////////////////////////////////*/

/**
 * @title  Root Bridge Agent Contract
 * @author MaiaDAO
 * @notice Contract responsible for interfacing with Users and Routers acting as a middleman to
 *         access LayerZero cross-chain messaging and Port communication for asset management.
 * @dev    Bridge Agents allow for the encapsulation of business logic as well as the standardized
 *         cross-chain communication, allowing for the creation of custom Routers to perform
 *         actions as a response to remote user requests. This contract is for deployment in the Root
 *         Chain Omnichain Environment based on Arbitrum.
 *         The Root Bridge Agent is responsible for sending/receiving requests to/from the LayerZero Messaging Layer for
 *         execution, as well as requests tokens clearances and tx execution from the `RootBridgeAgentExecutor`.
 *         Remote execution is "sandboxed" within 2 different layers/nestings:
 *         - 1: Upon receiving a request from LayerZero Messaging Layer to avoid blocking future requests due
 *              to execution reversion, ensuring our app is Non-Blocking.
 *              (See https://github.com/LayerZero-Labs/solidity-examples/blob/8e62ebc886407aafc89dbd2a778e61b7c0a25ca0/contracts/lzApp/NonblockingLzApp.sol)
 *         - 2: The call to `RootBridgeAgentExecutor` is in charge of requesting token deposits for each
 *              remote interaction as well as performing the Router calls if any of the calls initiated
 *              by the Router led to an invalid state change in both the token deposit clearances as well as
 *              the external interactions will be reverted and caught by the `RootBridgeAgent`.
 *
 *          Func IDs for calling these  functions through the messaging layer:
 *
 *       ROOT BRIDGE AGENT DEPOSIT FLAGS
 *       ------------------------------
 *       ID   | DESCRIPTION
 *       -----+------------------------
 *       0x01 | Call to Root Router without Deposit.
 *       0x02 | Call to Root Router with Deposit.
 *       0x03 | Call to Root Router with Deposit of Multiple Tokens.
 *       0x04 | Call to Root Router without Deposit + signed message.
 *       0x05 | Call to Root Router with Deposit + signed message.
 *       0x06 | Call to Root Router with Deposit of Multiple Tokens + signed message.
 *       0x07 | Call to `retrySettlement()´. (retries sending a settlement w/ new calldata for execution + new gas)
 *       0x08 | Call to `retrieveDeposit()´. (clears a deposit that has not been executed yet triggering `_fallback`)
 *       0x09 | Call to `_fallback()`. (reopens a settlement for asset redemption)
 *
 *
 *          Encoding Scheme for different Root Bridge Agent Deposit Flags:
 *
 *           - ht = hToken
 *           - t = Token
 *           - A = Amount
 *           - D = Deposit
 *           - b = bytes
 *           - n = number of assets
 *       _____________________________________________________________________________________________________________
 *      |            Flag               |        Deposit Info        |             Token Info             |   DATA   |
 *      |           1 byte              |         4-25 bytes         |       104 or (128 * n) bytes       |   ---	 |
 *      |                               |                            |           hT - t - A - D           |          |
 *      |_______________________________|____________________________|____________________________________|__________|
 *      | callOut = 0x01                |                 4b(nonce)  |            -------------           |   ---	 |
 *      | callOutSingle = 0x02          |                 4b(nonce)  |        20b + 20b + 32b + 32b       |   ---	 |
 *      | callOutMulti = 0x03           |         1b(n) + 4b(nonce)  |   	  32b + 32b + 32b + 32b       |   ---	 |
 *      | callOutSigned = 0x04          |    20b(recip) + 4b(nonce)  |   	      -------------           |   ---    |
 *      | callOutSignedSingle = 0x05    |           20b + 4b(nonce)  |        20b + 20b + 32b + 32b       |   ---	 |
 *      | callOutSignedMultiple = 0x06  |   20b + 1b(n) + 4b(nonce)  |        32b + 32b + 32b + 32b       |   ---	 |
 *      |_______________________________|____________________________|____________________________________|__________|
 *
 *          Generic Contract Interaction Flow:
 *
 *                 BridgeAgent.lzReceive()
 *                           |
 *                           V
 *              BridgeAgentExecutor.execute**()
 *                           |
 *                           V
 *                   Router.execute**()
 *                           |
 *                           V
 *            BridgeAgentExecutor (txExecuted)
 *
 */
interface IRootBridgeAgent is ILayerZeroReceiver {
    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function that returns the current settlement nonce.
     *  @return nonce bridge agent's current settlement nonce
     *
     */
    function settlementNonce() external view returns (uint32 nonce);

    /**
     * @notice External function that returns a given settlement entry.
     *  @param _settlementNonce Identifier for token settlement.
     *
     */
    function getSettlementEntry(uint32 _settlementNonce) external view returns (Settlement memory);

    /**
     * @notice External function to get the Bridge Agent Executor Address.
     * @return address Bridge Agent Executor Address.
     */
    function bridgeAgentExecutorAddress() external view returns (address);

    /**
     * @notice External function to get the Root Bridge Agent's Factory Address.
     *  @return address Root Bridge Agent's Factory Address.
     */
    function factoryAddress() external view returns (address);

    /**
     * @notice External function to get the attached Branch Bridge Agent for a given chain.
     *  @param _chainId Chain ID of the Branch Bridge Agent.
     *  @return address Branch Bridge Agent Address.
     */
    function getBranchBridgeAgent(uint256 _chainId) external view returns (address);

    /**
     * @notice External function to verify a given chain has been allowed by the Root Bridge Agent's Manager
     *         for new Branch Bridge Agent creation.
     *  @param _chainId Chain ID of the Branch Bridge Agent.
     *  @return bool True if the chain has been allowed for new Branch Bridge Agent creation.
     */
    function isBranchBridgeAgentAllowed(uint256 _chainId) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
                        ROOT ROUTER CALL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice External function performs call to LayerZero Endpoint Contract for cross-chain messaging.
     *  @param _gasRefundee Address to return excess gas deposited in `msg.value` to.
     *  @param _recipient address to receive any outstanding gas on the destination chain.
     *  @param _dstChainId Chain to bridge to.
     *  @param _params Calldata for function call.
     *  @param _gParams Gas Parameters for cross-chain message.
     *  @dev Internal function performs call to LayerZero Endpoint Contract for cross-chain messaging.
     */
    function callOut(
        address payable _gasRefundee,
        address _recipient,
        uint16 _dstChainId,
        bytes memory _params,
        GasParams calldata _gParams
    ) external payable;

    /**
     * @notice External function to move assets from root chain to branch omnichain environment.
     *  @param _settlementOwnerAndGasRefundee the effective owner of the settlement this address receives
     *                    excess gas deposited on source chain for a cross-chain call and is allowed to redeeming
     *                    assets after a failed settlement fallback. This address' Virtual Account is also allowed.
     *  @param _recipient recipient of bridged tokens and any outstanding gas on the destination chain.
     *  @param _dstChainId chain to bridge to.
     *  @param _params parameters for function call on branch chain.
     *  @param _sParams settlement parameters for asset bridging to branch chains.
     *  @param _gParams Gas Parameters for cross-chain message.
     *  @param _hasFallbackToggled Flag to toggle fallback function.
     *
     */
    function callOutAndBridge(
        address payable _settlementOwnerAndGasRefundee,
        address _recipient,
        uint16 _dstChainId,
        bytes calldata _params,
        SettlementInput calldata _sParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable;

    /**
     * @notice External function to move assets from branch chain to root omnichain environment.
     *  @param _settlementOwnerAndGasRefundee the effective owner of the settlement this address receives
     *                    excess gas deposited on source chain for a cross-chain call and is allowed to redeeming
     *                    assets after a failed settlement fallback. This address' Virtual Account is also allowed.
     *  @param _recipient recipient of bridged tokens.
     *  @param _dstChainId chain to bridge to.
     *  @param _params parameters for function call on branch chain.
     *  @param _sParams settlement parameters for asset bridging to branch chains.
     *  @param _gParams Gas Parameters for cross-chain message.
     *  @param _hasFallbackToggled Flag to toggle fallback function.
     *
     *
     */
    function callOutAndBridgeMultiple(
        address payable _settlementOwnerAndGasRefundee,
        address _recipient,
        uint16 _dstChainId,
        bytes calldata _params,
        SettlementMultipleInput calldata _sParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                        SETTLEMENT FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to retry a user's Settlement balance.
     *  @param _settlementOwnerAndGasRefundee owner of the settlement and gas refundee.
     *  @param _settlementNonce Identifier for token settlement.
     *  @param _recipient recipient of bridged tokens and any outstanding gas on the destination chain.
     *  @param _params Calldata for function call in branch chain.
     *  @param _gParams Gas Parameters for cross-chain message.
     *  @param _hasFallbackToggled Flag to toggle fallback function.
     */
    function retrySettlement(
        address _settlementOwnerAndGasRefundee,
        uint32 _settlementNonce,
        address _recipient,
        bytes calldata _params,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable;

    /**
     * @notice Function that allows retrieval of failed Settlement's foricng fallback to be triggered.
     *  @param _settlementNonce Identifier for token settlement.
     *  @param _gParams Gas Parameters for cross-chain message.
     *
     */
    function retrieveSettlement(uint32 _settlementNonce, GasParams calldata _gParams) external payable;

    /**
     * @notice Function that allows redemption of failed Settlement's global tokens.
     *  @param _depositNonce Identifier for token deposit.
     *  @param _recipient recipient of redeemed root/global tokens.
     *
     */
    function redeemSettlement(uint32 _depositNonce, address _recipient) external;

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to move assets from branch chain to root omnichain environment.
     * @dev Called in response to Bridge Agent Executor.
     *  @param _recipient recipient of bridged token.
     *  @param _dParams Cross-Chain Deposit of Multiple Tokens Params.
     *  @param _srcChainId chain to bridge from.
     *
     */
    function bridgeIn(address _recipient, DepositParams memory _dParams, uint256 _srcChainId) external;

    /**
     * @notice Function to move assets from branch chain to root omnichain environment.
     * @dev Called in response to Bridge Agent Executor.
     *  @param _recipient recipient of bridged tokens.
     *  @param _dParams Cross-Chain Deposit of Multiple Tokens Params.
     *  @param _srcChainId chain to bridge from.
     *  @dev Since the input data is encodePacked we need to parse it:
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
     *
     */
    function bridgeInMultiple(address _recipient, DepositMultipleParams calldata _dParams, uint256 _srcChainId)
        external;

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new branch bridge agent to a given branch chainId
     *  @param _branchChainId chainId of the branch chain
     */
    function approveBranchBridgeAgent(uint256 _branchChainId) external;

    /**
     * @notice Updates the address of the branch bridge agent
     *  @param _newBranchBridgeAgent address of the new branch bridge agent
     *  @param _branchChainId chainId of the branch chain
     */
    function syncBranchBridgeAgent(address _newBranchBridgeAgent, uint256 _branchChainId) external;

    /**
     * @notice Allows current bridge agent manager to allowlist a successor address.
     *  @param _newManager address of the new bridge agent manager.
     */
    function transferManagementRole(address _newManager) external;

    /**
     * @notice Used by the new bridge agent manager to accept the management role.
     */
    function acceptManagementRole() external;

    /*///////////////////////////////////////////////////////////////
                             EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LogExecute(uint256 indexed depositNonce, uint256 indexed srcChainId);
    event LogFallback(uint256 indexed settlementNonce, uint256 indexed dstChainId);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    ///////////////////////////////////////////////////////////////*/

    error ExecutionFailure();
    error GasErrorOrRepeatedTx();
    error AlreadyExecutedTransaction();
    error UnknownFlag();

    error NotDao();

    error LayerZeroUnauthorizedEndpoint();
    error LayerZeroUnauthorizedCaller();

    error AlreadyAddedBridgeAgent();
    error UnrecognizedExecutor();
    error UnrecognizedPort();
    error UnrecognizedBridgeAgent();
    error UnrecognizedLocalBridgeAgent();
    error UnrecognizedBridgeAgentManager();
    error UnrecognizedRouter();

    error UnrecognizedUnderlyingAddress();
    error UnrecognizedLocalAddress();

    error SettlementRetryUnavailable();
    error SettlementRetryUnavailableUseCallout();
    error SettlementRedeemUnavailable();
    error SettlementRetrieveUnavailable();
    error NotSettlementOwner();
    error ContractsVirtualAccountNotAllowed();

    error InsufficientBalanceForSettlement();
    error InsufficientGasForFees();
    error InvalidInputParams();
    error InvalidInputParamsLength();

    error CallerIsNotPool();
    error AmountsAreZero();
}
