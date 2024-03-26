// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IERC20EXP {
    // ERC20-Expirable Specification
    event BlockProducedPerYearUpdated(uint256 oldValue, uint256 newValue);
    event TokenExpiryPeriodUpdated(uint8 oldValue, uint8 newValue);

    function blockPerEra() external returns (uint256);
    function blockPerSlot() external returns (uint256);

    function balanceOf(
        address account,
        fromEra,
        fromSlot,
        toEra,
        toSlot
    ) external returns (uint256); // not implemented yet
    function slotPerEra() external returns (uint8); // not implemented yet
}
