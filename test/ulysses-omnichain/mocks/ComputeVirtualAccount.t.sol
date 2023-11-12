// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VirtualAccount} from "@omni/VirtualAccount.sol";

library ComputeVirtualAccount {
    /*///////////////////////////////////////////////////////////////
                      COMPUTE VIRTUAL ACCOUNT ADDRESS
    ///////////////////////////////////////////////////////////////*/

    function _getInitCodeHash(address owner) internal pure returns (bytes32 initCodeHash) {
        initCodeHash = keccak256(abi.encodePacked((type(VirtualAccount).creationCode), abi.encode(owner)));
    }

    /// @notice Deterministically computes the virtual account address given the root port and owner
    /// @param rootPort The Root Port contract address
    /// @param owner The owner's address
    /// @return virtualAccount The contract address of the virtual account
    function computeAddress(address rootPort, address owner) internal pure returns (address virtualAccount) {
        virtualAccount = address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", rootPort, bytes32(bytes20(owner)), _getInitCodeHash(owner)))
                )
            )
        );
    }
}
