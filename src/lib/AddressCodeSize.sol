// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Address Code Size Library
 * @notice Library for checking the size of a contract's code.
 * @dev    Used for checking if an address is a contract or an EOA.
 */
library AddressCodeSize {
    /*///////////////////////////////////////////////////////////////
                   PAYLOAD DECODING POSITIONAL CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function isEOA(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size == 0;
    }
}
