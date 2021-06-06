// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interface to Compose ERC20 tokens
interface CERC20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}