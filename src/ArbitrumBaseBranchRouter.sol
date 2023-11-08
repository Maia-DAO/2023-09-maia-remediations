// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IArbitrumBranchPort} from "./interfaces/IArbitrumBranchPort.sol";

import {BaseBranchRouter} from "./BaseBranchRouter.sol";

/// @title Base Branch Router Contract
/// @author MaiaDAO
contract ArbitrumBaseBranchRouter is BaseBranchRouter {
    using SafeTransferLib for address;

    /// @notice Address for Root Port Address
    address public rootPortAddress;

    /*///////////////////////////////////////////////////////////////
                    INITIALIZATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Arbitrum Base Branch Router.
     * @param _localBridgeAgentAddress The address of the local Bridge Agent.
     */
    function initialize(address _localBridgeAgentAddress) public override onlyOwner {
        super.initialize(_localBridgeAgentAddress);

        rootPortAddress = IArbitrumBranchPort(localPortAddress).rootPortAddress();
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to transfer token into a contract.
     *   @param _hToken The address of the hToken.
     *   @param _token The address of the token.
     *   @param _amount The amount of the hToken.
     *   @param _deposit The amount of the token.
     */
    function _transferAndApproveToken(address _hToken, address _token, uint256 _amount, uint256 _deposit)
        internal
        override
    {
        // Check if the local branch tokens are being spent
        if (_amount - _deposit > 0) {
            unchecked {
                _hToken.safeTransferFrom(msg.sender, address(this), _amount - _deposit);
                _hToken.safeApprove(rootPortAddress, _amount - _deposit);
            }
        }

        // Check if the underlying tokens are being spent
        if (_deposit > 0) {
            _token.safeTransferFrom(msg.sender, address(this), _deposit);
            _token.safeApprove(localPortAddress, _deposit);
        }
    }
}
