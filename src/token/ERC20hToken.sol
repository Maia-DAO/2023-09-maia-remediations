// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20hToken} from "../interfaces/IERC20hToken.sol";

/// @title ERC20 hToken Contract
/// @author MaiaDAO
contract ERC20hToken is ERC20, Ownable, IERC20hToken {
    /**
     * @notice Constructor for the ERC20hToken branch or root Contract.
     *   @param _localPortAddress Address of the local Branch or Root Port Contract.
     *   @param _name Name of the Token.
     *   @param _symbol Symbol of the Token.
     *   @param _decimals Decimals of the Token.
     */
    constructor(address _localPortAddress, string memory _name, string memory _symbol, uint8 _decimals)
        ERC20(_name, _symbol, _decimals)
    {
        if (_localPortAddress == address(0)) revert InvalidPortAddress();
        _initializeOwner(_localPortAddress);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC20 LOGIC
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC20hToken
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /// @inheritdoc IERC20hToken
    function burn(address account, uint256 amount) public override onlyOwner {
        _burn(account, amount);
    }
}
