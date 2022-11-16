// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface ISVC{
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address owner, address buyer, uint256 numTokens) external returns (bool);
    function approve(address delegate, uint256 numTokens) external returns (bool);
}