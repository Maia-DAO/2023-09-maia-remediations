// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IMulticall2 as IMulticall} from "./interfaces/IMulticall2.sol";
import {
    GasParams,
    IRootBridgeAgent as IBridgeAgent,
    SettlementInput,
    SettlementMultipleInput
} from "./interfaces/IRootBridgeAgent.sol";
import {IRootRouter, DepositParams, DepositMultipleParams} from "./interfaces/IRootRouter.sol";
import {IVirtualAccount, Call} from "./interfaces/IVirtualAccount.sol";

struct OutputParams {
    // Address to retry/retrieve/redeem the output assets.
    address settlementOwner;
    // Address to receive the output assets.
    address recipient;
    // Address of the output hToken.
    address outputToken;
    // Amount of output hTokens to send.
    uint256 amountOut;
    // Amount of output underlying token to send.
    uint256 depositOut;
}

struct OutputMultipleParams {
    // Address to retry/retrieve/redeem the output assets.
    address settlementOwner;
    // Address to receive the output assets.
    address recipient;
    // Addresses of the output hTokens.
    address[] outputTokens;
    // Amounts of output hTokens to send.
    uint256[] amountsOut;
    // Amounts of output underlying tokens to send.
    uint256[] depositsOut;
}

/**
 * @title  Multicall Root Router Contract
 * @author MaiaDAO
 * @notice Root Router implementation for interfacing with third-party dApps present in the Root Omnichain Environment.
 * @dev    Func IDs for calling these  functions through the messaging layer:
 *
 *         CROSS-CHAIN MESSAGING FUNCIDs
 *         -----------------------------
 *         FUNC ID      | FUNC NAME
 *         -------------+---------------
 *         0x01         | multicallNoOutput
 *         0x02         | multicallSingleOutput
 *         0x03         | multicallMultipleOutput
 */
contract MulticallRootRouter is IRootRouter, Ownable {
    using SafeTransferLib for address;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Used for identifying cases when this contract's balance of a token is to be used as an input
    /// This value is equivalent to 1<<255, i.e. a singular 1 in the most significant bit.
    uint256 internal constant CONTRACT_BALANCE = 0x8000000000000000000000000000000000000000000000000000000000000000;

    /*///////////////////////////////////////////////////////////////
                    MULTICALL ROOT ROUTER STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Root Chain Layer Zero Identifier.
    uint256 public immutable localChainId;

    /// @notice Address for Local Port Address where assets are stored and managed.
    address public immutable localPortAddress;

    /// @notice Root Chain Multicall Address.
    address public immutable multicallAddress;

    /// @notice Bridge Agent to manage communications and cross-chain assets.
    address payable public bridgeAgentAddress;

    /// @notice Bridge Agent Executor Address.
    address public bridgeAgentExecutorAddress;

    /// @notice Re-entrancy lock modifier state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Multicall Root Router.
     * @param _localChainId local layer zero chain id.
     * @param _localPortAddress address of the root Port.
     * @param _multicallAddress address of the Multicall contract.
     */
    constructor(uint256 _localChainId, address _localPortAddress, address _multicallAddress) {
        require(_localPortAddress != address(0), "Local Port Address cannot be 0");
        require(_multicallAddress != address(0), "Multicall Address cannot be 0");

        localChainId = _localChainId;
        localPortAddress = _localPortAddress;
        multicallAddress = _multicallAddress;
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the Multicall Root Router.
     * @param _bridgeAgentAddress The address of the Bridge Agent.
     */
    function initialize(address _bridgeAgentAddress) external onlyOwner {
        require(_bridgeAgentAddress != address(0), "Bridge Agent Address cannot be 0");
        renounceOwnership();

        bridgeAgentAddress = payable(_bridgeAgentAddress);
        bridgeAgentExecutorAddress = IBridgeAgent(_bridgeAgentAddress).bridgeAgentExecutorAddress();
    }

    /*///////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     *  @notice Function to call 'callOutAndBridge' on RootBridgeAgent.
     *  @param settlementOwner settlement owner and excess gas receiver.
     *  @param recipient Address to receive the output assets.
     *  @param outputToken Address of the output hToken.
     *  @param amountOut Amount of output hTokens to send.
     *  @param depositOut Amount of output hTokens to deposit.
     *  @param dstChainId Chain Id of the destination chain.
     *  @param gasParams Amounts of tokens to withdraw from the destination port.
     */
    function callOutAndBridge(
        address settlementOwner,
        address recipient,
        address outputToken,
        uint256 amountOut,
        uint256 depositOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) external payable virtual {
        outputToken.safeTransferFrom(msg.sender, address(this), amountOut);

        _approveAndCallOut(settlementOwner, recipient, outputToken, amountOut, depositOut, dstChainId, gasParams);
    }

    /**
     *  @notice Function to call 'callOutAndBridgeMultiple' on RootBridgeAgent.
     *  @param settlementOwner settlement owner and excess gas receiver.
     *  @param recipient Address to receive the output assets.
     *  @param outputTokens Addresses of the output hTokens.
     *  @param amountsOut Total amount of tokens to send.
     *  @param depositsOut Amounts of tokens to withdraw from the destination port.
     *  @param gasParams Amounts of tokens to withdraw from the destination port.
     */
    function callOutAndBridgeMultiple(
        address settlementOwner,
        address recipient,
        address[] memory outputTokens,
        uint256[] memory amountsOut,
        uint256[] memory depositsOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) external payable virtual {
        for (uint256 i = 0; i < outputTokens.length;) {
            outputTokens[i].safeTransferFrom(msg.sender, address(this), amountsOut[i]);

            unchecked {
                ++i;
            }
        }

        _approveMultipleAndCallOut(
            settlementOwner, recipient, outputTokens, amountsOut, depositsOut, dstChainId, gasParams
        );
    }

    /// @inheritdoc IRootRouter
    function retrySettlement(
        uint32 _settlementNonce,
        address _recipient,
        bytes calldata _params,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override {
        // Perform call to bridge agent.
        IBridgeAgent(bridgeAgentAddress).retrySettlement{value: msg.value}(
            msg.sender, _settlementNonce, _recipient, _params, _gParams, _hasFallbackToggled
        );
    }

    /*///////////////////////////////////////////////////////////////
                           LAYERZERO FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootRouter
    function executeRetrySettlement(
        address _owner,
        uint32 _settlementNonce,
        address _recipient,
        bytes calldata _params,
        GasParams calldata _gParams,
        bool _hasFallbackToggled,
        uint16
    ) public payable override requiresBridgeAgent {
        // Perform call to bridge agent.
        IBridgeAgent(bridgeAgentAddress).retrySettlement{value: msg.value}(
            _owner, _settlementNonce, _recipient, _params, _gParams, _hasFallbackToggled
        );
    }

    /**
     *  @inheritdoc IRootRouter
     *  @dev FuncIDs
     *
     *  FUNC ID      | FUNC NAME
     *  0x01         |  multicallNoOutput
     *  0x02         |  multicallSingleOutput
     *  0x03         |  multicallMultipleOutput
     *
     */
    function execute(bytes calldata encodedData, uint16) external payable override lock requiresExecutor {
        // Parse funcId
        bytes1 funcId = encodedData[0];

        /// FUNC ID: 1 (multicallNoOutput)
        if (funcId == 0x01) {
            // Decode Params
            (IMulticall.Call[] memory callData) = abi.decode(_decode(encodedData[1:]), (IMulticall.Call[]));

            // Perform Calls
            _multicall(callData);

            /// FUNC ID: 2 (multicallSingleOutput)
        } else if (funcId == 0x02) {
            // Decode Params
            (
                IMulticall.Call[] memory callData,
                OutputParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (IMulticall.Call[], OutputParams, uint16, GasParams));

            // Perform Calls
            _multicall(callData);

            // Bridge Out assets
            _approveAndCallOut(
                outputParams.settlementOwner,
                outputParams.recipient,
                outputParams.outputToken,
                outputParams.amountOut,
                outputParams.depositOut,
                dstChainId,
                gasParams
            );

            /// FUNC ID: 3 (multicallMultipleOutput)
        } else if (funcId == 0x03) {
            // Decode Params
            (
                IMulticall.Call[] memory callData,
                OutputMultipleParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (IMulticall.Call[], OutputMultipleParams, uint16, GasParams));

            // Perform Calls
            _multicall(callData);

            // Bridge Out assets
            _approveMultipleAndCallOut(
                outputParams.settlementOwner,
                outputParams.recipient,
                outputParams.outputTokens,
                outputParams.amountsOut,
                outputParams.depositsOut,
                dstChainId,
                gasParams
            );
            /// UNRECOGNIZED FUNC ID
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    ///@inheritdoc IRootRouter
    function executeDepositSingle(bytes calldata, DepositParams calldata, uint16) external payable override {
        revert();
    }

    ///@inheritdoc IRootRouter
    function executeDepositMultiple(bytes calldata, DepositMultipleParams calldata, uint16) external payable {
        revert();
    }

    ///  @inheritdoc IRootRouter
    function executeSigned(bytes calldata encodedData, address userAccount, uint16)
        external
        payable
        override
        lock
        requiresExecutor
    {
        _executeSigned(encodedData, userAccount);
    }

    ///  @inheritdoc IRootRouter
    function executeSignedDepositSingle(bytes calldata encodedData, DepositParams calldata, address userAccount, uint16)
        external
        payable
        override
        requiresExecutor
        lock
    {
        _executeSigned(encodedData, userAccount);
    }

    ///  @inheritdoc IRootRouter
    function executeSignedDepositMultiple(
        bytes calldata encodedData,
        DepositMultipleParams calldata,
        address userAccount,
        uint16
    ) external payable override requiresExecutor lock {
        _executeSigned(encodedData, userAccount);
    }

    /**
     *  @dev FuncIDs
     *
     *  FUNC ID      | FUNC NAME
     *  0x01         |  multicallNoOutput
     *  0x02         |  multicallSingleOutput
     *  0x03         |  multicallMultipleOutput
     */
    function _executeSigned(bytes calldata encodedData, address userAccount) internal {
        // Parse funcId
        bytes1 funcId = encodedData[0];

        /// FUNC ID: 1 (multicallNoOutput)
        if (funcId == 0x01) {
            // Decode Params
            Call[] memory calls = abi.decode(_decode(encodedData[1:]), (Call[]));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            /// FUNC ID: 2 (multicallSingleOutput)
        } else if (funcId == 0x02) {
            // Decode Params
            (Call[] memory calls, OutputParams memory outputParams, uint16 dstChainId, GasParams memory gasParams) =
                abi.decode(_decode(encodedData[1:]), (Call[], OutputParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // use amountOut == CONTRACT_BALANCE as a flag to swap the entire balance of the contract
            if (outputParams.amountOut == CONTRACT_BALANCE) {
                outputParams.amountOut = outputParams.outputToken.balanceOf(userAccount);
            }

            // Withdraw assets from Virtual Account
            IVirtualAccount(userAccount).withdrawERC20(outputParams.outputToken, outputParams.amountOut);

            // Bridge Out assets
            _approveAndCallOut(
                outputParams.settlementOwner,
                outputParams.recipient,
                outputParams.outputToken,
                outputParams.amountOut,
                outputParams.depositOut,
                dstChainId,
                gasParams
            );

            /// FUNC ID: 3 (multicallMultipleOutput)
        } else if (funcId == 0x03) {
            // Decode Params
            (
                Call[] memory calls,
                OutputMultipleParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (Call[], OutputMultipleParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            for (uint256 i = 0; i < outputParams.outputTokens.length;) {
                // use amountOut == CONTRACT_BALANCE as a flag to swap the entire balance of the contract
                if (outputParams.amountsOut[i] == CONTRACT_BALANCE) {
                    outputParams.amountsOut[i] = outputParams.outputTokens[i].balanceOf(userAccount);
                }

                IVirtualAccount(userAccount).withdrawERC20(outputParams.outputTokens[i], outputParams.amountsOut[i]);

                unchecked {
                    ++i;
                }
            }

            // Bridge Out assets
            _approveMultipleAndCallOut(
                outputParams.settlementOwner,
                outputParams.recipient,
                outputParams.outputTokens,
                outputParams.amountsOut,
                outputParams.depositsOut,
                dstChainId,
                gasParams
            );
            /// UNRECOGNIZED FUNC ID
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /*///////////////////////////////////////////////////////////////
                          MULTICALL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     *  @notice Function to perform a set of actions on the omnichain environment without using the user's Virtual Acccount.
     *  @param calls to be executed.
     */
    function _multicall(IMulticall.Call[] memory calls)
        internal
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        // Make requested calls
        (blockNumber, returnData) = IMulticall(multicallAddress).aggregate(calls);
    }

    /*///////////////////////////////////////////////////////////////
                              INTERNAL HOOKS
    ///////////////////////////////////////////////////////////////*/

    /**
     *  @notice Function to approve token spend before Bridge Agent interaction to Bridge Out of omnichain environment.
     *  @param settlementOwner settlement owner and excess gas receiver.
     *  @param recipient Address to receive the output assets.
     *  @param outputToken Address of the output hToken.
     *  @param amountOut Amount of output hTokens to send.
     *  @param depositOut Amount of output hTokens to deposit.
     *  @param dstChainId Chain Id of the destination chain.
     */
    function _approveAndCallOut(
        address settlementOwner,
        address recipient,
        address outputToken,
        uint256 amountOut,
        uint256 depositOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal virtual {
        // Approve Root Port to spend/send output hTokens.
        outputToken.safeApprove(localPortAddress, amountOut - depositOut);

        //Move output hTokens from Root to Branch and call 'clearToken'.
        IBridgeAgent(bridgeAgentAddress).callOutAndBridge{value: msg.value}(
            payable(settlementOwner),
            recipient,
            dstChainId,
            "",
            SettlementInput(outputToken, amountOut, depositOut),
            gasParams,
            true
        );
    }

    /**
     *  @notice Function to approve multiple token spend before Bridge Agent interaction to Bridge Out of omnichain environment.
     *  @param settlementOwner settlement owner and excess gas receiver.
     *  @param recipient Address to receive the output assets.
     *  @param outputTokens Addresses of the output hTokens.
     *  @param amountsOut Total amount of tokens to send.
     *  @param depositsOut Amounts of tokens to withdraw from the destination port.
     *
     */
    function _approveMultipleAndCallOut(
        address settlementOwner,
        address recipient,
        address[] memory outputTokens,
        uint256[] memory amountsOut,
        uint256[] memory depositsOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal virtual {
        // For each output token
        for (uint256 i = 0; i < outputTokens.length;) {
            // Approve Root Port to spend output hTokens.
            outputTokens[i].safeApprove(localPortAddress, amountsOut[i] - depositsOut[i]);
            unchecked {
                ++i;
            }
        }

        //Move output hTokens from Root to Branch and call 'clearTokens'.
        IBridgeAgent(bridgeAgentAddress).callOutAndBridgeMultiple{value: msg.value}(
            payable(settlementOwner),
            recipient,
            dstChainId,
            "",
            SettlementMultipleInput(outputTokens, amountsOut, depositsOut),
            gasParams,
            true
        );
    }

    /*///////////////////////////////////////////////////////////////
                            DECODING FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _decode(bytes calldata data) internal pure virtual returns (bytes memory) {
        return data;
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Modifier for a simple re-entrancy check.
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /// @notice Verifies the caller is the Bridge Agent Executor.
    modifier requiresExecutor() {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedBridgeAgentExecutor();
        _;
    }

    /// @notice Verifies the caller is the Bridge Agent Executor.
    modifier requiresBridgeAgent() {
        if (msg.sender != bridgeAgentAddress) revert UnrecognizedBridgeAgent();
        _;
    }
}
