// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IMarketplace{
    function checkListed(bytes calldata _signature) external view returns(bool);
    function checkListingAmount(bytes calldata _signature) external view returns (uint256);
}
