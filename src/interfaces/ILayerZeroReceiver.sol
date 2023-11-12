// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    /*///////////////////////////////////////////////////////////////
                            LAYER ZERO FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice LayerZero endpoint will invoke this function to deliver the message on the destination
     *  @param _srcChainId the source endpoint identifier
     *  @param _srcAddress the source sending contract address from the source chain
     *  @param _nonce the ordered message nonce
     *  @param _payload the signed payload is the UA bytes has encoded to be sent
     */
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        external
        payable
        returns (bool);

    /**
     * @notice External function to receive cross-chain messages from LayerZero Endpoint Contract without blocking.
     *  @param _endpoint address of the LayerZero Endpoint Contract.
     *  @param _srcAddress address path of the recipient + sender.
     *  @param _payload Calldata for function call.
     */
    function lzReceiveNonBlocking(
        address _endpoint,
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external payable;

    /**
     * @notice Only when the BridgeAgent needs to resume the message flow in blocking mode and clear the stored payload.
     *  @param _srcChainId the chainId of the source chain
     *  @param _srcAddress the contract address of the source contract at the source chain
     */
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}
