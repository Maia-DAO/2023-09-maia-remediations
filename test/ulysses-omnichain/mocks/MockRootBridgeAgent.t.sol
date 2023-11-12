// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RootBridgeAgent} from "@omni/RootBridgeAgent.sol";

contract MockRootBridgeAgent is RootBridgeAgent {
    constructor(
        uint16 _localChainId,
        address _lzEndpointAddress,
        address _localPortAddress,
        address _localRouterAddress
    ) RootBridgeAgent(_localChainId, _lzEndpointAddress, _localPortAddress, _localRouterAddress) {}

    /*///////////////////////////////////////////////////////////////
                      INTERNAL FUNCTIONS MADE PUBLIC
    ///////////////////////////////////////////////////////////////*/

    function checkSettlementOwner(address caller, address settlementOwner) external view {
        super._checkSettlementOwner(caller, settlementOwner);
    }
}
